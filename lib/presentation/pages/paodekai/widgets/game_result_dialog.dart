import 'package:flutter/material.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_game_state.dart';
import 'package:poke_game/domain/paodekai/usecases/calculate_score_usecase.dart';

class GameResultDialog extends StatelessWidget {
  final PdkGameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const GameResultDialog({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    const scoreUseCase = CalculateScoreUseCase();
    final scores = scoreUseCase(state.rankings);
    const rankLabels = ['🥇 头游', '🥈 二游', '🥉 末游'];
    const scoreLabels = ['+2', '+0', '-2'];

    return Dialog(
      backgroundColor: const Color(0xFF1B3A2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '游戏结束',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(state.rankings.length, (i) {
              final pid = state.rankings[i];
              final player = state.players.firstWhere(
                (p) => p.id == pid,
                orElse: () => state.players.first,
              );
              final delta = scores[pid] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rankLabels[i],
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      player.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      scoreLabels[i],
                      style: TextStyle(
                        color: delta > 0
                            ? Colors.greenAccent
                            : delta < 0
                                ? Colors.redAccent
                                : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                    ),
                    child: const Text(
                      '返回首页',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D52),
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
}
