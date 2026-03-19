import 'package:flutter/material.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as game;
import 'package:poke_game/presentation/widgets/playing_card_widget.dart';

/// 中央出牌区域组件
class CenterPlayAreaWidget extends StatefulWidget {
  final List<game.Card>? playedCards;
  final String? playerName;
  final bool isPass;

  const CenterPlayAreaWidget({
    super.key,
    this.playedCards,
    this.playerName,
    this.isPass = false,
  });

  @override
  State<CenterPlayAreaWidget> createState() => _CenterPlayAreaWidgetState();
}

class _CenterPlayAreaWidgetState extends State<CenterPlayAreaWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  List<game.Card>? _lastPlayedCards;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _lastPlayedCards = widget.playedCards;
    if (widget.playedCards != null && widget.playedCards!.isNotEmpty) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CenterPlayAreaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当出牌变化时，重新播放动画
    if (widget.playedCards != _lastPlayedCards) {
      _lastPlayedCards = widget.playedCards;
      if (widget.playedCards != null && widget.playedCards!.isNotEmpty) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playedCards == null || widget.playedCards!.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.playerName != null)
              Text(
                widget.playerName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            if (widget.isPass)
              Text(
                '不出',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              )
            else
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: widget.playedCards!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final card = entry.value;
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      // 错开动画时间
                      final delay = index * 0.05;
                      final delayedValue =
                          (_controller.value - delay).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: delayedValue,
                        child: Transform.scale(
                          scale: 0.8 + 0.2 * delayedValue,
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 44,
                      child: CardWidget(
                        card: card,
                        isSelected: false,
                        faceUp: true,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
