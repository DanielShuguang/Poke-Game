import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';

/// 消息优先级
enum MessagePriority {
  /// 高优先级（游戏操作）
  high,

  /// 普通优先级（状态同步）
  normal,

  /// 低优先级（聊天消息）
  low,
}

/// 待发送消息
class _PendingMessage {
  final Map<String, dynamic> message;
  final MessagePriority priority;
  final DateTime createdAt;

  _PendingMessage(this.message, this.priority) : createdAt = DateTime.now();
}

/// 网络延迟优化器
///
/// 实现消息队列、批量发送、心跳超时检测
class NetworkOptimizer {
  final Logger _logger = Logger();

  /// 消息队列
  final Queue<_PendingMessage> _messageQueue = Queue<_PendingMessage>();

  /// 批量发送间隔
  final Duration batchInterval;

  /// 最大批量大小
  final int maxBatchSize;

  /// 心跳超时时间
  final Duration heartbeatTimeout;

  /// 发送回调
  void Function(List<Map<String, dynamic>> messages)? onSend;

  Timer? _batchTimer;
  DateTime? _lastHeartbeatTime;

  NetworkOptimizer({
    this.batchInterval = const Duration(milliseconds: 50),
    this.maxBatchSize = 10,
    this.heartbeatTimeout = const Duration(seconds: 15),
  });

  /// 添加消息到队列
  void enqueue(Map<String, dynamic> message, {MessagePriority priority = MessagePriority.normal}) {
    _messageQueue.add(_PendingMessage(message, priority));

    // 如果是高优先级消息，立即发送
    if (priority == MessagePriority.high) {
      _flushQueue();
      return;
    }

    // 启动批量发送定时器
    _startBatchTimer();
  }

  /// 启动批量发送定时器
  void _startBatchTimer() {
    _batchTimer ??= Timer(batchInterval, () {
      _flushQueue();
    });
  }

  /// 刷新队列
  void _flushQueue() {
    _batchTimer?.cancel();
    _batchTimer = null;

    if (_messageQueue.isEmpty) return;

    // 按优先级排序
    final messages = <Map<String, dynamic>>[];
    final highPriority = <_PendingMessage>[];
    final normalPriority = <_PendingMessage>[];
    final lowPriority = <_PendingMessage>[];

    while (_messageQueue.isNotEmpty && messages.length < maxBatchSize) {
      final pending = _messageQueue.removeFirst();
      if (pending.priority == MessagePriority.high) {
        highPriority.add(pending);
      } else if (pending.priority == MessagePriority.normal) {
        normalPriority.add(pending);
      } else {
        lowPriority.add(pending);
      }
    }

    // 按优先级添加
    messages.addAll(highPriority.map((p) => p.message));
    messages.addAll(normalPriority.map((p) => p.message));
    messages.addAll(lowPriority.map((p) => p.message));

    if (messages.isNotEmpty) {
      // 如果只有一条消息，直接发送
      if (messages.length == 1) {
        onSend?.call(messages);
      } else {
        // 多条消息合并为批量消息
        onSend?.call([
          {'type': 'batch', 'messages': messages}
        ]);
      }

      _logger.d('发送批量消息: ${messages.length} 条');
    }
  }

  /// 更新心跳时间
  void updateHeartbeatTime() {
    _lastHeartbeatTime = DateTime.now();
  }

  /// 检查心跳超时
  bool isHeartbeatTimeout() {
    if (_lastHeartbeatTime == null) return false;
    return DateTime.now().difference(_lastHeartbeatTime!) > heartbeatTimeout;
  }

  /// 获取自上次心跳以来的时间
  Duration? getTimeSinceLastHeartbeat() {
    if (_lastHeartbeatTime == null) return null;
    return DateTime.now().difference(_lastHeartbeatTime!);
  }

  /// 清空队列
  void clearQueue() {
    _messageQueue.clear();
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  /// 获取队列大小
  int get queueSize => _messageQueue.length;

  /// 释放资源
  void dispose() {
    clearQueue();
  }
}

/// 延迟统计器
class LatencyTracker {
  /// 最大样本数
  final int maxSamples;

  /// 延迟样本（毫秒）
  final List<int> _samples = [];

  LatencyTracker({this.maxSamples = 100});

  /// 记录延迟
  void record(int latencyMs) {
    _samples.add(latencyMs);
    if (_samples.length > maxSamples) {
      _samples.removeAt(0);
    }
  }

  /// 获取平均延迟
  double get averageLatency {
    if (_samples.isEmpty) return 0;
    return _samples.reduce((a, b) => a + b) / _samples.length;
  }

  /// 获取最大延迟
  int get maxLatency {
    if (_samples.isEmpty) return 0;
    return _samples.reduce((a, b) => a > b ? a : b);
  }

  /// 获取最小延迟
  int get minLatency {
    if (_samples.isEmpty) return 0;
    return _samples.reduce((a, b) => a < b ? a : b);
  }

  /// 获取最新延迟
  int? get lastLatency => _samples.isNotEmpty ? _samples.last : null;

  /// 获取样本数
  int get sampleCount => _samples.length;

  /// 清空样本
  void clear() {
    _samples.clear();
  }

  /// 获取统计报告
  Map<String, dynamic> getStatistics() {
    return {
      'average': averageLatency,
      'max': maxLatency,
      'min': minLatency,
      'last': lastLatency,
      'sampleCount': sampleCount,
    };
  }
}

/// 心跳管理器
class HeartbeatManager {
  final Logger _logger = Logger();

  /// 心跳间隔
  final Duration interval;

  /// 心跳超时
  final Duration timeout;

  /// 心跳发送回调
  void Function()? onSendHeartbeat;

  /// 心跳超时回调
  void Function()? onTimeout;

  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  DateTime? _lastPongTime;

  HeartbeatManager({
    this.interval = const Duration(seconds: 5),
    this.timeout = const Duration(seconds: 15),
  });

  /// 开始心跳
  void start() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(interval, (_) {
      _sendHeartbeat();
    });

    _lastPongTime = DateTime.now();
    _logger.i('心跳管理器已启动');
  }

  /// 停止心跳
  void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _logger.i('心跳管理器已停止');
  }

  /// 发送心跳
  void _sendHeartbeat() {
    onSendHeartbeat?.call();

    // 启动超时检测
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(timeout, () {
      _logger.w('心跳超时');
      onTimeout?.call();
    });
  }

  /// 收到心跳响应
  void onPongReceived() {
    _lastPongTime = DateTime.now();
    _timeoutTimer?.cancel();
  }

  /// 检查是否超时
  bool get isTimeout {
    if (_lastPongTime == null) return false;
    return DateTime.now().difference(_lastPongTime!) > timeout;
  }

  /// 获取上次响应时间
  DateTime? get lastPongTime => _lastPongTime;
}
