import 'package:flutter/material.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_card.dart';

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

    if (!faceUp || card == null) {
      return _cardBack(w, h);
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.suitSymbol,
            style: TextStyle(
              fontSize: 16,
              color: card.isRed ? Colors.red : Colors.black87,
            ),
          ),
          Text(
            card.displayText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: card.isRed ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBack(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade800),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2))],
      ),
      child: const Center(
        child: Text('🂠', style: TextStyle(fontSize: 28, color: Colors.white70)),
      ),
    );
  }
}
