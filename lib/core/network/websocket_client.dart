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

/// 客户端 WebSocket 连接器
///
/// 用于客户端连接到房主的 WebSocket 服务器
class WebSocketClient {
  final Logger _logger = Logger();

  /// 服务器地址
  final String serverAddress;

  /// WebSocket 端口
  final int port;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  /// 消息流控制器
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// 消息流
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// 连接状态
  WebSocketConnectionStatus _status = WebSocketConnectionStatus.disconnected;
  WebSocketConnectionStatus get status => _status;

  /// 心跳间隔
  final Duration heartbeatInterval;

  /// 重连间隔
  final Duration reconnectInterval;

  /// 最大重连次数
  final int maxReconnectAttempts;

  int _reconnectAttempts = 0;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  WebSocketClient({
    required this.serverAddress,
    this.port = 8082,
    this.heartbeatInterval = const Duration(seconds: 5),
    this.reconnectInterval = const Duration(seconds: 3),
    this.maxReconnectAttempts = 5,
  });

  /// 连接到服务器
  Future<bool> connect() async {
    if (_status == WebSocketConnectionStatus.connected) {
      _logger.w('WebSocket 已连接');
      return true;
    }

    _status = WebSocketConnectionStatus.connecting;

    try {
      final uri = Uri.parse('ws://$serverAddress:$port');
      _channel = WebSocketChannel.connect(uri);

      // 等待连接建立
      await _channel!.ready;

      // 监听消息
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnect,
      );

      _status = WebSocketConnectionStatus.connected;
      _reconnectAttempts = 0;

      // 开始心跳
      _startHeartbeat();

      _logger.i('WebSocket 已连接: $serverAddress:$port');
      return true;
    } catch (e) {
      _logger.e('WebSocket 连接失败: $e');
      _status = WebSocketConnectionStatus.disconnected;
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _stopHeartbeat();
    _stopReconnect();

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _status = WebSocketConnectionStatus.disconnected;
    _logger.i('WebSocket 已断开');
  }

  /// 发送消息
  void send(Map<String, dynamic> message) {
    if (_status != WebSocketConnectionStatus.connected || _channel == null) {
      _logger.w('WebSocket 未连接，无法发送消息');
      return;
    }

    try {
      final json = jsonEncode(message);
      _channel!.sink.add(json);
      _logger.d('发送消息: ${message['type']}');
    } catch (e) {
      _logger.e('发送消息失败: $e');
    }
  }

  /// 收到消息
  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;

      // 处理心跳
      if (json['type'] == 'ping') {
        send({'type': 'pong', 'timestamp': DateTime.now().toIso8601String()});
        return;
      }

      // 发送到消息流
      _messageController.add(json);
    } catch (e) {
      _logger.e('解析消息失败: $e');
    }
  }

  /// 连接错误
  void _onError(dynamic error) {
    _logger.e('WebSocket 错误: $error');
    _handleDisconnect();
  }

  /// 连接断开
  void _onDisconnect() {
    _logger.i('WebSocket 断开');
    _handleDisconnect();
  }

  /// 处理断开连接
  void _handleDisconnect() {
    _stopHeartbeat();
    _status = WebSocketConnectionStatus.disconnected;

    // 尝试重连
    if (_reconnectAttempts < maxReconnectAttempts) {
      _startReconnect();
    }
  }

  /// 开始心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      send({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});
    });
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 开始重连
  void _startReconnect() {
    _status = WebSocketConnectionStatus.reconnecting;
    _reconnectAttempts++;

    _logger.i('开始重连 (第 $_reconnectAttempts 次)...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectInterval, () async {
      final success = await connect();
      if (!success && _reconnectAttempts < maxReconnectAttempts) {
        _startReconnect();
      }
    });
  }

  /// 停止重连
  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
