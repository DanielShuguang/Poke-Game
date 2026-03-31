import 'package:flutter/material.dart';
import 'package:poke_game/domain/shengji/entities/shengji_team.dart';

/// 计分板组件
class ScoreBoard extends StatelessWidget {
  final List<ShengjiTeam> teams;

  const ScoreBoard({
    super.key,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < teams.length; i++) ...[
            _buildTeamScore(teams[i]),
            if (i < teams.length - 1)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: const Text(
                  'VS',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamScore(ShengjiTeam team) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 队伍标识
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: team.isDealer ? Colors.orange.shade700 : Colors.blue.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            team.isDealer ? '庄' : '闲',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        const SizedBox(width: 6),
        // 级别和得分
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${team.levelName}级',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              '${team.roundScore}分',
              style: const TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
