import 'package:flutter/material.dart';
import 'package:poke_game/domain/guandan/entities/guandan_card.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';
import 'package:poke_game/presentation/shared/widgets/drag_select_card_hand.dart';

/// 掼蛋手牌展示组件（水平本家支持拖拽选牌，竖向对手保留 Stack 布局）
class GuandanHandWidget extends StatelessWidget {
  final List<GuandanCard> cards;
  final Set<int> selectedIndices;
  final bool faceDown;
  final bool isHorizontal;
  final double cardWidth;
  final double cardHeight;
  final void Function(int index)? onCardTap;

  /// 拖拽预览计算回调（仅水平交互模式使用）
  final Set<int> Function(List<int> draggedIndices)? calculatePreview;

  /// 拖拽结束选中确认回调
  final void Function(Set<int> selectedIndices)? onDragEnd;

  const GuandanHandWidget({
    super.key,
    required this.cards,
    this.selectedIndices = const {},
    this.faceDown = false,
    this.isHorizontal = true,
    this.cardWidth = 40,
    this.cardHeight = 60,
    this.onCardTap,
    this.calculatePreview,
    this.onDragEnd,
  });

  static const double _hOverlap = 20.0;
  static const double _vOverlap = 30.0;
  static const double _liftHeight = 12.0;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    // 水平且可交互（本家手牌）→ 使用共享拖拽组件
    if (isHorizontal && onCardTap != null) {
      return _buildDragSelectHand();
    }

    // 水平展示（不可交互，如结算展示）
    if (isHorizontal) {
      return _buildHorizontalStack();
    }

    // 竖向（左右对手）
    return _buildVerticalStack();
  }

  /// 使用 DragSelectCardHand 的水平交互手牌
  Widget _buildDragSelectHand() {
    return DragSelectCardHand(
      cardCount: cards.length,
      enabled: onCardTap != null,
      height: cardHeight + _liftHeight,
      cardBuilder: (i, {required isDragged, required isPreview}) {
        final isSelected = selectedIndices.contains(i);
        final lift = isSelected || isPreview;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            transform: Matrix4.translationValues(
              0,
              lift ? -_liftHeight : 0,
              0,
            ),
            child: _buildCardBox(
              cards[i],
              isSelected: isSelected,
              isPreview: isPreview,
            ),
          ),
        );
      },
      calculatePreview: calculatePreview,
      onDragEnd: onDragEnd,
      onTap: onCardTap,
    );
  }

  /// 水平 Stack 布局（不可交互）
  Widget _buildHorizontalStack() {
    final slotW = cardWidth - _hOverlap;
    final totalW = cards.length == 1
        ? cardWidth
        : (cards.length - 1) * slotW + cardWidth;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalW,
        height: cardHeight + _liftHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(cards.length, _buildHCardNonInteractive),
        ),
      ),
    );
  }

  /// 竖向 Stack 布局（对手手牌）
  Widget _buildVerticalStack() {
    final slotH = cardHeight - _vOverlap;
    final totalH = cards.length == 1
        ? cardHeight
        : (cards.length - 1) * slotH + cardHeight;
    return SizedBox(
      width: cardWidth + 8,
      height: totalH,
      child: Stack(
        children: List.generate(cards.length, _buildVCard),
      ),
    );
  }

  /// 水平非交互卡牌（保留原 Stack 定位）
  Widget _buildHCardNonInteractive(int i) {
    final isSelected = selectedIndices.contains(i);
    final slotW = cardWidth - _hOverlap;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 120),
      left: i * slotW,
      bottom: isSelected ? _liftHeight : 0,
      child: _buildCardBox(cards[i], isSelected: isSelected),
    );
  }

  /// 竖向卡牌
  Widget _buildVCard(int i) {
    final slotH = cardHeight - _vOverlap;
    return Positioned(
      top: i * slotH,
      left: 0,
      right: 0,
      child: _buildCardBox(cards[i]),
    );
  }

  Widget _buildCardBox(
    GuandanCard card, {
    bool isSelected = false,
    bool isPreview = false,
  }) {
    Color borderColor;
    double borderWidth;

    if (isSelected) {
      borderColor = GameColors.dark.accentAmber;
      borderWidth = 2;
    } else if (isPreview) {
      borderColor = GameColors.dark.primaryGreen;
      borderWidth = 2;
    } else {
      borderColor = Colors.white24;
      borderWidth = 1;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: isPreview
                ? GameColors.dark.primaryGreen.withValues(alpha: 0.3)
                : Colors.black54,
            blurRadius: isSelected || isPreview ? 6 : 2,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: faceDown ? _buildBack() : _buildFront(card, isSelected),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      color: const Color(0xFF1E3A6E),
      child: const Center(
        child: Icon(Icons.style, color: Colors.white38, size: 20),
      ),
    );
  }

  Widget _buildFront(GuandanCard card, bool isSelected) {
    final isRed = card.isRed;
    final bgColor = isSelected ? const Color(0xFFFFF8E1) : Colors.white;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.displayText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isRed ? Colors.red : Colors.black87,
              height: 1.0,
            ),
          ),
          if (!card.isJoker) ...[
            Text(
              card.suitSymbol,
              style: TextStyle(
                fontSize: 11,
                color: isRed ? Colors.red : Colors.black87,
                height: 1.0,
              ),
            ),
          ],
          if (card.isWild)
            const Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  '★',
                  style: TextStyle(fontSize: 9, color: Colors.orange),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
