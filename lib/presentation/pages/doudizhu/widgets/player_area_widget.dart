import 'package:flutter/material.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';

/// 玩家区域组件
class PlayerAreaWidget extends StatelessWidget {
  final String name;
  final int cardCount;
  final PlayerRole? role;
  final bool isCurrentPlayer;

  const PlayerAreaWidget({
    super.key,
    required this.name,
    required this.cardCount,
    this.role,
    this.isCurrentPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 玩家名称和角色
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (role != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: role == PlayerRole.landlord
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role == PlayerRole.landlord ? '地主' : '农民',
                    style: TextStyle(
                      fontSize: 10,
                      color: role == PlayerRole.landlord
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // 卡牌数量
          Text(
            '剩余: $cardCount 张',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
