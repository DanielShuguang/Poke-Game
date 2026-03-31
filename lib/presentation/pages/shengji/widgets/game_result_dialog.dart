import 'package:flutter/material.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';

/// 游戏结果对话框
class GameResultDialog extends StatelessWidget {
  final ShengjiGameState gameState;
  final VoidCallback onContinue;
  final VoidCallback onExit;

  const GameResultDialog({
    super.key,
    required this.gameState,
    required this.onContinue,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '本局结束',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 得分显示
            for (final team in gameState.teams)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '队伍 ${team.id + 1}',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '得分: ${team.roundScore}',
                      style: const TextStyle(color: Colors.yellow, fontSize: 18),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '级别: ${team.levelName}',
                      style: const TextStyle(color: Colors.green, fontSize: 18),
                    ),
                    if (team.isDealer)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '庄家',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // 结果消息
            if (gameState.message != null)
              Text(
                gameState.message!,
                style: const TextStyle(color: Colors.yellow, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            // 操作按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('继续'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onExit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('退出'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
