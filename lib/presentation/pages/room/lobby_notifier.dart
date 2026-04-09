import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:poke_game/core/network/network_environment_checker.dart';
import 'package:poke_game/core/network/room_http_server.dart';
import 'package:poke_game/core/network/room_state_sync_service.dart';
import 'package:poke_game/core/network/udp_broadcaster.dart';
import 'package:poke_game/core/network/websocket_client.dart';
import 'package:poke_game/core/network/websocket_manager.dart';
import 'package:poke_game/domain/lan/entities/player_identity.dart';
import 'package:poke_game/domain/lan/entities/room.dart';

/// 等待大厅状态
class LobbyState {
  final Room? room;
  final String? currentPlayerId;
  final bool isStarting;

  const LobbyState({
    this.room,
    this.currentPlayerId,
    this.isStarting = false,
  });

  /// 是否是房主
  bool get isHost => room?.hostPlayerId == currentPlayerId;

  /// 当前玩家
  PlayerIdentity? get currentPlayer {
    if (room == null || currentPlayerId == null) return null;
    try {
      return room!.players.firstWhere((p) => p.playerId == currentPlayerId);
    } catch (_) {
      return null;
    }
  }

  LobbyState copyWith({
    Room? room,
    String? currentPlayerId,
    bool? isStarting,
  }) {
    return LobbyState(
      room: room ?? this.room,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      isStarting: isStarting ?? this.isStarting,
    );
  }
}

/// 等待大厅 Provider
final lobbyProvider = StateNotifierProvider<LobbyNotifier, LobbyState>((ref) {
  return LobbyNotifier();
});

/// 等待大厅 Notifier
class LobbyNotifier extends StateNotifier<LobbyState> {
  final Logger _logger = Logger();

  /// WebSocket 管理器（房主端）
  WebSocketManager? _webSocketManager;

  /// WebSocket 客户端（客户端模式）
  WebSocketClient? _wsClient;

  /// 状态同步服务（房主端）
  RoomStateSyncService? _syncService;

  /// HTTP 服务器（房主端）
  RoomHttpServer? _httpServer;

  /// 是否是房主模式
  bool _isHostMode = false;

  LobbyNotifier() : super(const LobbyState());

