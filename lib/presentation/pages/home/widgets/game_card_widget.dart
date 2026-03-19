import 'package:flutter/material.dart';
import 'package:poke_game/domain/game/entities/game_info.dart';

/// 游戏卡片组件
class GameCardWidget extends StatelessWidget {
  final GameInfo game;
  final VoidCallback onTap;

  const GameCardWidget({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 游戏图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    game.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 游戏信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            game.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildStatusBadge(context),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 箭头图标
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    String label;
    Color backgroundColor;
    Color textColor;

    switch (game.status) {
      case GameStatus.available:
        label = '已上线';
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case GameStatus.comingSoon:
        label = '开发中';
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      case GameStatus.planned:
        label = '计划中';
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
