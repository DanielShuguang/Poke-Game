import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:poke_game/domain/lan/entities/game_event.dart';

/// 重连状态
enum ReconnectStatus {
  /// 未断线
  connected,

  /// 断线中（可重连）
  disconnected,

  /// 重连中
  reconnecting,

  /// 已超时（无法重连）
  timeout,
}

/// 断线重连管理器
///
/// 管理玩家的断线检测和重连逻辑
class ReconnectionManager {
  final Logger _logger = Logger();

  /// 重连超时时间
  final Duration reconnectTimeout;

  /// 最大事件缓存数
  final int maxEventCache;

  /// 玩家断线时间记录
  final Map<String, DateTime> _disconnectTimes = {};

  /// 玩家最后事件ID记录
  final Map<String, String> _lastEventIds = {};

  /// 事件缓存队列（玩家ID -> 事件队列）
  final Map<String, Queue<GameEvent>> _eventCaches = {};

  /// 重连状态流
  final StreamController<Map<String, ReconnectStatus>> _statusController =
      StreamController<Map<String, ReconnectStatus>>.broadcast();

  Stream<Map<String, ReconnectStatus>> get statusStream => _statusController.stream;

  ReconnectionManager({
    this.reconnectTimeout = const Duration(seconds: 60),
    this.maxEventCache = 100,
  });

  /// 记录玩家断线
  void recordDisconnect(String playerId) {
    _disconnectTimes[playerId] = DateTime.now();
    _logger.i('玩家断线: $playerId');

    _notifyStatusChange();
  }

  /// 检查是否可以重连
  bool canReconnect(String playerId) {
    final disconnectTime = _disconnectTimes[playerId];
    if (disconnectTime == null) return false;

    final elapsed = DateTime.now().difference(disconnectTime);
    return elapsed < reconnectTimeout;
  }

  /// 获取重连状态
  ReconnectStatus getStatus(String playerId) {
    final disconnectTime = _disconnectTimes[playerId];
    if (disconnectTime == null) return ReconnectStatus.connected;

    final elapsed = DateTime.now().difference(disconnectTime);
    if (elapsed < reconnectTimeout) {
      return ReconnectStatus.disconnected;
    }
    return ReconnectStatus.timeout;
  }

  /// 清除断线记录（重连成功或超时）
  void clearDisconnect(String playerId) {
    _disconnectTimes.remove(playerId);
    _eventCaches.remove(playerId);
    _logger.i('清除断线记录: $playerId');

    _notifyStatusChange();
  }

  /// 缓存游戏事件
  void cacheEvent(String playerId, GameEvent event) {
    _eventCaches.putIfAbsent(playerId, () => Queue<GameEvent>());

    final cache = _eventCaches[playerId]!;
    cache.add(event);

    // 限制缓存大小
    if (cache.length > maxEventCache) {
      cache.removeFirst();
    }

    _lastEventIds[playerId] = event.eventId;
  }

  /// 获取缓存的后续事件
  List<GameEvent> getEventsAfter(String playerId, String lastEventId) {
    final cache = _eventCaches[playerId];
    if (cache == null) return [];

    // 找到 lastEventId 之后的事件
    final events = <GameEvent>[];
    bool found = false;

    for (final event in cache) {
      if (found) {
        events.add(event);
      } else if (event.eventId == lastEventId) {
        found = true;
      }
    }

    _logger.i('获取缓存事件: $playerId, 从 $lastEventId 之后, 共 ${events.length} 条');
    return events;
  }

  /// 获取最后事件ID
  String? getLastEventId(String playerId) {
    return _lastEventIds[playerId];
  }

