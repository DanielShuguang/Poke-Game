import 'package:flutter/material.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_card.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

/// 炸金花手牌组件（3张牌，支持蒙牌/翻牌动画）
class ZhjHandWidget extends StatefulWidget {
  final List<ZhjCard> cards;
  final bool hasPeeked;
  final bool isFolded;
  final bool isCurrentPlayer;
  final bool showFaceUp; // 结算时强制正面显示

  const ZhjHandWidget({
    super.key,
    required this.cards,
    required this.hasPeeked,
    this.isFolded = false,
    this.isCurrentPlayer = false,
    this.showFaceUp = false,
  });

  @override
  State<ZhjHandWidget> createState() => _ZhjHandWidgetState();
}

class _ZhjHandWidgetState extends State<ZhjHandWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnim;
  bool _prevPeeked = false;

  @override
  void initState() {
    super.initState();
    _prevPeeked = widget.hasPeeked;
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    if (widget.hasPeeked || widget.showFaceUp) _flipController.value = 1.0;
  }

  @override
  void didUpdateWidget(ZhjHandWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_prevPeeked && (widget.hasPeeked || widget.showFaceUp)) {
      _flipController.forward();
      _prevPeeked = true;
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faceUp = widget.hasPeeked || widget.showFaceUp;
    return Opacity(
      opacity: widget.isFolded ? 0.4 : 1.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            AnimatedBuilder(
              animation: _flipAnim,
              builder: (_, __) => _buildCard(
                context,
                i < widget.cards.length ? widget.cards[i] : null,
                faceUp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, ZhjCard? card, bool faceUp) {
    const w = 48.0;
    const h = 68.0;
    final colors = context.gameColors;

    if (!faceUp || card == null) {
      return _cardBack(context, w, h);
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.cardBg1, colors.cardBg2],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: card.isRed ? colors.cardBorderRed : colors.cardBorderBlack),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.suitSymbol,
            style: TextStyle(
              fontSize: 16,
              color: card.isRed ? colors.cardBorderRed : colors.textPrimary,
            ),
          ),
          Text(
            card.displayText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: card.isRed ? colors.cardBorderRed : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBack(BuildContext context, double w, double h) {
    final colors = context.gameColors;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: colors.cardBackBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colors.cardBorderBlack.withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2))
        ],
      ),
      child: Center(
        child: Text(
          '🂠',
          style: TextStyle(fontSize: 28, color: colors.cardBorderBlack),
        ),
      ),
    );
  }
}
