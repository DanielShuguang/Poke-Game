import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:poke_game/core/network/blackjack_network_adapter.dart';
import 'package:poke_game/core/network/holdem_network_adapter.dart';
import 'package:poke_game/core/network/network_environment_checker.dart';
import 'package:poke_game/core/network/room_http_server.dart';
import 'package:poke_game/core/network/room_state_sync_service.dart';
import 'package:poke_game/core/network/udp_broadcaster.dart';
import 'package:poke_game/core/network/websocket_client.dart';
import 'package:poke_game/core/network/websocket_manager.dart';
import 'package:poke_game/core/network/zhj_network_adapter.dart';
import 'package:poke_game/core/network/shengji_network_adapter.dart';
import 'package:poke_game/domain/lan/entities/player_identity.dart';
import 'package:poke_game/domain/lan/entities/room.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';
import 'package:poke_game/presentation/pages/texas_holdem/holdem_game_page.dart';
import 'package:poke_game/presentation/pages/texas_holdem/holdem_provider.dart';
import 'package:poke_game/presentation/pages/zhajinhua/providers/zhj_game_provider.dart';
import 'package:poke_game/presentation/pages/zhajinhua/zhajinhua_page.dart';
import 'package:poke_game/presentation/pages/blackjack/blackjack_page.dart';
import 'package:poke_game/presentation/pages/blackjack/providers/blackjack_game_notifier.dart';
import 'package:poke_game/core/network/niuniu_network_adapter.dart';
import 'package:poke_game/presentation/pages/niuniu/niuniu_page.dart';
import 'package:poke_game/presentation/pages/niuniu/providers/niuniu_game_notifier.dart';
import 'package:poke_game/presentation/pages/shengji/shengji_page.dart';
import 'package:poke_game/domain/shengji/notifiers/shengji_notifier.dart';

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

/// 等待大厅页面
class RoomLobbyPage extends ConsumerStatefulWidget {
  const RoomLobbyPage({super.key});

  @override
  ConsumerState<RoomLobbyPage> createState() => _RoomLobbyPageState();
}

