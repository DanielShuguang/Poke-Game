import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as game;
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_provider.dart';
import 'package:poke_game/presentation/widgets/playing_card_widget.dart';

/// 手牌组件
class HandCardsWidget extends ConsumerWidget {
  final List<game.Card> cards;
  final Set<game.Card> selectedCards;
  final bool enabled;
  final Set<game.Card>? hintCards;

  const HandCardsWidget({
    super.key,
    required this.cards,
    required this.selectedCards,
    this.enabled = true,
    this.hintCards,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: cards.map((card) {
            final isSelected = selectedCards.contains(card);
            final isHint = hintCards?.contains(card) ?? false;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Padding(
                key: ValueKey('${card.suit}_${card.rank}_$isSelected'),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: CardWidget(
                  card: card,
                  isSelected: isSelected,
                  isHint: isHint && !isSelected,
                  onTap: enabled
                      ? () {
                          ref
                              .read(doudizhuProvider.notifier)
                              .toggleCardSelection(card);
                        }
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
