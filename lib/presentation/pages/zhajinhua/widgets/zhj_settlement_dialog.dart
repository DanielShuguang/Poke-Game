import 'package:flutter/material.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';

/// 结算弹窗
class ZhjSettlementDialog extends StatelessWidget {
  final ZhjGameState gameState;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const ZhjSettlementDialog({
    super.key,
    required this.gameState,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final winner = gameState.players.firstWhere(
      (p) => p.id == gameState.winnerId,
      orElse: () => gameState.alivePlayers.first,
    );
    final isHumanWinner = winner.id == 'human';

    return Dialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHumanWinner ? '🎉 你赢了！' : '💸 本局结束',
              style: TextStyle(
                color: isHumanWinner ? Colors.amber : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '胜者：${winner.name}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            // 各玩家筹码变化
            ..._buildPlayerResults(gameState),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('返回大厅'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('再来一局'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlayerResults(ZhjGameState state) {
    return state.players.map((p) {
      final isWinner = p.id == state.winnerId;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              if (isWinner)
                const Text('👑 ', style: TextStyle(fontSize: 14))
              else
                const SizedBox(width: 20),
              Text(p.name,
                  style: TextStyle(
                    color: isWinner ? Colors.amber : Colors.white70,
                    fontSize: 14,
                  )),
            ]),
            Text(
              '💰 ${p.chips}',
              style: TextStyle(
                color: isWinner ? Colors.amber : Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
