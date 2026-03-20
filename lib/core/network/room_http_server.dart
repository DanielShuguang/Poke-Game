import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 房间 HTTP 服务器
///
/// 房主端运行，提供房间信息 API 和 WebSocket 升级
class RoomHttpServer {
  final Logger _logger = Logger();

  /// HTTP 端口
  final int httpPort;

  /// WebSocket 端口
  final int webSocketPort;

  /// 房间信息获取回调
  Future<Map<String, dynamic>> Function()? onGetRoomInfo;

  /// 玩家加入回调
  Future<Map<String, dynamic>> Function(String playerId, String playerName)? onPlayerJoin;

  /// WebSocket 连接回调
  void Function(WebSocketChannel webSocket, String? playerId)? onWebSocketConnect;

  HttpServer? _httpServer;
  HttpServer? _webSocketServer;

  RoomHttpServer({
    this.httpPort = 8080,
    this.webSocketPort = 8082,
  });

  /// 启动服务器
  Future<void> start() async {
    try {
      // 启动 HTTP 服务器
      await _startHttpServer();

      // 启动 WebSocket 服务器
      await _startWebSocketServer();

      _logger.i('房间服务器已启动 - HTTP: $httpPort, WebSocket: $webSocketPort');
    } catch (e) {
      _logger.e('启动房间服务器失败: $e');
      rethrow;
    }
  }

  /// 停止服务器
  Future<void> stop() async {
    await _httpServer?.close(force: true);
    _httpServer = null;

    await _webSocketServer?.close(force: true);
    _webSocketServer = null;

    _logger.i('房间服务器已停止');
  }

  /// 启动 HTTP 服务器
  Future<void> _startHttpServer() async {
    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addMiddleware(_corsMiddleware())
        .addHandler(_handleRequest);

    _httpServer = await io.serve(handler, InternetAddress.anyIPv4, httpPort);
    _logger.i('HTTP 服务器已启动: ${_httpServer!.address.address}:$httpPort');
  }

  /// 启动 WebSocket 服务器
  Future<void> _startWebSocketServer() async {
    final handler = webSocketHandler((WebSocketChannel webSocket, String? protocol) {
      _logger.i('WebSocket 连接建立');

      // 获取 playerId（从查询参数）
      // 注意：这里需要从请求中提取，简化处理
      onWebSocketConnect?.call(webSocket, null);
    });

    final pipeline = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(handler);

    _webSocketServer = await io.serve(pipeline, InternetAddress.anyIPv4, webSocketPort);
    _logger.i('WebSocket 服务器已启动: ${_webSocketServer!.address.address}:$webSocketPort');
  }

  /// CORS 中间件
  shelf.Middleware _corsMiddleware() {
    return (shelf.Handler innerHandler) {
      return (shelf.Request request) async {
        if (request.method == 'OPTIONS') {
          return shelf.Response(200, headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
          });
        }

        final response = await innerHandler(request);
        // shelf.Response 没有 copyWith 方法，需要创建新的 Response
        return shelf.Response(
          response.statusCode,
          body: await response.readAsString(),
          headers: {
            ...response.headers,
            'Access-Control-Allow-Origin': '*',
          },
        );
      };
    };
  }

  /// 处理 HTTP 请求
  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    final path = request.url.path;

    try {
      switch (path) {
        case 'room/info':
          return await _handleGetRoomInfo(request);

        case 'room/join':
          return await _handleJoinRoom(request);

        case 'health':
          return _jsonResponse({'status': 'ok'});

        default:
          return shelf.Response.notFound('Not Found');
      }
    } catch (e) {
      _logger.e('处理请求失败: $e');
      return _jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  }

  /// 处理获取房间信息请求
  Future<shelf.Response> _handleGetRoomInfo(shelf.Request request) async {
    if (onGetRoomInfo == null) {
      return _jsonResponse({'error': 'No room info callback'}, statusCode: 500);
    }

    final roomInfo = await onGetRoomInfo!();
    return _jsonResponse(roomInfo);
  }

  /// 处理加入房间请求
  Future<shelf.Response> _handleJoinRoom(shelf.Request request) async {
    if (request.method != 'POST') {
      return shelf.Response(405, body: 'Method Not Allowed');
    }

    if (onPlayerJoin == null) {
      return _jsonResponse({'error': 'No join callback'}, statusCode: 500);
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final playerId = data['playerId'] as String? ?? '';
      final playerName = data['playerName'] as String? ?? '玩家';

      final result = await onPlayerJoin!(playerId, playerName);
      return _jsonResponse(result);
    } catch (e) {
      _logger.e('处理加入请求失败: $e');
      return _jsonResponse({'error': e.toString()}, statusCode: 400);
    }
  }

  /// 创建 JSON 响应
  shelf.Response _jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
    return shelf.Response(
      statusCode,
      body: jsonEncode(data),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  /// 是否正在运行
  bool get isRunning => _httpServer != null && _webSocketServer != null;

  /// 获取服务器地址
  String? get serverAddress {
    if (_httpServer == null) return null;
    return '${_httpServer!.address.address}:$httpPort';
  }
}
