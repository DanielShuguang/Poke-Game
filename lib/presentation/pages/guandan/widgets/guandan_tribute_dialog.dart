import 'package:flutter/material.dart';
import 'package:poke_game/domain/guandan/entities/guandan_card.dart';
import 'package:poke_game/domain/guandan/entities/guandan_game_state.dart';
import 'package:poke_game/domain/guandan/entities/guandan_player.dart';
import 'package:poke_game/presentation/pages/guandan/widgets/guandan_hand_widget.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

/// 贡牌/还贡阶段覆盖弹窗
class GuandanTributeDialog extends StatefulWidget {
  final GuandanGameState state;
  final String localPlayerId;
  final void Function(GuandanCard card) onTribute;
  final void Function(GuandanCard card) onReturnTribute;

  const GuandanTributeDialog({
    super.key,
    required this.state,
    required this.localPlayerId,
    required this.onTribute,
    required this.onReturnTribute,
  });

  @override
  State<GuandanTributeDialog> createState() => _GuandanTributeDialogState();
}

class _GuandanTributeDialogState extends State<GuandanTributeDialog> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final ts = widget.state.tributeState;
    if (ts == null) return const SizedBox.shrink();

    final localPlayer = widget.state.getPlayerById(widget.localPlayerId);
    if (localPlayer == null) return const SizedBox.shrink();

    final isTributing =
        ts.pendingTributes.containsKey(widget.localPlayerId);
    final isReturning =
        ts.pendingReturnTributes.containsKey(widget.localPlayerId);

    if (!isTributing && !isReturning) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2838),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GameColors.dark.accentAmber.withAlpha(120)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTributing ? '请选择进贡（最大单张）' : '请选择还贡',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCardSelection(localPlayer, isTributing),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectedIndex != null ? _onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.dark.accentAmber,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 44),
                ),
                child: const Text('确认'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSelection(GuandanPlayer player, bool isTributing) {
    List<GuandanCard> selectable;

    if (isTributing) {
      // 进贡：只能选最大单张
      final nonJokers = player.cards
          .where((c) => !c.isJoker)
          .toList()
        ..sort((a, b) => b.rank!.compareTo(a.rank!));
      selectable = nonJokers.isEmpty ? player.cards : [nonJokers.first];
    } else {
      // 还贡：可以选任意手牌
      selectable = List.from(player.cards);
    }

    return GuandanHandWidget(
      cards: selectable,
      selectedIndices: _selectedIndex != null ? {_selectedIndex!} : {},
      cardWidth: 44,
      cardHeight: 66,
      onCardTap: (i) => setState(() => _selectedIndex = i),
    );
  }

  void _onConfirm() {
    final ts = widget.state.tributeState;
    if (ts == null || _selectedIndex == null) return;

    final localPlayer = widget.state.getPlayerById(widget.localPlayerId);
    if (localPlayer == null) return;

    final isTributing = ts.pendingTributes.containsKey(widget.localPlayerId);

    final nonJokers = localPlayer.cards
        .where((c) => !c.isJoker)
        .toList()
      ..sort((a, b) => b.rank!.compareTo(a.rank!));

    final selectable = isTributing
        ? (nonJokers.isEmpty ? localPlayer.cards : [nonJokers.first])
        : List<GuandanCard>.from(localPlayer.cards);

    if (_selectedIndex! >= selectable.length) return;
    final card = selectable[_selectedIndex!];

    if (isTributing) {
      widget.onTribute(card);
    } else {
      widget.onReturnTribute(card);
    }

    setState(() => _selectedIndex = null);
  }
}
