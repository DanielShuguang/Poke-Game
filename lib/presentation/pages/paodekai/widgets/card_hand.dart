import 'package:flutter/material.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_card.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_game_state.dart';
import 'package:poke_game/domain/paodekai/usecases/validate_play_usecase.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';
import 'package:poke_game/presentation/shared/widgets/drag_select_card_hand.dart';

class CardHand extends StatelessWidget {
  static const _validate = ValidatePlayUseCase();

  final List<PdkCard> cards;
  final Set<int> selectedIndices;
  final Set<int> hintIndices;
  final bool enabled;
  final ValueChanged<int> onCardTap;
  final ValueChanged<Set<int>>? onSelectionChanged;

  const CardHand({
    super.key,
    required this.cards,
    required this.selectedIndices,
    this.hintIndices = const {},
    this.enabled = true,
    required this.onCardTap,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DragSelectCardHand(
      cardCount: cards.length,
      enabled: enabled,
      height: 80,
      cardBuilder: (i, {required isDragged, required isPreview}) {
        final selected = selectedIndices.contains(i);
        final isHint = hintIndices.contains(i) && !selected;
        final showPreview = isPreview && !selected;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          transform: Matrix4.translationValues(
              0, selected || showPreview ? -12 : 0, 0),
          child: _CardWidget(
            card: cards[i],
            selected: selected,
            isHint: isHint,
            isPreview: showPreview,
          ),
        );
      },
      calculatePreview: _calculatePreview,
      onDragEnd: (selectedIndices) {
        onSelectionChanged?.call(selectedIndices);
      },
      onTap: enabled ? (index) => onCardTap(index) : null,
    );
  }

  Set<int> _calculatePreview(List<int> draggedIndices) {
    if (draggedIndices.isEmpty) return {};
    final draggedCards = draggedIndices.map((i) => cards[i]).toList();
    final hand = _validate(
      selectedCards: draggedCards,
      state: PdkGameState(
        players: const [],
        phase: PdkGamePhase.playing,
        isFirstPlay: false,
      ),
    );
    return hand != null ? draggedIndices.toSet() : {};
  }
}

class _CardWidget extends StatelessWidget {
  final PdkCard card;
  final bool selected;
  final bool isHint;
  final bool isPreview;

  const _CardWidget({
    required this.card,
    required this.selected,
    required this.isHint,
    required this.isPreview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final isRed = card.isRed;

    Color borderColor;
    List<BoxShadow>? shadow;
    List<Color> gradientColors;

    if (selected) {
      borderColor = colors.cardSelectedGlow.withValues(alpha: 0.8);
      shadow = [
        BoxShadow(
          color: colors.cardSelectedGlow.withValues(alpha: 0.3),
          blurRadius: 6,
        ),
      ];
      gradientColors = [
        colors.primaryGreen.withValues(alpha: 0.25),
        colors.cardBg1,
      ];
    } else if (isHint) {
      borderColor = colors.accentAmber.withValues(alpha: 0.9);
      shadow = [
        BoxShadow(
          color: colors.accentAmber.withValues(alpha: 0.4),
          blurRadius: 8,
        ),
      ];
      gradientColors = [
        colors.accentAmber.withValues(alpha: 0.15),
        colors.cardBg1,
      ];
    } else if (isPreview) {
      borderColor = colors.cardSelectedGlow.withValues(alpha: 0.5);
      shadow = [
        BoxShadow(
          color: colors.cardSelectedGlow.withValues(alpha: 0.2),
          blurRadius: 4,
        ),
      ];
      gradientColors = [
        colors.primaryGreen.withValues(alpha: 0.12),
        colors.cardBg1,
      ];
    } else {
      borderColor = isRed
          ? colors.cardBorderRed.withValues(alpha: 0.7)
          : colors.cardBorderBlack.withValues(alpha: 0.5);
      gradientColors = [colors.cardBg1, colors.cardBg2];
    }

    return Container(
      width: 44,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: selected || isHint ? 1.5 : 1,
        ),
        boxShadow: shadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.suitSymbol,
            style: TextStyle(
              color: isRed ? colors.cardBorderRed : colors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            card.rankDisplay,
            style: TextStyle(
              color: isRed ? colors.cardBorderRed : colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
