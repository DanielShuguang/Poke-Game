import 'package:flutter/material.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_player.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

class OpponentSeat extends StatelessWidget {
  final PdkPlayer player;
  final bool isCurrentPlayer;

  const OpponentSeat({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 背面手牌扇形
        SizedBox(
          width: 60,
          height: 40,
          child: Stack(
            children: List.generate(
              player.hand.length.clamp(0, 5),
              (i) => Positioned(
                left: i * 8.0,
                child: Transform.rotate(
                  angle: (i - 2) * 0.08,
                  child: Container(
                    width: 24,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.cardBackBg,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: colors.cardBorderBlack.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isCurrentPlayer
                ? colors.primaryGreen.withValues(alpha: 0.8)
                : colors.overlay,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${player.name} (${player.hand.length}张)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
