import 'package:poke_game/domain/zhajinhua/entities/zhj_card.dart';

/// 炸金花牌型等级（值越大越强）
enum HandRank {
  highCard,      // 散牌
  pair,          // 对子
  straight,      // 顺子
  flush,         // 同花
  straightFlush, // 同花顺
  threeOfAKind,  // 豹子
}

/// 牌型评估结果
class HandEvaluation {
  final HandRank rank;

  /// 比较值列表（从高到低），用于同牌型比较大小
  final List<int> tiebreakers;

  const HandEvaluation({required this.rank, required this.tiebreakers});
}

/// 炸金花牌型验证器（纯函数，无副作用）
class ZhjCardValidator {
  ZhjCardValidator._();

  /// 评估3张牌的牌型
  static HandEvaluation evaluate(List<ZhjCard> cards) {
    assert(cards.length == 3, 'ZhjCardValidator: must have exactly 3 cards');

    final sorted = [...cards]..sort((a, b) => b.rank.compareTo(a.rank)); // 降序
    final ranks = sorted.map((c) => c.rank).toList();
    final suits = cards.map((c) => c.suit).toSet();

    final isFlush = suits.length == 1;
    final isStraight = _isStraight(ranks);

    // 豹子
    if (ranks[0] == ranks[1] && ranks[1] == ranks[2]) {
      return HandEvaluation(rank: HandRank.threeOfAKind, tiebreakers: [ranks[0]]);
    }

    // 同花顺
    if (isFlush && isStraight) {
      return HandEvaluation(
        rank: HandRank.straightFlush,
        tiebreakers: [_straightHighCard(ranks)],
      );
    }

    // 同花
    if (isFlush) {
      return HandEvaluation(rank: HandRank.flush, tiebreakers: ranks);
    }

    // 顺子
    if (isStraight) {
      return HandEvaluation(
        rank: HandRank.straight,
        tiebreakers: [_straightHighCard(ranks)],
      );
    }

    // 对子
    if (ranks[0] == ranks[1] || ranks[1] == ranks[2]) {
      final pairRank = (ranks[0] == ranks[1]) ? ranks[0] : ranks[1];
      final kicker = ranks.firstWhere((r) => r != pairRank);
      return HandEvaluation(rank: HandRank.pair, tiebreakers: [pairRank, kicker]);
    }

    // 散牌
    return HandEvaluation(rank: HandRank.highCard, tiebreakers: ranks);
  }

  /// 比较两手牌：a > b 返回 1，a < b 返回 -1，相等返回 0
  static int compare(List<ZhjCard> a, List<ZhjCard> b) {
    final evalA = evaluate(a);
    final evalB = evaluate(b);

    final rankCmp = evalA.rank.index.compareTo(evalB.rank.index);
    if (rankCmp != 0) return rankCmp;

    // 同牌型比 tiebreakers
    for (int i = 0; i < evalA.tiebreakers.length; i++) {
      final cmp = evalA.tiebreakers[i].compareTo(evalB.tiebreakers[i]);
      if (cmp != 0) return cmp;
    }
    return 0;
  }

  /// 判断是否是顺子（含 A-2-3 特例）
  static bool _isStraight(List<int> sortedDesc) {
    final high = sortedDesc[0];
    final mid = sortedDesc[1];
    final low = sortedDesc[2];

    // 普通顺子：三张连续
    if (high - mid == 1 && mid - low == 1) return true;

    // A-2-3 特例：rank 14（A）、3、2 = [14, 3, 2] 降序
    if (high == 14 && mid == 3 && low == 2) return true;

    return false;
  }

  /// 顺子的最大牌（用于比较），A-2-3 中最大牌视为 3
  static int _straightHighCard(List<int> sortedDesc) {
    // A-2-3 特例，A 不作为 14 参与比较
    if (sortedDesc[0] == 14 && sortedDesc[1] == 3 && sortedDesc[2] == 2) {
      return 3;
    }
    return sortedDesc[0];
  }
}
