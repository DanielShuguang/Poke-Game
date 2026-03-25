import 'package:flutter/material.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as poker;
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';
import 'package:poke_game/presentation/widgets/playing_card_widget.dart';

/// 公牌区 Widget
/// 展示5个卡牌位，未翻出时显示牌背，翻出时带翻转动画
class CommunityCardsWidget extends StatelessWidget {
  final List<poker.Card> communityCards;
  final GamePhase phase;

  const CommunityCardsWidget({
    super.key,
    required this.communityCards,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < communityCards.length) {
          return _FlippableCard(card: communityCards[i]);
        }
        return const _CardBackSlot();
      }),
    );
  }
}

/// 翻转卡牌（有动画）
class _FlippableCard extends StatefulWidget {
  final poker.Card card;
  const _FlippableCard({required this.card});

  @override
  State<_FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<_FlippableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final isFlipped = _anim.value > 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(
              isFlipped ? 0 : (1 - _anim.value * 2) * 3.14159 / 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: isFlipped
                ? CardWidget(card: widget.card, width: 64, height: 90)
                : const _CardBackSlot(),
          ),
        );
      },
    );
  }
}

/// 牌背占位（未翻出的公牌）
class _CardBackSlot extends StatelessWidget {
  const _CardBackSlot();

  // 占位用虚拟牌，只显示牌背
  static const _dummy = poker.Card(suit: poker.Suit.spade, rank: 14);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CardWidget(
        card: _dummy,
        faceUp: false,
        width: 64,
        height: 90,
      ),
    );
  }
}
