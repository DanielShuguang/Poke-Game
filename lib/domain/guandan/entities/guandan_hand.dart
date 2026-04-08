import 'guandan_card.dart';
import 'guandan_hand_type.dart';

/// 一手出牌
class GuandanHand {
  final List<GuandanCard> cards;
  final HandType type;

  /// 牌型的"代表点数"，用于同类型比较
  /// - single/pair/triple/triplePair/bomb/straightFlushBomb：主牌点数（含大小王特殊值）
  /// - straight/consecutivePairs/steelPlate：最高点数
  /// - kingBomb：固定最大值（不参与比较，天王炸无法被压制）
  final int rank;

  /// 张数（炸弹比较时同类型先比张数）
  int get count => cards.length;

  const GuandanHand({
    required this.cards,
    required this.type,
    required this.rank,
  });

  // ────────────────────────────────────────────────────────────────
  // 炸弹优先级辅助
  // ────────────────────────────────────────────────────────────────

  bool get isBomb =>
      type == HandType.bomb ||
      type == HandType.straightFlushBomb ||
      type == HandType.kingBomb;

  /// 炸弹优先级数值（越大越强）
  /// 天王炸=4, 同花顺炸=3, 级牌炸=2, 普通炸=1
  int bombPriority(int currentLevel) {
    if (type == HandType.kingBomb) return 4;
    if (type == HandType.straightFlushBomb) return 3;
    if (type == HandType.bomb &&
        cards.every((c) => !c.isJoker && c.rank == currentLevel)) {
      return 2; // 级牌炸
    }
    if (type == HandType.bomb) return 1;
    return 0; // 非炸弹
  }

  // ────────────────────────────────────────────────────────────────
  // 比较
  // ────────────────────────────────────────────────────────────────

  /// 是否能压制 [other]（this > other）
  /// 只有相同牌型或炸弹才能压制
  bool beats(GuandanHand other, int currentLevel) {
    // 天王炸压制一切
    if (type == HandType.kingBomb) return true;

    // 炸弹压制非炸弹
    if (isBomb && !other.isBomb) return true;
    if (!isBomb && other.isBomb) return false;

    // 双方都是炸弹
    if (isBomb && other.isBomb) {
      return _compareBombs(other, currentLevel) > 0;
    }

    // 非炸弹：必须牌型相同且张数相同
    if (type != other.type) return false;
    if (count != other.count) return false;

    return rank > other.rank;
  }

  int _compareBombs(GuandanHand other, int currentLevel) {
    final myPriority = bombPriority(currentLevel);
    final otherPriority = other.bombPriority(currentLevel);

    if (myPriority != otherPriority) {
      return myPriority.compareTo(otherPriority);
    }

    // 同优先级：张数多的更大
    if (count != other.count) return count.compareTo(other.count);

    // 同张数同类型：rank 比较（普通炸弹按点数）
    return rank.compareTo(other.rank);
  }

  // ────────────────────────────────────────────────────────────────
  // 序列化
  // ────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'cards': cards.map((c) => c.toId()).toList(),
        'type': type.name,
        'rank': rank,
      };

  static GuandanHand fromJson(Map<String, dynamic> json) => GuandanHand(
        cards: (json['cards'] as List<dynamic>)
            .map((id) => GuandanCard.fromId(id as String))
            .toList(),
        type: HandType.values.firstWhere(
          (e) => e.name == json['type'],
        ),
        rank: json['rank'] as int,
      );

  @override
  String toString() => 'GuandanHand($type, rank=$rank, cards=$cards)';
}
