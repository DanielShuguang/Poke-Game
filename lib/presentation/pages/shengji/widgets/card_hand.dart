import 'package:flutter/material.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';

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
              child: _buildCard(card),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(ShengjiCard card) {
    return Container(
      width: cardHeight * 0.7,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.toString(),
          style: TextStyle(
            color: card.isRed ? Colors.red : Colors.black,
            fontSize: cardHeight * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
