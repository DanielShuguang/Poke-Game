import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket 连接状态
enum WebSocketConnectionStatus {
  /// 已断开
  disconnected,

  /// 连接中
  connecting,

  /// 已连接
  connected,

  /// 重连中
  reconnecting,
}

/// WebSocket 连接信息
class WebSocketConnection {
  /// 连接 ID
  final String connectionId;

  /// 玩家 ID
  final String? playerId;

  /// WebSocket 通道
  final WebSocketChannel channel;

  /// 最后活跃时间
  DateTime lastActiveTime;

  /// 是否已认证
  bool isAuthenticated;

  WebSocketConnection({
    required this.connectionId,
    this.playerId,
    required this.channel,
    DateTime? lastActiveTime,
    this.isAuthenticated = false,
  }) : lastActiveTime = lastActiveTime ?? DateTime.now();
}

/// WebSocket 连接管理器
///
/// 用于房主端管理所有客户端的 WebSocket 连接
class WebSocketManager {
  final Logger _logger = Logger();

  /// 所有连接
  final Map<String, WebSocketConnection> _connections = {};

  /// 消息流控制器
  final StreamController<_WebSocketMessage> _messageController =
      StreamController<_WebSocketMessage>.broadcast();

  /// 仅包含消息数据的流（供游戏适配器使用）
  Stream<Map<String, dynamic>> get dataStream =>
      _messageController.stream.map((msg) => msg.data);

  /// 心跳间隔
  final Duration heartbeatInterval;

  /// 心跳超时
  final Duration heartbeatTimeout;

  Timer? _heartbeatTimer;

  WebSocketManager({
    this.heartbeatInterval = const Duration(seconds: 5),
    this.heartbeatTimeout = const Duration(seconds: 15),
  });

  /// 添加连接
  void addConnection(WebSocketChannel channel, {String? connectionId, String? playerId}) {
    final id = connectionId ?? _generateConnectionId();

    final connection = WebSocketConnection(
      connectionId: id,
      playerId: playerId,
      channel: channel,
    );

    _connections[id] = connection;

    // 监听消息
    channel.stream.listen(
      (data) => _onMessage(id, data),
      onError: (error) => _onError(id, error),
      onDone: () => _onDisconnect(id),
    );

    _logger.i('WebSocket 连接已添加: $id, 当前连接数: ${_connections.length}');

    // 开始心跳
    _startHeartbeat();
  }

  /// 移除连接
  void removeConnection(String connectionId) {
    final connection = _connections.remove(connectionId);
    if (connection != null) {
      _logger.i('WebSocket 连接已移除: $connectionId, 剩余连接数: ${_connections.length}');
    }

    // 如果没有连接了，停止心跳
    if (_connections.isEmpty) {
      _stopHeartbeat();
    }
  }

  /// 获取连接
  WebSocketConnection? getConnection(String connectionId) {
    return _connections[connectionId];
  }

  /// 获取所有连接
  List<WebSocketConnection> get allConnections => _connections.values.toList();

  /// 获取连接数量
  int get connectionCount => _connections.length;

  /// 发送消息给指定连接
  void sendTo(String connectionId, Map<String, dynamic> message) {
    final connection = _connections[connectionId];
    if (connection != null) {
      _sendMessage(connection, message);
    }
  }

  /// 发送消息给指定玩家
  void sendToPlayer(String playerId, Map<String, dynamic> message) {
    for (final connection in _connections.values) {
      if (connection.playerId == playerId) {
        _sendMessage(connection, message);
      }
    }
  }

  /// 广播消息给所有连接
  void broadcast(Map<String, dynamic> message) {
    for (final connection in _connections.values) {
      _sendMessage(connection, message);
    }
  }

  /// 广播消息给除指定连接外的所有连接
  void broadcastExcept(String excludeConnectionId, Map<String, dynamic> message) {
    for (final connection in _connections.values) {
      if (connection.connectionId != excludeConnectionId) {
        _sendMessage(connection, message);
      }
    }
  }

  /// 关闭所有连接
  Future<void> closeAll() async {
    _stopHeartbeat();

    for (final connection in _connections.values) {
      try {
        await connection.channel.sink.close();
      } catch (e) {
        _logger.e('关闭连接失败: ${connection.connectionId}, $e');
      }
    }

    _connections.clear();
    _logger.i('所有 WebSocket 连接已关闭');
  }

  /// 释放资源
  void dispose() {
    closeAll();
    _messageController.close();
  }

  /// 发送消息
  void _sendMessage(WebSocketConnection connection, Map<String, dynamic> message) {
    try {
      final json = jsonEncode(message);
      connection.channel.sink.add(json);
      connection.lastActiveTime = DateTime.now();
    } catch (e) {
      _logger.e('发送消息失败: ${connection.connectionId}, $e');
    }
  }

  /// 收到消息
  void _onMessage(String connectionId, dynamic data) {
    final connection = _connections[connectionId];
    if (connection == null) return;

    connection.lastActiveTime = DateTime.now();

    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;

      // 处理心跳响应
      if (json['type'] == 'pong') {
        return;
      }

      // 发送到消息流
      _messageController.add(_WebSocketMessage(
        connectionId: connectionId,
        playerId: connection.playerId,
        data: json,
      ));
    } catch (e) {
      _logger.e('解析消息失败: $connectionId, $e');
    }
  }

  /// 连接错误
  void _onError(String connectionId, dynamic error) {
    _logger.e('WebSocket 错误: $connectionId, $error');
    removeConnection(connectionId);
  }

  /// 连接断开
  void _onDisconnect(String connectionId) {
    _logger.i('WebSocket 断开: $connectionId');
    removeConnection(connectionId);
  }

  /// 开始心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      _sendHeartbeat();
      _checkTimeouts();
    });
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 发送心跳
  void _sendHeartbeat() {
    broadcast({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});
  }

  /// 检查超时
  void _checkTimeouts() {
    final now = DateTime.now();
    final timeoutConnections = <String>[];

    for (final connection in _connections.values) {
      final elapsed = now.difference(connection.lastActiveTime);
      if (elapsed > heartbeatTimeout) {
        timeoutConnections.add(connection.connectionId);
      }
    }

    // 移除超时连接
    for (final connectionId in timeoutConnections) {
      _logger.w('连接超时: $connectionId');
      removeConnection(connectionId);
    }
  }

  /// 生成连接 ID
  String _generateConnectionId() {
    return 'conn_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// WebSocket 消息
class _WebSocketMessage {
  final String connectionId;
  final String? playerId;
  final Map<String, dynamic> data;

  _WebSocketMessage({
    required this.connectionId,
    this.playerId,
    required this.data,
  });
}
