import 'package:flutter/material.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_player.dart';

/// 玩家座位组件
class PlayerSeat extends StatelessWidget {
  final ShengjiPlayer player;
  final bool isCurrentPlayer;
  final bool isTeammate;
  final List<ShengjiCard>? playedCards;

  const PlayerSeat({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
    this.isTeammate = false,
    this.playedCards,
  });

  @override
  Widget build(BuildContext context) {
    // 根据座位索引确定位置
    final position = _getPosition(player.seatIndex, context);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 玩家信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(8),
              border: isCurrentPlayer
                  ? Border.all(color: Colors.yellow, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isTeammate)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '队友',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                if (player.isAi)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 手牌数量（非本地玩家显示背面）
          if (!player.isAi || player.hand.isNotEmpty)
            Text(
              '${player.hand.length} 张',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isTeammate) return Colors.blue.shade700;
    return Colors.black38;
  }

  Offset _getPosition(int seatIndex, BuildContext context) {
    final size = MediaQuery.of(context).size;

    switch (seatIndex) {
      case 0: // 底部（自己）- 放在底部手牌区上方
        return Offset(size.width / 2 - 60, size.height - 200);
      case 1: // 右侧
        return Offset(size.width - 130, size.height / 2 - 40);
      case 2: // 顶部（对家）
        return Offset(size.width / 2 - 60, 55);
      case 3: // 左侧
        return Offset(20, size.height / 2 - 40);
      default:
        return Offset.zero;
    }
  }
}
