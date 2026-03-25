import 'package:flutter/material.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as poker;
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';

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
        return const _CardBack();
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
          child: isFlipped
              ? _CardFace(card: widget.card)
              : const _CardBack(),
        );
      },
    );
  }
}

/// 牌面
class _CardFace extends StatelessWidget {
  final poker.Card card;
  const _CardFace({required this.card});

  @override
  Widget build(BuildContext context) {
    final isRed = card.isRed;
    return _CardContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.suitSymbol,
            style: const TextStyle(fontSize: 20),
          ),
          Text(
            card.displayText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isRed ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// 牌背
class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Text('🂠', style: TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 64,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