class _RoomLobbyPageState extends ConsumerState<RoomLobbyPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lobbyProvider);

    // 任务 6.1：当 isStarting 变为 true 时根据游戏类型导航
    ref.listen<LobbyState>(lobbyProvider, (prev, next) {
      if (prev?.isStarting == false && next.isStarting == true) {
        _navigateToGame(context, ref, next);
      }
    });

    final room = state.room;

    // 仅在没有真实房间数据时使用模拟数据展示
    final Room effectiveRoom;
    final LobbyState effectiveState;
    if (room != null) {
      effectiveRoom = room;
      effectiveState = state;
    } else {
      effectiveRoom = Room(
        roomId: 'mock-room',
        roomName: '欢乐对战',
        gameType: GameType.doudizhu,
        hostPlayerId: 'player1',
        players: [
          PlayerIdentity(
            playerId: 'player1',
            playerName: '玩家1（房主）',
            seatNumber: 1,
            status: PlayerStatus.ready,
            isHost: true,
          ),
          PlayerIdentity(
            playerId: 'player2',
            playerName: '玩家2',
            seatNumber: 2,
            status: PlayerStatus.ready,
          ),
          PlayerIdentity(
            playerId: 'player3',
            playerName: '玩家3',
            seatNumber: 3,
            status: PlayerStatus.online,
          ),
        ],
        status: RoomStatus.waiting,
        maxPlayerCount: 3,
        gameConfig: {},
        createdAt: DateTime.now(),
      );
      effectiveState = state.copyWith(room: effectiveRoom, currentPlayerId: 'player1');
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showLeaveDialog(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(effectiveRoom.roomName),
          actions: [
            if (effectiveState.isHost)
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showRoomSettings(context, ref),
              ),
          ],
        ),
        body: Column(
          children: [
            _buildRoomInfo(context, effectiveRoom),
            const Divider(),
            Expanded(
              child: _buildPlayerList(context, ref, effectiveState),
            ),
            _buildBottomActions(context, ref, effectiveState),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfo(BuildContext context, Room room) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              room.gameType.displayName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${room.currentPlayerCount}/${room.maxPlayerCount} 人',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          if (room.status == RoomStatus.waiting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '等待中',
                style: TextStyle(color: Colors.green.shade700, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(
    BuildContext context,
    WidgetRef ref,
    LobbyState state,
  ) {
    final room = state.room!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: room.maxPlayerCount,
      itemBuilder: (context, index) {
        final seatNumber = index + 1;
        final player = room.getPlayerBySeat(seatNumber);

        return _PlayerSeatCard(
          seatNumber: seatNumber,
          player: player,
          isCurrentPlayer: player?.playerId == state.currentPlayerId,
          isHost: state.isHost,
          onKick: player != null && state.isHost && !player.isHost
              ? () => _kickPlayer(context, ref, player.playerId)
              : null,
        );
      },
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    WidgetRef ref,
    LobbyState state,
  ) {
    final currentPlayer = state.currentPlayer;
    final isReady = currentPlayer?.status == PlayerStatus.ready;
    final allReady = state.room?.allPlayersReady ?? false;
    final hasMinPlayers = state.room?.hasMinimumPlayers ?? false;
    final canStart = state.isHost && allReady && hasMinPlayers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!state.isHost)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(lobbyProvider.notifier).toggleReady(),
                  icon: Icon(isReady ? Icons.check_circle : Icons.circle_outlined),
                  label: Text(isReady ? '取消准备' : '准备'),
                ),
              ),
            if (state.isHost) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: hasMinPlayers && !allReady
                      ? () => _forceStart(context, ref)
                      : null,
                  child: const Text('强制开始'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: canStart && !state.isStarting
                      ? () => ref.read(lobbyProvider.notifier).startGame()
                      : null,
                  child: state.isStarting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('开始游戏'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('离开房间'),
        content: const Text('确定要离开房间吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(lobbyProvider.notifier).leaveRoom();
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('离开'),
          ),
        ],
      ),
    );
  }

  void _showRoomSettings(BuildContext context, WidgetRef ref) {
    final room = ref.read(lobbyProvider).room;
    if (room == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '房间设置',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('房间名称'),
              subtitle: Text(room.roomName),
            ),
            ListTile(
              leading: const Icon(Icons.games),
              title: const Text('游戏类型'),
              subtitle: Text(room.gameType.displayName),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('人数'),
              subtitle: Text('${room.currentPlayerCount}/${room.maxPlayerCount}'),
            ),
            if (room.password != null && room.password!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('房间密码'),
                subtitle: Text(room.password!),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }

  void _kickPlayer(BuildContext context, WidgetRef ref, String playerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('踢出玩家'),
        content: const Text('确定要踢出该玩家吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(lobbyProvider.notifier).kickPlayer(playerId);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _forceStart(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('强制开始'),
        content: const Text('未准备的玩家将被踢出，确定要强制开始吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(lobbyProvider.notifier).startGame();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 任务 6.1-6.3：根据游戏类型路由至对应游戏页面并初始化 NetworkAdapter
  void _navigateToGame(BuildContext context, WidgetRef ref, LobbyState lobbyState) {
    final room = lobbyState.room;
    if (room == null) return;
    final lobbyNotifier = ref.read(lobbyProvider.notifier);
    final isHost = lobbyState.isHost;
    // 任务 6.2：使用房间分配的玩家 ID 作为本地玩家 ID
    final localPlayerId = lobbyState.currentPlayerId ?? 'player1';

    final incomingStream = isHost
        ? lobbyNotifier.hostGameStream
        : lobbyNotifier.clientGameStream;

    void broadcastFn(Map<String, dynamic> msg) {
      if (isHost) {
        lobbyNotifier.broadcastGameMessage(msg);
      } else {
        lobbyNotifier.sendGameMessage(msg);
      }
    }

    switch (room.gameType) {
      case GameType.texasHoldem:
        // 任务 6.3：Host 初始化并启动 HoldemNetworkAdapter
        final holdemNotifier = ref.read(holdemGameProvider.notifier);
        final adapter = HoldemNetworkAdapter(
          incomingStream: incomingStream,
          broadcastFn: broadcastFn,
          notifier: holdemNotifier,
          isHost: isHost,
          localPlayerId: localPlayerId,
        );
        adapter.start();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => HoldemGamePage(isOnline: true, networkAdapter: adapter),
        ));
      case GameType.zhajinhua:
        final zhjNotifier = ref.read(zhjGameProvider.notifier);
        final adapter = ZhjNetworkAdapter(
          incomingStream: incomingStream,
          broadcastFn: broadcastFn,
          notifier: zhjNotifier,
          isHost: isHost,
          localPlayerId: localPlayerId,
        );
        adapter.start();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ZhajinhuaPage(isOnline: true, networkAdapter: adapter),
        ));
      case GameType.blackjack:
        final bjNotifier = ref.read(blackjackGameProvider.notifier);
        final adapter = BlackjackNetworkAdapter(
          incomingStream: incomingStream,
          broadcastFn: broadcastFn,
          notifier: bjNotifier,
          isHost: isHost,
          localPlayerId: localPlayerId,
        );
        adapter.start();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BlackjackPage(isOnline: true, networkAdapter: adapter),
        ));
      case GameType.niuniu:
        final nnNotifier = ref.read(niuniuGameProvider.notifier);
        final adapter = NiuniuNetworkAdapter(
          incomingStream: incomingStream,
          broadcastFn: broadcastFn,
          notifier: nnNotifier,
          isHost: isHost,
          localPlayerId: localPlayerId,
        );
        adapter.start();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NiuniuPage(isOnline: true, networkAdapter: adapter),
        ));
      case GameType.doudizhu:
        context.push('/doudizhu');
      case GameType.shengji:
        final shengjiNotifier = ref.read(shengjiNotifierProvider.notifier);
        final adapter = ShengjiNetworkAdapter(
          incomingStream: incomingStream,
          broadcastFn: broadcastFn,
          notifier: shengjiNotifier,
          isHost: isHost,
          localPlayerId: localPlayerId,
        );
        adapter.start();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ShengjiPage(isOnline: true, networkAdapter: adapter),
        ));
    }
  }
}

