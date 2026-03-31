import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_notifier.dart';
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_provider.dart';
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_state.dart';
import 'package:poke_game/presentation/pages/doudizhu/widgets/action_buttons_widget.dart';
import 'package:poke_game/presentation/pages/doudizhu/widgets/center_play_area_widget.dart';
import 'package:poke_game/presentation/pages/doudizhu/widgets/hand_cards_widget.dart';
import 'package:poke_game/presentation/pages/doudizhu/widgets/landlord_cards_widget.dart';
import 'package:poke_game/presentation/pages/doudizhu/widgets/player_area_widget.dart';

/// 斗地主游戏页面
class DoudizhuGamePage extends ConsumerStatefulWidget {
  const DoudizhuGamePage({super.key});

  @override
  ConsumerState<DoudizhuGamePage> createState() => _DoudizhuGamePageState();
}

class _DoudizhuGamePageState extends ConsumerState<DoudizhuGamePage> {
  @override
  void initState() {
    super.initState();
    // 强制横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 隐藏状态栏，获得更好的游戏体验
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 页面加载后自动开始游戏
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doudizhuProvider.notifier).startGame();
    });
  }

  @override
  void dispose() {
    // 恢复屏幕方向设置
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doudizhuProvider);
    final notifier = ref.read(doudizhuProvider.notifier);

    // 监听错误和提示消息
    ref.listen<DoudizhuUiState>(doudizhuProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            duration: const Duration(seconds: 2),
          ),
        );
        notifier.clearError();
      }
      if (next.infoMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.infoMessage!),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmExit(context);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 主内容
            Positioned.fill(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildGameBody(context, state, notifier),
            ),
            // 退出按钮（左上角）
            Positioned(
              top: 8,
              left: 8,
              child: SafeArea(
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _confirmExit(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBody(
    BuildContext context,
    DoudizhuUiState state,
    DoudizhuNotifier notifier,
  ) {
    final gameState = state.gameState;

    switch (gameState.phase) {
      case GamePhase.waiting:
        return _buildWaitingScreen();
      case GamePhase.dealing:
        return const Center(child: CircularProgressIndicator());
      case GamePhase.calling:
        return _buildCallingPhase(context, state, notifier);
      case GamePhase.playing:
        return _buildPlayingPhase(context, state, notifier);
      case GamePhase.finished:
        return _buildFinishedScreen(context, state, notifier);
    }
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎮', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          const Text('准备开始游戏...'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('返回首页'),
          ),
        ],
      ),
    );
  }

  Widget _buildCallingPhase(
    BuildContext context,
    DoudizhuUiState state,
    DoudizhuNotifier notifier,
  ) {
    final gameState = state.gameState;
    final isHumanTurn = gameState.callingPlayerIndex == 0;

    return Column(
      children: [
        // 顶部：底牌
        Container(
          padding: const EdgeInsets.all(16),
          child: LandlordCardsWidget(
            cards: gameState.landlordCards,
            revealed: false,
          ),
        ),
        const Spacer(),
        // 中间：叫地主提示
        Text(
          isHumanTurn ? '请选择是否叫地主' : 'AI 正在思考...',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        // 操作按钮
        if (isHumanTurn)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ActionButtonsWidget(
              isCallPhase: true,
              onCall: () => notifier.callLandlord(true),
              onPass: () => notifier.callLandlord(false),
            ),
          ),
        const Spacer(),
        // 底部：手牌
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: HandCardsWidget(
            cards: gameState.players.isNotEmpty
                ? gameState.players[0].handCards
                : [],
            selectedCards: const {},
            enabled: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayingPhase(
    BuildContext context,
    DoudizhuUiState state,
    DoudizhuNotifier notifier,
  ) {
    final gameState = state.gameState;
    final humanPlayer = gameState.players[0];
    final aiPlayer1 = gameState.players[1];
    final aiPlayer2 = gameState.players[2];

    final isHumanTurn = gameState.currentPlayerIndex == 0;
    final canPass = gameState.lastPlayedCards != null &&
        gameState.lastPlayerIndex != 0;

    // 检查玩家是否能打过上家
    final canPlay = state.canPlayerBeatLastPlayer(
      DoudizhuNotifier.humanPlayerId,
      CardValidator(),
    );

    return Column(
      children: [
        // 顶部：AI 玩家
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PlayerAreaWidget(
                name: aiPlayer1.name,
                cardCount: aiPlayer1.handCards.length,
                role: aiPlayer1.role,
                isCurrentPlayer: gameState.currentPlayerIndex == 1,
              ),
              // 底牌（已翻牌）
              LandlordCardsWidget(
                cards: gameState.landlordCards,
                revealed: true,
              ),
              PlayerAreaWidget(
                name: aiPlayer2.name,
                cardCount: aiPlayer2.handCards.length,
                role: aiPlayer2.role,
                isCurrentPlayer: gameState.currentPlayerIndex == 2,
              ),
            ],
          ),
        ),
        const Spacer(),
        // 中央出牌区
        CenterPlayAreaWidget(
          playedCards: gameState.lastPlayedCards,
          playerName: gameState.lastPlayerIndex != null
              ? gameState.players[gameState.lastPlayerIndex!].name
              : null,
        ),
        const Spacer(),
        // 操作按钮
        if (isHumanTurn)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ActionButtonsWidget(
              isCallPhase: false,
              canPass: canPass,
              canPlay: canPlay,
              hasHintCards: state.hintCards != null && state.hintCards!.isNotEmpty,
              onPlay: canPlay ? () => notifier.playCards() : null,
              onPass: canPass ? () => notifier.passTurn() : null,
              onHint: canPlay ? () => notifier.showHintCards() : null,
            ),
          ),
        // 出牌倒计时（仅人类回合显示）
        if (isHumanTurn)
          _TurnCountdown(
            key: ValueKey('turn_${state.turnKey}'),
            seconds: 15,
            canPass: canPass,
            onTimeout: () {
              if (canPass) {
                notifier.passTurn();
              } else {
                notifier.showHintCards();
                notifier.playCards();
              }
            },
          ),
        // 底部：手牌
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              PlayerAreaWidget(
                name: humanPlayer.name,
                cardCount: humanPlayer.handCards.length,
                role: humanPlayer.role,
                isCurrentPlayer: isHumanTurn,
              ),
              const SizedBox(height: 8),
              HandCardsWidget(
                cards: humanPlayer.handCards,
                selectedCards: state.selectedCards,
                enabled: isHumanTurn,
                hintCards: state.hintCards,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedScreen(
    BuildContext context,
    DoudizhuUiState state,
    DoudizhuNotifier notifier,
  ) {
    final gameState = state.gameState;
    final humanPlayer = gameState.players[0];
    final isWinner = state.winners?.contains(humanPlayer.id) ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isWinner ? '🎉 恭喜你赢了！' : '😢 很遗憾，你输了',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => notifier.startGame(),
                child: const Text('再来一局'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
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
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
    }
  }
}

/// 出牌回合倒计时组件
/// 超时后自动触发 [onTimeout]，最后3秒进度条变红并闪烁警告文字
class _TurnCountdown extends StatefulWidget {
  final int seconds;
  final bool canPass;
  final VoidCallback onTimeout;

  const _TurnCountdown({
    super.key,
    required this.seconds,
    required this.canPass,
    required this.onTimeout,
  });

  @override
  State<_TurnCountdown> createState() => _TurnCountdownState();
}

class _TurnCountdownState extends State<_TurnCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )..forward();

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_triggered) {
        _triggered = true;
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final remaining = 1 - _ctrl.value;
        final remainingSecs = (remaining * widget.seconds).ceil();
        final isUrgent = remainingSecs <= 3;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 最后3秒警告文字（闪烁效果用 Opacity 交替）
              if (isUrgent)
                _BlinkText(
                  text: '请尽快出牌！剩余 $remainingSecs 秒',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                )
              else
                Text(
                  '剩余 $remainingSecs 秒',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: remaining,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUrgent ? Colors.red : Colors.teal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 闪烁文字（最后3秒警告用）
class _BlinkText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _BlinkText({required this.text, required this.style});

  @override
  State<_BlinkText> createState() => _BlinkTextState();
}

class _BlinkTextState extends State<_BlinkText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Text(widget.text, style: widget.style),
    );
  }
}
