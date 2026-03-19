import 'package:flutter/material.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as game;

/// 卡牌组件
class CardWidget extends StatefulWidget {
  final game.Card card;
  final bool isSelected;
  final bool faceUp;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool isHint; // 是否是提示的牌
  final bool isPreview; // 是否是拖拽预览选中的牌

  const CardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.faceUp = true,
    this.onTap,
    this.width,
    this.height,
    this.isHint = false,
    this.isPreview = false,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _hintAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHint && !oldWidget.isHint) {
      _hintController.repeat(reverse: true);
    } else if (!widget.isHint && oldWidget.isHint) {
      _hintController.stop();
      _hintController.reset();
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 确定边框颜色
    Color borderColor;
    double borderWidth;
    Color shadowColor;
    double blurRadius;
    double shadowOffset;

    if (widget.isSelected) {
      borderColor = Colors.green;
      borderWidth = 2;
      shadowColor = Colors.green.withValues(alpha: 0.4);
      blurRadius = 8;
      shadowOffset = 4;
    } else if (widget.isPreview) {
      borderColor = Colors.blue;
      borderWidth = 2;
      shadowColor = Colors.blue.withValues(alpha: 0.3);
      blurRadius = 8;
      shadowOffset = 2;
    } else if (widget.isHint) {
      borderColor = Colors.amber;
      borderWidth = 2;
      shadowColor = Colors.amber.withValues(alpha: 0.3);
      blurRadius = 8;
      shadowOffset = 2;
    } else {
      borderColor = Colors.grey.shade300;
      borderWidth = 1;
      shadowColor = Colors.black.withValues(alpha: 0.1);
      blurRadius = 4;
      shadowOffset = 2;
    }

    Widget cardContent = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: widget.isSelected
            ? Matrix4.translationValues(0, -20, 0)
            : Matrix4.identity(),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: widget.isSelected ? 1.05 : 1.0,
          child: Container(
            width: widget.width ?? 48,
            height: widget.height ?? 68,
            decoration: BoxDecoration(
              color: widget.faceUp ? Colors.white : Colors.blue.shade700,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: blurRadius,
                  offset: Offset(0, shadowOffset),
                ),
              ],
            ),
            child: widget.faceUp ? _buildCardFace() : _buildCardBack(),
          ),
        ),
      ),
    );

    // 如果是提示的牌，添加呼吸动画
    if (widget.isHint) {
      return AnimatedBuilder(
        animation: _hintAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hintAnimation.value,
            child: child,
          );
        },
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildCardFace() {
    // 根据卡片大小调整字体
    final isSmall = (widget.width ?? 48) < 40;
    final suitSize = isSmall ? 14.0 : 22.0;
    final textSize = isSmall ? 11.0 : 16.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.card.suitSymbol,
            style: TextStyle(
              fontSize: suitSize,
              color: widget.card.isRed ? Colors.red : Colors.black,
            ),
          ),
          SizedBox(height: isSmall ? 1 : 2),
          Text(
            widget.card.displayText,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: widget.card.isRed ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          '🂠',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
