import 'package:flutter/material.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

/// 手牌显示组件
class CardHand extends StatelessWidget {
  final List<ShengjiCard> cards;
  final Set<ShengjiCard> selectedCards;
  final void Function(ShengjiCard card) onCardTap;
  final double cardHeight;

  const CardHand({
    super.key,
    required this.cards,
    required this.selectedCards,
    required this.onCardTap,
    this.cardHeight = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight + 20,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          final isSelected = selectedCards.contains(card);
          return GestureDetector(
            onTap: () => onCardTap(card),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Transform.translate(
                offset: Offset(0, isSelected ? -10 : 0),
              ).transform,
              child: _buildCard(context, card, isSelected: isSelected),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, ShengjiCard card,
      {bool isSelected = false}) {
    final colors = context.gameColors;
    final cardColor =
        card.isRed ? colors.cardBorderRed : colors.textPrimary;
    final borderColor = card.isBigJoker
        ? colors.cardBorderGold
        : card.isRed
            ? colors.cardBorderRed
            : colors.cardBorderBlack;
    final effectiveBorderColor =
        isSelected ? colors.cardSelectedGlow : borderColor;

    return Container(
      width: cardHeight * 0.7,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.cardBg1, colors.cardBg2],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: effectiveBorderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 4,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.toString(),
          style: TextStyle(
            color: cardColor,
            fontSize: cardHeight * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