  /// 检查并清理超时玩家
  List<String> checkTimeouts() {
    final timeoutPlayers = <String>[];
    final now = DateTime.now();

    _disconnectTimes.forEach((playerId, disconnectTime) {
      final elapsed = now.difference(disconnectTime);
      if (elapsed >= reconnectTimeout) {
        timeoutPlayers.add(playerId);
      }
    });

    for (final playerId in timeoutPlayers) {
      _logger.w('玩家重连超时: $playerId');
      clearDisconnect(playerId);
    }

    return timeoutPlayers;
  }

  /// 获取所有断线玩家
  Map<String, Duration> getDisconnectedPlayers() {
    final result = <String, Duration>{};
    final now = DateTime.now();

    _disconnectTimes.forEach((playerId, disconnectTime) {
      result[playerId] = now.difference(disconnectTime);
    });

    return result;
  }

  /// 通知状态变更
  void _notifyStatusChange() {
    final statuses = <String, ReconnectStatus>{};
    for (final playerId in _disconnectTimes.keys) {
      statuses[playerId] = getStatus(playerId);
    }
    _statusController.add(statuses);
  }

  /// 清空所有数据
  void clearAll() {
    _disconnectTimes.clear();
    _lastEventIds.clear();
    _eventCaches.clear();
    _notifyStatusChange();
  }

  /// 释放资源
  void dispose() {
    _statusController.close();
  }
}

/// 客户端断线重连处理器
class ClientReconnectionHandler {
  final Logger _logger = Logger();

  /// 重连超时时间
  final Duration reconnectTimeout;

  /// 最大重连次数
  final int maxReconnectAttempts;

  /// 重连间隔
  final Duration reconnectInterval;

  DateTime? _disconnectTime;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  /// 重连状态流
  final StreamController<ReconnectStatus> _statusController =
      StreamController<ReconnectStatus>.broadcast();

  Stream<ReconnectStatus> get statusStream => _statusController.stream;

  /// 重连回调
  Future<bool> Function()? onReconnect;

  ClientReconnectionHandler({
    this.reconnectTimeout = const Duration(seconds: 60),
    this.maxReconnectAttempts = 5,
    this.reconnectInterval = const Duration(seconds: 3),
  });

  /// 记录断线
  void recordDisconnect() {
    _disconnectTime = DateTime.now();
    _logger.i('客户端断线');
    _statusController.add(ReconnectStatus.disconnected);
  }

  /// 尝试重连
  Future<bool> tryReconnect() async {
    if (_disconnectTime == null) {
      _logger.w('未断线，无需重连');
      return true;
    }

    final elapsed = DateTime.now().difference(_disconnectTime!);
    if (elapsed >= reconnectTimeout) {
      _logger.e('重连超时');
      _statusController.add(ReconnectStatus.timeout);
      return false;
    }

    _statusController.add(ReconnectStatus.reconnecting);
    _reconnectAttempts++;

    _logger.i('尝试重连 (第 $_reconnectAttempts 次)');

    if (onReconnect != null) {
      final success = await onReconnect!();
      if (success) {
        _disconnectTime = null;
        _reconnectAttempts = 0;
        _statusController.add(ReconnectStatus.connected);
        _logger.i('重连成功');
        return true;
      }
    }

    // 重连失败
    if (_reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      _logger.e('重连失败，已达到最大尝试次数');
      _statusController.add(ReconnectStatus.timeout);
    }

    return false;
  }

  /// 调度重连
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectInterval, () {
      tryReconnect();
    });
  }

  /// 取消重连
  void cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _disconnectTime = null;
    _reconnectAttempts = 0;
    _statusController.add(ReconnectStatus.connected);
  }

  /// 获取状态
  ReconnectStatus get status {
    if (_disconnectTime == null) return ReconnectStatus.connected;

    final elapsed = DateTime.now().difference(_disconnectTime!);
    if (elapsed >= reconnectTimeout) {
      return ReconnectStatus.timeout;
    }

    return ReconnectStatus.disconnected;
  }

  /// 释放资源
  void dispose() {
    _reconnectTimer?.cancel();
    _statusController.close();
  }
}
