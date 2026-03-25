import 'package:flutter/material.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';
import 'package:poke_game/presentation/widgets/playing_card_widget.dart';

/// 玩家席位 Widget
/// 显示名称、筹码、当前投注额、底牌、位置标记（D/SB/BB）、倒计时
class PlayerSeatWidget extends StatelessWidget {
  final HoldemPlayer player;
  final bool isCurrentPlayer;
  final int dealerIndex;
  final int playerIndex;
  final int smallBlindIndex;
  final int bigBlindIndex;
  final bool showHoleCards;

  const PlayerSeatWidget({
    super.key,
    required this.player,
    required this.isCurrentPlayer,
    required this.dealerIndex,
    required this.playerIndex,
    required this.smallBlindIndex,
    required this.bigBlindIndex,
    this.showHoleCards = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: player.isFolded
            ? Colors.grey.shade800.withValues(alpha: 0.6)
            : isCurrentPlayer
                ? Colors.amber.shade700.withValues(alpha: 0.9)
                : Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlayer ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 位置标记行
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (playerIndex == dealerIndex) _Badge('D', Colors.grey),
              if (playerIndex == smallBlindIndex) _Badge('SB', Colors.blue),
              if (playerIndex == bigBlindIndex) _Badge('BB', Colors.orange),
            ],
          ),
          // 玩家名称
          Text(
            player.name,
            style: TextStyle(
              color: player.isFolded ? Colors.grey : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              decoration:
                  player.isFolded ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 4),
          // 筹码
          Text(
            '💰${player.chips}',
            style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
          ),
          // 当前投注
          if (player.currentBet > 0)
            Text(
              '下注：${player.currentBet}',
              style: const TextStyle(color: Colors.amber, fontSize: 11),
            ),
          if (player.isAllIn)
            const Text(
              'ALL IN',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 4),
          // 底牌
          _HoleCards(
            player: player,
            showCards: showHoleCards,
          ),
          // 倒计时进度条（当前行动玩家）
          if (isCurrentPlayer)
            const _CountdownBar(),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _HoleCards extends StatelessWidget {
  final HoldemPlayer player;
  final bool showCards;
  const _HoleCards({required this.player, required this.showCards});

  @override
  Widget build(BuildContext context) {
    if (player.holeCards.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: player.holeCards.map((card) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: CardWidget(
            card: card,
            faceUp: showCards && !player.isFolded,
            width: 44,
            height: 62,
          ),
        );
      }).toList(),
    );
  }
}

/// 30秒倒计时进度条
class _CountdownBar extends StatefulWidget {
  const _CountdownBar();

  @override
  State<_CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<_CountdownBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final remaining = 1 - _ctrl.value;
        return SizedBox(
          width: 80,
          height: 4,
          child: LinearProgressIndicator(
            value: remaining,
            backgroundColor: Colors.grey.shade700,
            valueColor: AlwaysStoppedAnimation<Color>(
              remaining > 0.3 ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        );
      },
    );
  }
}
