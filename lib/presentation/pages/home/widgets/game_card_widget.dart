import 'package:flutter/material.dart';
import 'package:poke_game/domain/game/entities/game_info.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

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
    final colors = context.gameColors;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: colors.bgSurface,
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
                  color: colors.primaryGreen.withValues(alpha: 0.1),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        _buildStatusBadge(context, colors),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
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
                            foregroundColor: colors.primaryGreen,
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
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, GameColors colors) {
    String label;
    Color backgroundColor;
    Color textColor;

    switch (game.status) {
      case GameStatus.available:
        label = '已上线';
        backgroundColor = colors.primaryGreen.withValues(alpha: 0.15);
        textColor = colors.primaryGreen;
        break;
      case GameStatus.comingSoon:
        label = '开发中';
        backgroundColor = colors.accentAmber.withValues(alpha: 0.15);
        textColor = colors.accentAmber;
        break;
      case GameStatus.planned:
        label = '计划中';
        backgroundColor = colors.textSecondary.withValues(alpha: 0.15);
        textColor = colors.textSecondary;
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
