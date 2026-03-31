import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as game;
import 'package:poke_game/presentation/shared/game_colors.dart';

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
    final colors = context.gameColors;

    // 正常状态下按花色区分边框
    final normalBorderColor = widget.card.isBigJoker
        ? colors.cardBorderGold
        : widget.card.isRed
            ? colors.cardBorderRed
            : colors.cardBorderBlack;

    Color borderColor;
    double borderWidth;
    Color shadowColor;
    double blurRadius;
    double shadowOffset;

    if (widget.isSelected) {
      borderColor = colors.cardSelectedGlow;
      borderWidth = 2;
      shadowColor = colors.cardSelectedGlow.withValues(alpha: 0.5);
      blurRadius = 10;
      shadowOffset = 4;
    } else if (widget.isPreview) {
      borderColor = colors.cardSelectedGlow.withValues(alpha: 0.7);
      borderWidth = 2;
      shadowColor = colors.cardSelectedGlow.withValues(alpha: 0.3);
      blurRadius = 8;
      shadowOffset = 2;
    } else if (widget.isHint) {
      borderColor = colors.accentAmber;
      borderWidth = 2;
      shadowColor = colors.accentAmber.withValues(alpha: 0.3);
      blurRadius = 8;
      shadowOffset = 2;
    } else {
      borderColor = normalBorderColor;
      borderWidth = 1;
      shadowColor = const Color(0x4D000000);
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
              gradient: widget.faceUp
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.cardBg1, colors.cardBg2],
                    )
                  : null,
              color: widget.faceUp ? null : colors.cardBackBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: blurRadius,
                  spreadRadius: borderWidth > 1 ? 1 : 0,
                  offset: Offset(0, shadowOffset),
                ),
              ],
            ),
            child: widget.faceUp
                ? _buildCardFace(colors)
                : _buildCardBack(colors),
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

  Widget _buildCardFace(GameColors colors) {
    final isSmall = (widget.width ?? 48) < 40;
    final smallFontSize = isSmall ? 9.0 : 11.0;
    final largeFontSize = isSmall ? 16.0 : 22.0;
    final cardColor =
        widget.card.isRed ? colors.cardBorderRed : colors.textPrimary;

    if (widget.card.isJoker) {
      return _buildJokerFace(isSmall, colors);
    }

    final suitText = widget.card.suitSymbol;
    final rankText = widget.card.displayText;

    return Padding(
      padding: EdgeInsets.all(isSmall ? 2 : 3),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rankText,
                    style: TextStyle(
                        fontSize: smallFontSize,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                        height: 1.1)),
                Text(suitText,
                    style: TextStyle(
                        fontSize: smallFontSize, color: cardColor, height: 1.0)),
              ],
            ),
          ),
          Center(
            child: Text(suitText,
                style: TextStyle(fontSize: largeFontSize, color: cardColor)),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
              angle: pi,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rankText,
                      style: TextStyle(
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                          height: 1.1)),
                  Text(suitText,
                      style: TextStyle(
                          fontSize: smallFontSize,
                          color: cardColor,
                          height: 1.0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJokerFace(bool isSmall, GameColors colors) {
    final suitText = widget.card.suitSymbol;
    final rankText = widget.card.displayText;
    final jokerColor = widget.card.isBigJoker
        ? colors.cardBorderGold
        : colors.cardBorderBlack;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(suitText, style: TextStyle(fontSize: isSmall ? 14 : 20)),
          SizedBox(height: isSmall ? 2 : 4),
          Text(rankText,
              style: TextStyle(
                  fontSize: isSmall ? 9 : 11,
                  fontWeight: FontWeight.bold,
                  color: jokerColor)),
        ],
      ),
    );
  }

  Widget _buildCardBack(GameColors colors) {
    return Center(
      child: Text('🂠',
          style: TextStyle(fontSize: 24, color: colors.cardBorderBlack)),
    );
  }
}
