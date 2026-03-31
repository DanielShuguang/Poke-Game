// lib/presentation/shared/widgets/game_back_button.dart
import 'package:flutter/material.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

/// 所有游戏页面统一退出按钮
class GameBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GameBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: colors.bgSurface,
        foregroundColor: colors.textSecondary,
      ),
      icon: const Icon(Icons.arrow_back),
      onPressed: onPressed,
    );
  }
}
