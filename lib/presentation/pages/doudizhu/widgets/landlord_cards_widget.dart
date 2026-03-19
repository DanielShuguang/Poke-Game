import 'package:flutter/material.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as game;
import 'package:poke_game/presentation/widgets/playing_card_widget.dart';

/// 底牌展示组件
class LandlordCardsWidget extends StatelessWidget {
  final List<game.Card> cards;
  final bool revealed;

  const LandlordCardsWidget({
    super.key,
    required this.cards,
    this.revealed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '底牌',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          ...cards.map((card) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: CardWidget(
                card: card,
                faceUp: revealed,
                width: 36,
                height: 50,
              ),
            );
          }),
        ],
      ),
    );
  }
}
