import 'package:flutter/material.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';
import 'zhj_hand_widget.dart';

/// 单个玩家区域（显示头像、筹码、状态标签、手牌）
class ZhjPlayerWidget extends StatelessWidget {
  final ZhjPlayer player;
  final bool isCurrentTurn;
  final bool showFaceUp; // 结算时强制正面

  const ZhjPlayerWidget({
    super.key,
    required this.player,
    this.isCurrentTurn = false,
    this.showFaceUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: player.isFolded
            ? Colors.grey.shade800.withValues(alpha: 0.6)
            : Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn ? Colors.amber : Colors.white24,
          width: isCurrentTurn ? 2.5 : 1,
        ),
        boxShadow: isCurrentTurn
            ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 12)]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 玩家名称 + 状态标签
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.name,
                style: TextStyle(
                  color: player.isFolded ? Colors.grey : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: 6),
          // 手牌
          ZhjHandWidget(
            cards: player.cards,
            hasPeeked: player.hasPeeked,
            isFolded: player.isFolded,
            isCurrentPlayer: isCurrentTurn,
            showFaceUp: showFaceUp || player.isFolded,
          ),
          const SizedBox(height: 6),
          // 筹码
          Text(
            '💰 ${player.chips}',
            style: const TextStyle(color: Colors.amber, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    if (player.isFolded) {
      return _badge('弃牌', Colors.red.shade700);
    }
    if (!player.hasPeeked) {
      return _badge('蒙牌', Colors.blue.shade700.withValues(alpha: 0.8));
    }
    return const SizedBox.shrink();
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }
}
