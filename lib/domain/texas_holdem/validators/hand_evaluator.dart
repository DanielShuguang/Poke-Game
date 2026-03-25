import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 手牌等级（从小到大）
enum HandRank {
  /// 高牌
  highCard,

  /// 一对
  onePair,

  /// 两对
  twoPair,

  /// 三条
  threeOfAKind,

  /// 顺子
  straight,

  /// 同花
  flush,

  /// 葫芦（三带一对）
  fullHouse,

  /// 四条
  fourOfAKind,

  /// 同花顺
  straightFlush,

  /// 皇家同花顺
  royalFlush,
}

/// 手牌评估结果
class HandResult implements Comparable<HandResult> {
  final HandRank handRank;

  /// 整数评分（高位牌型等级，低位点数序列），可直接比较
  final int score;

  /// 最优5张牌
  final List<Card> bestFive;

  const HandResult({
    required this.handRank,
    required this.score,
    required this.bestFive,
  });

  @override
  int compareTo(HandResult other) => score.compareTo(other.score);

  @override
  String toString() => 'HandResult(${handRank.name}, score=$score)';
}

/// 德州扑克牌型评估引擎
/// 从7张牌中枚举 C(7,5)=21 种5张组合，返回最优牌型
class HandEvaluator {
  // 牌型等级基础分：每个 rank 用 4 位编码，5张牌 = 20位，_rankBase 须 > 2^20
  static const int _rankBase = 1 << 20; // 1,048,576

  /// 评估7张（或少于7张）牌中的最优5张
  static HandResult evaluate(List<Card> cards) {
    assert(cards.length >= 5 && cards.length <= 7,
        'Must provide 5-7 cards, got ${cards.length}');

    final combinations = _getCombinations(cards, 5);
    HandResult? best;
    for (final combo in combinations) {
      final result = _evaluateFive(combo);
      if (best == null || result.score > best.score) {
        best = result;
      }
    }
    return best!;
  }

  /// 生成 C(n,5) 所有5张组合
  static List<List<Card>> _getCombinations(List<Card> cards, int r) {
    final result = <List<Card>>[];
    _combine(cards, r, 0, [], result);
    return result;
  }

  static void _combine(
    List<Card> cards,
    int r,
    int start,
    List<Card> current,
    List<List<Card>> result,
  ) {
    if (current.length == r) {
      result.add(List.of(current));
      return;
    }
    for (var i = start; i < cards.length; i++) {
      current.add(cards[i]);
      _combine(cards, r, i + 1, current, result);
      current.removeLast();
    }
  }

