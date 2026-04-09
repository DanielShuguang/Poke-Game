import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poke_game/domain/lan/entities/player_identity.dart';
import 'package:poke_game/domain/lan/entities/room.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

import 'game_navigation_helper.dart';
import 'lobby_notifier.dart';

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

    // 当 isStarting 变为 true 时根据游戏类型导航
    ref.listen<LobbyState>(lobbyProvider, (prev, next) {
      if (prev?.isStarting == false && next.isStarting == true) {
        navigateToGame(context, ref, next);
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
      effectiveState =
          state.copyWith(room: effectiveRoom, currentPlayerId: 'player1');
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.gameColors.statusSuccessBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '等待中',
                style: TextStyle(
                    color: context.gameColors.primaryGreen, fontSize: 12),
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
                  onPressed: () =>
                      ref.read(lobbyProvider.notifier).toggleReady(),
                  icon: Icon(
                      isReady ? Icons.check_circle : Icons.circle_outlined),
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
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
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
              subtitle:
                  Text('${room.currentPlayerCount}/${room.maxPlayerCount}'),
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
            backgroundColor: context.gameColors.bgSurface,
            child: Text('$seatNumber'),
          ),
          title: Text(
            '等待加入...',
            style: TextStyle(color: context.gameColors.textSecondary),
          ),
        ),
      );
    }

    return Card(
      color: isCurrentPlayer
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: player!.isHost
              ? context.gameColors.accentAmber
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.gameColors.accentAmberBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '房主',
                  style: TextStyle(
                      fontSize: 10, color: context.gameColors.accentAmber),
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
              Icon(Icons.check_circle,
                  color: context.gameColors.primaryGreen),
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
