import 'package:flutter/material.dart';
import 'package:poke_game/domain/guandan/entities/guandan_card.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

/// 掼蛋手牌展示组件
class GuandanHandWidget extends StatelessWidget {
  final List<GuandanCard> cards;
  final Set<int> selectedIndices;
  final bool faceDown;
  final bool isHorizontal;
  final double cardWidth;
  final double cardHeight;
  final void Function(int index)? onCardTap;

  const GuandanHandWidget({
    super.key,
    required this.cards,
    this.selectedIndices = const {},
    this.faceDown = false,
    this.isHorizontal = true,
    this.cardWidth = 40,
    this.cardHeight = 60,
    this.onCardTap,
  });

  static const double _hOverlap = 20.0; // 水平叠牌遮挡量
  static const double _vOverlap = 30.0; // 垂直叠牌遮挡量
  static const double _liftHeight = 12.0; // 选中时抬起高度

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    if (isHorizontal) {
      // 每张牌占据 (cardWidth - _hOverlap) 宽度，最后一张占完整宽度
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
            children: List.generate(cards.length, _buildHCard),
          ),
        ),
      );
    }

    // 竖向（左右两侧对手）
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

  /// 水平排列中第 i 张牌
  Widget _buildHCard(int i) {
    final isSelected = selectedIndices.contains(i);
    final slotW = cardWidth - _hOverlap;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 120),
      left: i * slotW,
      bottom: isSelected ? _liftHeight : 0,
      child: GestureDetector(
        onTap: onCardTap != null ? () => onCardTap!(i) : null,
        child: _buildCardBox(cards[i], isSelected),
      ),
    );
  }

  /// 竖向排列中第 i 张牌（不可选）
  Widget _buildVCard(int i) {
    final slotH = cardHeight - _vOverlap;
    return Positioned(
      top: i * slotH,
      left: 0,
      right: 0,
      child: _buildCardBox(cards[i], false),
    );
  }

  Widget _buildCardBox(GuandanCard card, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? GameColors.dark.accentAmber : Colors.white24,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: isSelected ? 6 : 2,
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