  /// 评估精确5张牌
  static HandResult _evaluateFive(List<Card> cards) {
    final ranks = cards.map((c) => c.rank).toList()..sort((a, b) => b.compareTo(a));
    final suits = cards.map((c) => c.suit).toSet();
    final isFlush = suits.length == 1;
    final isStraight = _isStraight(ranks);
    final isWheelStraight = _isWheelStraight(ranks);

    if (isFlush && isStraight) {
      final rankScore = _rankScore(ranks);
      if (ranks[0] == 14) {
        return HandResult(
          handRank: HandRank.royalFlush,
          score: HandRank.royalFlush.index * _rankBase + rankScore,
          bestFive: cards,
        );
      }
      return HandResult(
        handRank: HandRank.straightFlush,
        score: HandRank.straightFlush.index * _rankBase + rankScore,
        bestFive: cards,
      );
    }

    if (isFlush && isWheelStraight) {
      // A-2-3-4-5 同花顺（A低）
      final wheelRanks = [5, 4, 3, 2, 1];
      return HandResult(
        handRank: HandRank.straightFlush,
        score: HandRank.straightFlush.index * _rankBase + _rankScore(wheelRanks),
        bestFive: cards,
      );
    }

    final groups = _groupByRank(ranks);
    final groupSizes = groups.values.toList()..sort((a, b) => b.compareTo(a));

    if (groupSizes[0] == 4) {
      return HandResult(
        handRank: HandRank.fourOfAKind,
        score: HandRank.fourOfAKind.index * _rankBase + _groupScore(groups, [4, 1]),
        bestFive: cards,
      );
    }

    if (groupSizes[0] == 3 && groupSizes[1] == 2) {
      return HandResult(
        handRank: HandRank.fullHouse,
        score: HandRank.fullHouse.index * _rankBase + _groupScore(groups, [3, 2]),
        bestFive: cards,
      );
    }

    if (isFlush) {
      return HandResult(
        handRank: HandRank.flush,
        score: HandRank.flush.index * _rankBase + _rankScore(ranks),
        bestFive: cards,
      );
    }

    if (isStraight) {
      return HandResult(
        handRank: HandRank.straight,
        score: HandRank.straight.index * _rankBase + _rankScore(ranks),
        bestFive: cards,
      );
    }

    if (isWheelStraight) {
      final wheelRanks = [5, 4, 3, 2, 1];
      return HandResult(
        handRank: HandRank.straight,
        score: HandRank.straight.index * _rankBase + _rankScore(wheelRanks),
        bestFive: cards,
      );
    }

    if (groupSizes[0] == 3) {
      return HandResult(
        handRank: HandRank.threeOfAKind,
        score: HandRank.threeOfAKind.index * _rankBase + _groupScore(groups, [3, 1, 1]),
        bestFive: cards,
      );
    }

    if (groupSizes[0] == 2 && groupSizes[1] == 2) {
      return HandResult(
        handRank: HandRank.twoPair,
        score: HandRank.twoPair.index * _rankBase + _groupScore(groups, [2, 2, 1]),
        bestFive: cards,
      );
    }

    if (groupSizes[0] == 2) {
      return HandResult(
        handRank: HandRank.onePair,
        score: HandRank.onePair.index * _rankBase + _groupScore(groups, [2, 1, 1, 1]),
        bestFive: cards,
      );
    }

    return HandResult(
      handRank: HandRank.highCard,
      score: HandRank.highCard.index * _rankBase + _rankScore(ranks),
      bestFive: cards,
    );
  }

  /// 判断是否为普通顺子（已降序排列）
  static bool _isStraight(List<int> sortedRanks) {
    for (var i = 0; i < sortedRanks.length - 1; i++) {
      if (sortedRanks[i] - sortedRanks[i + 1] != 1) return false;
    }
    return true;
  }

  /// 判断是否为 A-2-3-4-5 低顺（Wheel）
  static bool _isWheelStraight(List<int> sortedRanks) {
    // sortedRanks 降序，A 在最高位为 14
    return sortedRanks[0] == 14 &&
        sortedRanks[1] == 5 &&
        sortedRanks[2] == 4 &&
        sortedRanks[3] == 3 &&
        sortedRanks[4] == 2;
  }

  /// 按点数分组，返回 {rank: count}
  static Map<int, int> _groupByRank(List<int> ranks) {
    final map = <int, int>{};
    for (final r in ranks) {
      map[r] = (map[r] ?? 0) + 1;
    }
    return map;
  }

  /// 将降序点数列表编码为整数（每位点数占4 bit）
  static int _rankScore(List<int> sortedRanks) {
    var score = 0;
    for (final r in sortedRanks) {
      score = (score << 4) | (r & 0xF);
    }
    return score;
  }

  /// 按组大小优先级编码（先对子再踢脚牌），使用4位编码
  static int _groupScore(Map<int, int> groups, List<int> prioritySizes) {
    final sorted = groups.entries.toList()
      ..sort((a, b) {
        final sizeCmp = b.value.compareTo(a.value);
        if (sizeCmp != 0) return sizeCmp;
        return b.key.compareTo(a.key);
      });

    var score = 0;
    for (final entry in sorted) {
      score = (score << 4) | (entry.key & 0xF);
    }
    return score;
  }
}
