import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as game;
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_provider.dart';
import 'package:poke_game/presentation/shared/widgets/drag_select_card_hand.dart';
import 'package:poke_game/presentation/widgets/playing_card_widget.dart';

/// 手牌组件（支持拖拽选牌，基于共享 DragSelectCardHand）
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
    return DragSelectCardHand(
      cardCount: cards.length,
      enabled: enabled,
      height: 96,
      cardBuilder: (i, {required isDragged, required isPreview}) {
        final card = cards[i];
        final isSelected = selectedCards.contains(card);
        final isHint = hintCards?.contains(card) ?? false;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: CardWidget(
            card: card,
            isSelected: isSelected,
            isHint: isHint && !isSelected,
            isPreview: isPreview && !isSelected,
          ),
        );
      },
      calculatePreview: (draggedIndices) => _calculatePreview(
        ref,
        draggedIndices,
      ),
      onDragEnd: (selectedIndices) {
        final draggedCards = selectedIndices.map((i) => cards[i]).toList();
        ref.read(doudizhuProvider.notifier).selectCardsByDrag(draggedCards);
      },
      onTap: enabled
          ? (index) {
              ref
                  .read(doudizhuProvider.notifier)
                  .toggleCardSelection(cards[index]);
            }
          : null,
    );
  }

  /// 计算预览选中的牌（索引集合）
  Set<int> _calculatePreview(WidgetRef ref, List<int> draggedIndices) {
    if (draggedIndices.isEmpty) return {};

    final draggedCards = draggedIndices.map((i) => cards[i]).toList();
    final lastPlayedCards =
        ref.read(doudizhuProvider).gameState.lastPlayedCards;
    final validator = ref.read(doudizhuProvider.notifier).validator;

    List<game.Card>? result;
    if (lastPlayedCards == null) {
      result = validator.findBestCombination(draggedCards);
    } else {
      result = validator.findMinBeatingCombination(
        draggedCards,
        lastPlayedCards,
      );
    }
    if (result == null) return {};

    final resultSet = result.toSet();
    return draggedIndices.where((i) => resultSet.contains(cards[i])).toSet();
  }
}
