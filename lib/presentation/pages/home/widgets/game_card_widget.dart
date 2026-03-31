import 'package:flutter/material.dart';
import 'package:poke_game/domain/game/entities/game_info.dart';

/// 游戏卡片组件
class GameCardWidget extends StatelessWidget {
  final GameInfo game;
  final VoidCallback onTap;

  /// 联机对战按钮回调（为 null 时不显示按钮）
  final VoidCallback? onOnlineTap;

  const GameCardWidget({
    super.key,
    required this.game,
    required this.onTap,
    this.onOnlineTap,
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
                    if (onOnlineTap != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onOnlineTap,
                          icon: const Icon(Icons.wifi, size: 14),
                          label: const Text('联机对战'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
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
        backgroundColor = const Color(0xFF4ADE80).withValues(alpha: 0.15);
        textColor = const Color(0xFF4ADE80);
        break;
      case GameStatus.comingSoon:
        label = '开发中';
        backgroundColor = const Color(0xFFFBBF24).withValues(alpha: 0.15);
        textColor = const Color(0xFFFBBF24);
        break;
      case GameStatus.planned:
        label = '计划中';
        backgroundColor = const Color(0xFFA1A1AA).withValues(alpha: 0.15);
        textColor = const Color(0xFFA1A1AA);
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
