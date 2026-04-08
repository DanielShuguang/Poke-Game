import 'package:flutter/material.dart';
import 'package:poke_game/domain/guandan/entities/guandan_card.dart';
import 'package:poke_game/domain/guandan/entities/guandan_game_state.dart';
import 'package:poke_game/domain/guandan/entities/guandan_hand.dart';
import 'package:poke_game/presentation/pages/guandan/widgets/guandan_hand_widget.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

/// 掼蛋中央出牌区组件
class GuandanPlayAreaWidget extends StatelessWidget {
  final GuandanGameState state;
  final Set<int> selectedIndices;
  final List<GuandanCard> localHand;
  final bool isLocalTurn;
  final bool canPlay;
  final bool canPass;
  final VoidCallback onPlay;
  final VoidCallback onPass;
  final VoidCallback onHint;

  const GuandanPlayAreaWidget({
    super.key,
    required this.state,
    required this.selectedIndices,
    required this.localHand,
    required this.isLocalTurn,
    required this.canPlay,
    required this.canPass,
    required this.onPlay,
    required this.onPass,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final lastHand = state.lastPlayedHand;
    final currentLevel = state.currentLevel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 当前级牌提示
        _buildLevelBadge(currentLevel),
        const SizedBox(height: 8),

        // 场上最后一手牌
        _buildLastPlayedArea(lastHand),
        const SizedBox(height: 12),

        // 出牌/不出按钮
        if (isLocalTurn) _buildActionButtons(context),
      ],
    );
  }

  Widget _buildLevelBadge(int level) {
    final levelText = switch (level) {
      11 => 'J',
      12 => 'Q',
      13 => 'K',
      14 => 'A',
      _ => level.toString(),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: GameColors.dark.accentAmber.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '级牌: $levelText',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildLastPlayedArea(GuandanHand? lastHand) {
    if (lastHand == null) {
      return Container(
        height: 72,
        alignment: Alignment.center,
        child: const Text(
          '首出',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        Text(
          _handTypeName(lastHand),
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        GuandanHandWidget(
          cards: lastHand.cards,
          cardWidth: 36,
          cardHeight: 54,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 提示按钮
        IconButton(
          onPressed: onHint,
          icon: const Icon(Icons.lightbulb_outline, color: Colors.white54),
          tooltip: '提示',
        ),
        const SizedBox(width: 8),

        // 不出按钮
        if (canPass)
          OutlinedButton(
            onPressed: onPass,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white38),
            ),
            child: const Text('不出'),
          ),
        const SizedBox(width: 16),

        // 出牌按钮
        ElevatedButton(
          onPressed: canPlay ? onPlay : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.dark.accentAmber,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white12,
          ),
          child: const Text('出牌'),
        ),
      ],
    );
  }

  String _handTypeName(GuandanHand hand) {
    return switch (hand.type.name) {
      'single' => '单张',
      'pair' => '对子',
      'triple' => '三张',
      'triplePair' => '三带二',
      'straight' => '顺子',
      'consecutivePairs' => '连对',
      'steelPlate' => '钢板',
      'bomb' => '炸弹',
      'straightFlushBomb' => '同花顺炸',
      'kingBomb' => '天王炸',
      _ => '',
    };
  }
}
