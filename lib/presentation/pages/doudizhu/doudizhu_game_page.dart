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

    // 监听错误
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
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildGameBody(context, state, notifier),
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

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出游戏'),
        content: const Text('确定要退出当前游戏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
