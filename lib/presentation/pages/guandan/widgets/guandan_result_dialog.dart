import 'package:flutter/material.dart';
import 'package:poke_game/domain/guandan/entities/guandan_game_state.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

/// 掼蛋局结算弹窗
class GuandanResultDialog extends StatelessWidget {
  final GuandanGameState state;
  final String localPlayerId;
  final VoidCallback? onPlayAgain;

  const GuandanResultDialog({
    super.key,
    required this.state,
    required this.localPlayerId,
    this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final result = state.roundResult;
    if (result == null) return const SizedBox.shrink();

    final colors = GameColors.dark;
    final isFinished = state.phase == GuandanPhase.finished;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2838),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.accentAmber.withAlpha(120)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                isFinished ? '游戏结束' : '本局结算',
                style: TextStyle(
                  color: colors.accentAmber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 出局顺序
              _buildFinishOrder(result, colors),
              const SizedBox(height: 16),

              // 级牌变化
              _buildLevelChanges(result, colors),

              if (isFinished) ...[
                const SizedBox(height: 16),
                _buildGameOverBanner(colors),
              ],

              const SizedBox(height: 20),

              // 按钮
              if (onPlayAgain != null)
                ElevatedButton(
                  onPressed: onPlayAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentAmber,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 44),
                  ),
                  child: const Text('再来一局'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishOrder(RoundResult result, GameColors colors) {
    final labels = ['头游', '二游', '三游', '四游'];
    return Column(
      children: [
        for (int i = 0; i < result.finishOrder.length && i < 4; i++)
          _buildOrderRow(
            rank: labels[i],
            playerId: result.finishOrder[i],
            isFirst: i == 0,
            colors: colors,
          ),
      ],
    );
  }

  Widget _buildOrderRow({
    required String rank,
    required String playerId,
    required bool isFirst,
    required GameColors colors,
  }) {
    final player = state.getPlayerById(playerId);
    final name = player?.name ?? playerId;
    final isLocal = playerId == localPlayerId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isFirst
                  ? colors.accentAmber.withAlpha(200)
                  : Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rank,
              style: TextStyle(
                color: isFirst ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isLocal ? '$name（我）' : name,
            style: TextStyle(
              color: isLocal ? colors.accentAmber : Colors.white,
              fontSize: 14,
              fontWeight: isLocal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (player != null) ...[
            const Spacer(),
            Text(
              '队伍${player.teamId}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelChanges(RoundResult result, GameColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTeamLevel(
            teamId: 0,
            currentLevel: state.team0Level,
            delta: result.team0LevelDelta,
            colors: colors,
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          _buildTeamLevel(
            teamId: 1,
            currentLevel: state.team1Level,
            delta: result.team1LevelDelta,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLevel({
    required int teamId,
    required int currentLevel,
    required int delta,
    required GameColors colors,
  }) {
    final levelText = _levelName(currentLevel);
    final deltaText = delta > 0
        ? '+$delta'
        : delta < 0
            ? '$delta'
            : '±0';
    final deltaColor = delta > 0
        ? Colors.greenAccent
        : delta < 0
            ? Colors.redAccent
            : Colors.white38;

    return Column(
      children: [
        Text(
          '队伍$teamId',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          levelText,
          style: TextStyle(
            color: colors.accentAmber,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          deltaText,
          style: TextStyle(
            color: deltaColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverBanner(GameColors colors) {
    final team0Wins = state.team0Level > state.team1Level;
    final winTeam = team0Wins ? 0 : 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.accentAmber.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.accentAmber.withAlpha(100)),
      ),
      child: Text(
        '队伍$winTeam 胜利！',
        style: TextStyle(
          color: colors.accentAmber,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _levelName(int level) => switch (level) {
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        14 => 'A',
        _ => level.toString(),
      };
}
