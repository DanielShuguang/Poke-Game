import 'package:poke_game/domain/niuniu/entities/niuniu_card.dart';

/// 斗牛牌型等级（从低到高）
enum NiuniuRank {
  noPoints, // 无牛
  niu1,
  niu2,
  niu3,
  niu4,
  niu5,
  niu6,
  niu7,
  niu8,
  niu9,
  niuNiu, // 牛牛
  fiveSmall, // 五小牛
  bomb, // 炸弹（4张同点）
}

extension NiuniuRankX on NiuniuRank {
  String get displayName {
    switch (this) {
      case NiuniuRank.noPoints:
        return '无牛';
      case NiuniuRank.niu1:
        return '牛一';
      case NiuniuRank.niu2:
        return '牛二';
      case NiuniuRank.niu3:
        return '牛三';
      case NiuniuRank.niu4:
        return '牛四';
      case NiuniuRank.niu5:
        return '牛五';
      case NiuniuRank.niu6:
        return '牛六';
      case NiuniuRank.niu7:
        return '牛七';
      case NiuniuRank.niu8:
        return '牛八';
      case NiuniuRank.niu9:
        return '牛九';
      case NiuniuRank.niuNiu:
        return '牛牛';
      case NiuniuRank.fiveSmall:
        return '五小牛';
      case NiuniuRank.bomb:
        return '炸弹';
    }
  }

  /// 倍率：无牛/牛1-6=×1，牛7-9=×2，牛牛=×3，五小牛/炸弹=×5
  int get multiplier {
    switch (this) {
      case NiuniuRank.noPoints:
      case NiuniuRank.niu1:
      case NiuniuRank.niu2:
      case NiuniuRank.niu3:
      case NiuniuRank.niu4:
      case NiuniuRank.niu5:
      case NiuniuRank.niu6:
        return 1;
      case NiuniuRank.niu7:
      case NiuniuRank.niu8:
      case NiuniuRank.niu9:
        return 2;
      case NiuniuRank.niuNiu:
        return 3;
      case NiuniuRank.fiveSmall:
      case NiuniuRank.bomb:
        return 5;
    }
  }
}

/// 斗牛手牌（持有 5 张牌）
class NiuniuHand {
  final List<NiuniuCard> cards;

  const NiuniuHand({required this.cards});

  /// 计算牌型等级
  /// 优先级：炸弹 > 五小牛 > 牛牛 > 牛1~9 > 无牛
  NiuniuRank get rank {
    if (cards.length != 5) return NiuniuRank.noPoints;

    // 炸弹：4张同点数
    if (_hasBomb()) return NiuniuRank.bomb;

    // 五小牛：5张全部 ≤5 且点值之和 ≤10
    if (_isFiveSmall()) return NiuniuRank.fiveSmall;

    // 枚举 C(5,3) 找牛
    final niuValue = _findNiuValue();
    if (niuValue == null) return NiuniuRank.noPoints;
    if (niuValue == 0) return NiuniuRank.niuNiu;

    return NiuniuRank.values[niuValue]; // niu1~niu9
  }

  int get multiplier => rank.multiplier;

  /// 比较两手牌大小（返回正数=this更大，负数=other更大，0=相等）
  int compareTo(NiuniuHand other) {
    final rankCmp = rank.index.compareTo(other.rank.index);
    if (rankCmp != 0) return rankCmp;
    // 同牌型：比最大单张点值（K > Q > J > 10 > ... > A）
    return _maxPointValue().compareTo(other._maxPointValue());
  }

  // ── 私有帮助方法 ──────────────────────────────────────────────────────────

  bool _hasBomb() {
    final pointCounts = <int, int>{};
    for (final c in cards) {
      pointCounts[c.pointValue] = (pointCounts[c.pointValue] ?? 0) + 1;
    }
    return pointCounts.values.any((count) => count >= 4);
  }

  bool _isFiveSmall() {
    if (cards.any((c) => c.rank > 5)) return false;
    final total = cards.fold(0, (sum, c) => sum + c.pointValue);
    return total <= 10;
  }

  /// 枚举 C(5,3) 找到使余2张之和 mod 10 == 0 的组合
  /// 返回余2张之和 mod 10（0=牛牛，1-9=牛X），null=无牛
  int? _findNiuValue() {
    final indices = [0, 1, 2, 3, 4];
    for (int i = 0; i < 3; i++) {
      for (int j = i + 1; j < 4; j++) {
        for (int k = j + 1; k < 5; k++) {
          final threeSum =
              cards[i].pointValue + cards[j].pointValue + cards[k].pointValue;
          if (threeSum % 10 == 0) {
            final remaining = indices
                .where((idx) => idx != i && idx != j && idx != k)
                .toList();
            final twoSum =
                cards[remaining[0]].pointValue + cards[remaining[1]].pointValue;
            return twoSum % 10;
          }
        }
      }
    }
    return null;
  }

  int _maxPointValue() {
    return cards.fold(0, (max, c) => c.pointValue > max ? c.pointValue : max);
  }

  List<Map<String, dynamic>> toJson() => cards.map((c) => c.toJson()).toList();

  static NiuniuHand fromJson(List<dynamic> json) {
    return NiuniuHand(
      cards: json
          .cast<Map<String, dynamic>>()
          .map(NiuniuCard.fromJson)
          .toList(),
    );
  }
}