/// 玩家座位卡片
class _PlayerSeatCard extends StatelessWidget {
  final int seatNumber;
  final PlayerIdentity? player;
  final bool isCurrentPlayer;
  final bool isHost;
  final VoidCallback? onKick;

  const _PlayerSeatCard({
    required this.seatNumber,
    this.player,
    this.isCurrentPlayer = false,
    this.isHost = false,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Text('$seatNumber'),
          ),
          title: Text(
            '等待加入...',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Card(
      color: isCurrentPlayer ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: player!.isHost
              ? Colors.amber
              : Theme.of(context).colorScheme.primary,
          child: player!.isHost
              ? const Icon(Icons.star, color: Colors.white)
              : Text('$seatNumber'),
        ),
        title: Row(
          children: [
            Text(player!.playerName),
            if (player!.isHost) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '房主',
                  style: TextStyle(fontSize: 10, color: Colors.amber.shade900),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(player!.statusText),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player!.status == PlayerStatus.ready)
              Icon(Icons.check_circle, color: Colors.green.shade600),
            if (isHost && onKick != null && !isCurrentPlayer)
              IconButton(
                icon: const Icon(Icons.person_remove_outlined),
                onPressed: onKick,
                tooltip: '踢出',
              ),
          ],
        ),
      ),
    );
  }
}
