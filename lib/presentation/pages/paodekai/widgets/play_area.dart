import 'package:flutter/material.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_card.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_hand_type.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

class PlayArea extends StatelessWidget {
  final PdkPlayedHand? lastPlayedHand;
  final String? lastPlayerName;
  final String currentPlayerName;

  const PlayArea({
    super.key,
    this.lastPlayedHand,
    this.lastPlayerName,
    required this.currentPlayerName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上方：最后出牌区
        if (lastPlayedHand != null) ...[
          if (lastPlayerName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '$lastPlayerName 出:',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          Wrap(
            spacing: 4,
            children:
                lastPlayedHand!.cards.map((c) => _MiniCard(card: c)).toList(),
          ),
          const SizedBox(height: 12),
        ] else ...[
          const Text(
            '新一轮',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],

        // 下方：当前出牌提示
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.overlay,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '轮到 $currentPlayerName 出牌',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final PdkCard card;
  const _MiniCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final isRed = card.isRed;
    return Container(
      width: 36,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.cardBg1, colors.cardBg2],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isRed
              ? colors.cardBorderRed.withValues(alpha: 0.7)
              : colors.cardBorderBlack.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.suitSymbol,
            style: TextStyle(
              color: isRed ? colors.cardBorderRed : colors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            card.rankDisplay,
            style: TextStyle(
              color: isRed ? colors.cardBorderRed : colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
