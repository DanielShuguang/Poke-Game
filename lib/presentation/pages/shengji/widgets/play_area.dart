import 'package:flutter/material.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';

/// 出牌区域组件
class PlayArea extends StatelessWidget {
  final Map<int, List<ShengjiCard>> plays;
  final int? winnerSeatIndex;
  final double cardHeight;

  const PlayArea({
    super.key,
    required this.plays,
    this.winnerSeatIndex,
    this.cardHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (plays.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 显示每个玩家的出牌
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: plays.entries.map((entry) {
              final isWinner = entry.key == winnerSeatIndex;
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isWinner ? Colors.green.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '座位 ${entry.key + 1}',
                      style: TextStyle(
                        color: isWinner ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: entry.value.map((card) => _buildCard(card)).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (winnerSeatIndex != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '座位 ${winnerSeatIndex! + 1} 赢得此轮',
                style: const TextStyle(color: Colors.yellow, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(ShengjiCard card) {
    return Container(
      width: cardHeight * 0.7,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black26),
      ),
      child: Center(
        child: Text(
          card.toString(),
          style: TextStyle(
            color: card.isRed ? Colors.red : Colors.black,
            fontSize: cardHeight * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
