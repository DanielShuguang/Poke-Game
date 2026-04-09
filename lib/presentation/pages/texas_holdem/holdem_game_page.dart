import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/core/network/holdem_network_adapter.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';
import 'package:poke_game/domain/texas_holdem/usecases/betting_usecases.dart';
import 'package:poke_game/presentation/pages/texas_holdem/holdem_provider.dart';
import 'package:poke_game/presentation/pages/texas_holdem/widgets/community_cards_widget.dart';
import 'package:poke_game/presentation/pages/texas_holdem/widgets/player_seat_widget.dart';
import 'package:poke_game/presentation/pages/texas_holdem/widgets/betting_action_widget.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';
import 'package:poke_game/presentation/shared/widgets/game_back_button.dart';

/// 德州扑克游戏页面
class HoldemGamePage extends ConsumerStatefulWidget {
  /// 是否为联机模式
  final bool isOnline;

  /// 联机网络适配器（联机模式时提供）
  final HoldemNetworkAdapter? networkAdapter;

  final int turnTimeLimit;

  const HoldemGamePage({
    super.key,
    this.isOnline = false,
    this.networkAdapter,
    this.turnTimeLimit = 35,
  });

  @override
  ConsumerState<HoldemGamePage> createState() => _HoldemGamePageState();
}

class _HoldemGamePageState extends ConsumerState<HoldemGamePage> {
  @override
  void initState() {
    super.initState();
    // 锁定横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 联机模式下自动开始；单机模式等待玩家点击开始
    if (widget.isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(holdemGameProvider.notifier).startGame();
      });
    }
  }

  @override
  void dispose() {
    // 恢复所有屏幕方向
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出游戏'),
        content: const Text('确定要退出当前游戏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(holdemGameProvider);
    return Scaffold(
      backgroundColor: context.gameColors.bgTable, // 扑克绿色桌面
      body: SafeArea(
        child: Stack(
          children: [
            // 牌桌主布局
            Column(
              children: [
                // 上方对手席位
                _buildOpponentSeats(state),
                // 中间公牌区 + 底池
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CommunityCardsWidget(
                          communityCards: state.communityCards,
                          phase: state.phase,
                        ),
                        const SizedBox(height: 8),
                        _PotDisplay(totalPot: state.totalPot),
                      ],
                    ),
                  ),
                ),
                // 下方人类玩家区
                _buildHumanPlayerArea(state),
              ],
            ),
            // 左上角退出按钮
            Positioned(
              top: 8,
              left: 8,
              child: SafeArea(
                child: GameBackButton(onPressed: _confirmExit),
              ),
            ),
            // 摊牌结果遮罩
            if (state.phase == GamePhase.finished) _ShowdownOverlay(state: state),
            // 单机等待开始遮罩
            if (state.phase == GamePhase.waiting && !widget.isOnline)
              const _WaitingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildOpponentSeats(HoldemGameState state) {
    final humanId = state.humanPlayerId;
    final opponents = state.players.where((p) => p.id != humanId).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opponents.map((p) {
          final idx = state.players.indexOf(p);
          return PlayerSeatWidget(
            player: p,
            isCurrentPlayer: idx == state.currentPlayerIndex,
            dealerIndex: state.dealerIndex,
            playerIndex: idx,
            smallBlindIndex: state.smallBlindIndex,
            bigBlindIndex: state.bigBlindIndex,
            showHoleCards: state.phase == GamePhase.finished,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHumanPlayerArea(HoldemGameState state) {
    final humanId = state.humanPlayerId;
    final humanIdx = state.players.indexWhere((p) => p.id == humanId);
    if (humanIdx < 0) return const SizedBox.shrink();

    final human = state.players[humanIdx];
    final isMyTurn = humanIdx == state.currentPlayerIndex;
    final isOnline = widget.isOnline;
    final adapter = widget.networkAdapter;

    // 联机模式：非自己回合禁用操作
    final canAct = isMyTurn &&
        state.phase != GamePhase.waiting &&
        state.phase != GamePhase.finished;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerSeatWidget(
          player: human,
          isCurrentPlayer: isMyTurn,
          dealerIndex: state.dealerIndex,
          playerIndex: humanIdx,
          smallBlindIndex: state.smallBlindIndex,
          bigBlindIndex: state.bigBlindIndex,
          showHoleCards: true, // 人类玩家始终看到自己的底牌
        ),
        if (canAct)
          BettingActionWidget(
            state: state,
            player: human,
            onFold: () {
              if (isOnline && adapter != null && !adapter.isHost) {
                adapter.sendAction(const FoldAction());
              } else {
                ref.read(holdemGameProvider.notifier).fold();
              }
            },
            onCheck: () {
              if (isOnline && adapter != null && !adapter.isHost) {
                adapter.sendAction(const CheckAction());
              } else {
                ref.read(holdemGameProvider.notifier).check();
              }
            },
            onCall: () {
              if (isOnline && adapter != null && !adapter.isHost) {
                adapter.sendAction(const CallAction());
              } else {
                ref.read(holdemGameProvider.notifier).call();
              }
            },
            onRaise: (amount) {
              if (isOnline && adapter != null && !adapter.isHost) {
                adapter.sendAction(RaiseAction(amount));
              } else {
                ref.read(holdemGameProvider.notifier).raise(amount);
              }
            },
            onAllIn: () {
              if (isOnline && adapter != null && !adapter.isHost) {
                adapter.sendAction(const AllInAction());
              } else {
                ref.read(holdemGameProvider.notifier).allIn();
              }
            },
          )
        else if (isOnline && !canAct &&
            state.phase != GamePhase.waiting &&
            state.phase != GamePhase.finished)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '等待其他玩家操作...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PotDisplay extends StatelessWidget {
  final int totalPot;
  const _PotDisplay({required this.totalPot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '底池：$totalPot',
        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ShowdownOverlay extends StatelessWidget {
  final HoldemGameState state;
  const _ShowdownOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '本局结束',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context
                    .findAncestorStateOfType<_HoldemGamePageState>()
                    ?._startNextRound(),
                child: const Text('下一局'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on _HoldemGamePageState {
  void _startNextRound() {
    ref.read(holdemGameProvider.notifier).nextRound();
  }

  void _startGame() {
    ref.read(holdemGameProvider.notifier).startGame();
  }
}

class _WaitingOverlay extends StatelessWidget {
  const _WaitingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '德州扑克',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '现金局 · AI 对战',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context
                    .findAncestorStateOfType<_HoldemGamePageState>()
                    ?._startGame(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始游戏'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.gameColors.primaryGreen,
                  foregroundColor: const Color(0xFF0F0F0F),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