  /// 初始化房主模式
  Future<void> initHostMode(Room room, String currentPlayerId) async {
    _isHostMode = true;

    // 初始化 WebSocket 管理器
    _webSocketManager = WebSocketManager();

    // 初始化 UDP 广播器
    final udpBroadcaster = UdpBroadcaster();

    // 初始化状态同步服务
    _syncService = RoomStateSyncService(
      udpBroadcaster: udpBroadcaster,
      webSocketManager: _webSocketManager!,
    );

    // 初始化 HTTP 服务器
    _httpServer = RoomHttpServer(
      httpPort: 8080,
      webSocketPort: 8082,
    );

    // 设置回调
    _httpServer!.onGetRoomInfo = () async {
      return room.toJson();
    };

    _httpServer!.onPlayerJoin = (playerId, playerName) async {
      // 添加玩家到房间
      final newPlayer = PlayerIdentity(
        playerId: playerId,
        playerName: playerName,
        seatNumber: room.players.length + 1,
        status: PlayerStatus.online,
        joinedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      final updatedRoom = room.copyWith(
        players: [...room.players, newPlayer],
      );

      state = state.copyWith(room: updatedRoom);

      // 广播玩家加入
      _syncService?.broadcastPlayerJoined(playerName, newPlayer.seatNumber);

      return {'success': true, 'playerId': playerId};
    };

    _httpServer!.onWebSocketConnect = (webSocket, playerId) {
      _webSocketManager!.addConnection(webSocket, playerId: playerId);
    };

    // 启动服务器
    await _httpServer!.start();

    // 获取网络地址
    final networkChecker = NetworkEnvironmentChecker();
    final result = await networkChecker.checkEnvironment();

    // 开始广播房间
    _syncService!.startBroadcasting(
      room,
      result.localIp ?? 'unknown',
      'Host Device',
    );

    _logger.i('房主模式已初始化');
  }

  /// 初始化客户端模式
  Future<void> initClientMode(Room room, String currentPlayerId) async {
    _isHostMode = false;
    state = state.copyWith(room: room, currentPlayerId: currentPlayerId);

    // 如果房间有网络地址，初始化 WebSocket 客户端
    // 注意：这里需要从 RoomInfo 获取网络地址
    // 暂时跳过 WebSocket 连接
    _logger.i('客户端模式已初始化');
  }

  /// 初始化客户端模式（带 WebSocket 连接）
  Future<void> initClientModeWithWebSocket(
    Room room,
    String currentPlayerId,
    String serverAddress,
  ) async {
    _isHostMode = false;
    state = state.copyWith(room: room, currentPlayerId: currentPlayerId);

    // 初始化 WebSocket 客户端
    _wsClient = WebSocketClient(
      serverAddress: serverAddress,
      port: 8082,
    );

    // 连接到房主的 WebSocket 服务器
    final connected = await _wsClient!.connect();
    if (connected) {
      _logger.i('客户端 WebSocket 已连接: $serverAddress:8082');
    } else {
      _logger.w('客户端 WebSocket 连接失败');
    }
  }

  void setRoom(Room room, String currentPlayerId) {
    state = state.copyWith(room: room, currentPlayerId: currentPlayerId);
  }

  void toggleReady() {
    if (state.currentPlayerId == null || state.room == null) return;

    final currentPlayer = state.currentPlayer;
    if (currentPlayer == null) return;

    final newStatus = currentPlayer.status == PlayerStatus.ready
        ? PlayerStatus.online
        : PlayerStatus.ready;

    // 更新本地状态
    final players = state.room!.players.map((p) {
      if (p.playerId == state.currentPlayerId) {
        return p.copyWith(status: newStatus);
      }
      return p;
    }).toList();

    state = state.copyWith(
      room: state.room!.copyWith(players: players),
    );

    // 发送状态变更到服务器/广播
    if (_isHostMode && _syncService != null) {
      _syncService!.broadcastPlayerStatusChanged(
        state.currentPlayerId!,
        newStatus.name,
      );
    }

    _logger.i('玩家状态变更: ${state.currentPlayerId} -> $newStatus');
  }

  void startGame() {
    if (!state.isHost) return;
    state = state.copyWith(isStarting: true);

    // 发送开始游戏消息
    if (_syncService != null) {
      _syncService!.broadcastGameStarted();
    }

    _logger.i('游戏开始');
  }

  /// Host 广播游戏状态（供 NetworkAdapter 调用）
  void broadcastGameMessage(Map<String, dynamic> msg) {
    _webSocketManager?.broadcast(msg);
  }

  /// Host 游戏消息流（来自客户端）
  Stream<Map<String, dynamic>> get hostGameStream {
    if (_webSocketManager == null) return const Stream.empty();
    return _webSocketManager!.dataStream;
  }

  /// Client 游戏消息流（来自 Host）
  Stream<Map<String, dynamic>> get clientGameStream {
    return _wsClient?.messageStream ?? const Stream.empty();
  }

  /// Client 发送消息给 Host
  void sendGameMessage(Map<String, dynamic> msg) {
    _wsClient?.send(msg);
  }

  void leaveRoom() {
    // 发送离开房间消息
    if (!_isHostMode) {
      // 通过 WebSocket 发送离开消息给房主
      if (_wsClient != null && state.currentPlayerId != null) {
        _wsClient!.send({
          'type': 'player_leave',
          'playerId': state.currentPlayerId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _logger.i('发送离开房间消息给房主');
      }
      // 断开 WebSocket 连接
      _wsClient?.disconnect();
      _wsClient = null;
    } else {
      // 房主离开，销毁房间
      _syncService?.stopBroadcasting();
      _httpServer?.stop();
      _webSocketManager?.closeAll();
      _logger.i('房主离开，房间已销毁');
    }

    state = const LobbyState();
  }

  /// 踢出玩家
  void kickPlayer(String playerId) {
    if (!state.isHost || state.room == null) return;

    final player = state.room!.players.firstWhere(
      (p) => p.playerId == playerId,
      orElse: () => throw Exception('Player not found'),
    );

    // 从房间移除玩家
    final updatedPlayers = state.room!.players
        .where((p) => p.playerId != playerId)
        .toList();

    state = state.copyWith(
      room: state.room!.copyWith(players: updatedPlayers),
    );

    // 广播踢出消息
    if (_syncService != null) {
      _syncService!.broadcastPlayerLeft(playerId, player.playerName);
    }

    _logger.i('踢出玩家: $playerId');
  }

  /// 释放资源
  @override
  void dispose() {
    _syncService?.dispose();
    _httpServer?.stop();
    _webSocketManager?.dispose();
    super.dispose();
  }
}
