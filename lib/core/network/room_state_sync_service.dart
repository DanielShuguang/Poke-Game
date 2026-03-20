import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:poke_game/core/network/udp_broadcaster.dart';
import 'package:poke_game/core/network/websocket_manager.dart';
import 'package:poke_game/domain/lan/entities/game_event.dart';
import 'package:poke_game/domain/lan/entities/room.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';

/// 房间状态同步服务
///
/// 负责广播房间状态和同步玩家信息
class RoomStateSyncService {
  final Logger _logger = Logger();

  /// UDP 广播器
  final UdpBroadcaster _udpBroadcaster;

  /// WebSocket 管理器
  final WebSocketManager _webSocketManager;

  /// 广播间隔
  final Duration broadcastInterval;

  Timer? _broadcastTimer;

  RoomStateSyncService({
    required UdpBroadcaster udpBroadcaster,
    required WebSocketManager webSocketManager,
    this.broadcastInterval = const Duration(seconds: 2),
  })  : _udpBroadcaster = udpBroadcaster,
        _webSocketManager = webSocketManager;

  /// 开始广播房间状态
  void startBroadcasting(Room room, String networkAddress, String deviceName) {
    _broadcastTimer?.cancel();

    // 构建广播数据
    void broadcastRoom() {
      final roomInfo = room.toRoomInfo(
        hostDeviceName: deviceName,
        networkAddress: networkAddress,
      );

      final json = jsonEncode({
        'type': 'room_announce',
        'roomInfo': roomInfo.toJson(),
      });

      _udpBroadcaster.startBroadcasting(json);
    }

    // 立即广播一次
    broadcastRoom();

    // 定时广播
    _broadcastTimer = Timer.periodic(broadcastInterval, (_) {
      broadcastRoom();
    });

    _logger.i('开始广播房间状态');
  }

  /// 停止广播
  void stopBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _udpBroadcaster.stopBroadcasting();
    _logger.i('停止广播房间状态');
  }

  /// 广播玩家加入事件
  void broadcastPlayerJoined(String playerName, int seatNumber) {
    final event = {
      'type': 'player_joined',
      'playerName': playerName,
      'seatNumber': seatNumber,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _webSocketManager.broadcast(event);
    _logger.i('广播玩家加入: $playerName');
  }

  /// 广播玩家离开事件
  void broadcastPlayerLeft(String playerId, String playerName) {
    final event = {
      'type': 'player_left',
      'playerId': playerId,
      'playerName': playerName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _webSocketManager.broadcast(event);
    _logger.i('广播玩家离开: $playerName');
  }

  /// 广播玩家状态变更
  void broadcastPlayerStatusChanged(String playerId, String status) {
    final event = {
      'type': 'player_status_changed',
      'playerId': playerId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _webSocketManager.broadcast(event);
    _logger.d('广播玩家状态变更: $playerId -> $status');
  }

  /// 广播房间配置变更
  void broadcastRoomConfigChanged(Map<String, dynamic> config) {
    final event = {
      'type': 'room_config_changed',
      'config': config,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _webSocketManager.broadcast(event);
    _logger.i('广播房间配置变更');
  }

  /// 广播游戏开始事件
  void broadcastGameStarted() {
    final event = {
      'type': 'game_started',
      'timestamp': DateTime.now().toIso8601String(),
    };

    _webSocketManager.broadcast(event);
    _logger.i('广播游戏开始');
  }

  /// 广播游戏结束事件
  void broadcastGameEnded(Map<String, dynamic> result) {
    final event = {
      'type': 'game_ended',
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _webSocketManager.broadcast(event);
    _logger.i('广播游戏结束');
  }

  /// 广播聊天消息
  void broadcastChatMessage(String playerId, String playerName, String message) {
    final event = {
      'type': 'chat_message',
      'playerId': playerId,
      'playerName': playerName,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _webSocketManager.broadcast(event);
    _logger.d('广播聊天消息: $playerName');
  }

  /// 发送房间完整状态给指定玩家
  void sendRoomState(String connectionId, Room room) {
    final event = {
      'type': 'room_state_sync',
      'room': room.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _webSocketManager.sendTo(connectionId, event);
    _logger.d('发送房间状态给连接: $connectionId');
  }

  /// 发送游戏事件给指定玩家
  void sendGameEvent(String connectionId, GameEvent gameEvent) {
    _webSocketManager.sendTo(connectionId, gameEvent.toJson());
  }

  /// 发送游戏事件给指定玩家（按 playerId）
  void sendGameEventToPlayer(String playerId, GameEvent gameEvent) {
    _webSocketManager.sendToPlayer(playerId, gameEvent.toJson());
  }

  /// 广播游戏事件给所有玩家
  void broadcastGameEvent(GameEvent gameEvent) {
    _webSocketManager.broadcast(gameEvent.toJson());
  }

  /// 释放资源
  void dispose() {
    stopBroadcasting();
  }
}
