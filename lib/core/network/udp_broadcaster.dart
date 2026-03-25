import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

/// UDP 广播服务
///
/// 用于局域网内的房间发现（Android/Windows/Linux）
class UdpBroadcaster {
  final Logger _logger = Logger();

  /// UDP 端口
  final int port;

  /// 广播间隔（秒）
  final Duration broadcastInterval;

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  final bool _isListening = false;

  UdpBroadcaster({
    this.port = 8081,
    this.broadcastInterval = const Duration(seconds: 2),
  });

  /// 开始广播房间信息
  ///
  /// [roomInfo] 房间信息的 JSON 字符串
  Future<void> startBroadcasting(String roomInfo) async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket!.broadcastEnabled = true;
      _socket!.multicastLoopback = false;

      _logger.i('UDP 广播服务已启动，端口: $port');

      // 开始定时广播
      _broadcastTimer = Timer.periodic(broadcastInterval, (timer) {
        _broadcast(roomInfo);
      });
    } catch (e) {
      _logger.e('启动 UDP 广播失败: $e');
      rethrow;
    }
  }

  /// 停止广播
  void stopBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
    _logger.i('UDP 广播服务已停止');
  }

  /// 发送广播消息
  void _broadcast(String message) {
    if (_socket == null) return;

    try {
      final data = utf8.encode(message);
      final address = InternetAddress('255.255.255.255');
      _socket!.send(data, address, port);
      _logger.d('已发送广播消息: ${message.length} 字节');
    } catch (e) {
      _logger.e('发送广播消息失败: $e');
    }
  }
}

/// UDP 监听器
///
/// 用于监听局域网内的房间广播（客户端使用）
class UdpListener {
  final Logger _logger = Logger();

  /// UDP 端口
  final int port;

  RawDatagramSocket? _socket;
  bool _isListening = false;

  UdpListener({this.port = 8081});

  /// 开始监听房间广播
  ///
  /// [onRoomFound] 发现房间时的回调
  Future<void> startListening(Function(String roomInfo) onRoomFound) async {
    if (_isListening) {
      _logger.w('UDP 监听器已在运行');
      return;
    }

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _isListening = true;

      _logger.i('UDP 监听器已启动，端口: $port');

      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            try {
              final message = utf8.decode(datagram.data);
              _logger.d('收到广播消息: $message');
              onRoomFound(message);
            } catch (e) {
              _logger.e('解析广播消息失败: $e');
            }
          }
        }
      });
    } catch (e) {
      _logger.e('启动 UDP 监听失败: $e');
      rethrow;
    }
  }

  /// 停止监听
  void stopListening() {
    _socket?.close();
    _socket = null;
    _isListening = false;
    _logger.i('UDP 监听器已停止');
  }

  /// 是否正在监听
  bool get isListening => _isListening;
}
