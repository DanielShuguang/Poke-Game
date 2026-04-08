import '../entities/guandan_card.dart';
import '../entities/guandan_hand.dart';
import '../entities/guandan_hand_type.dart';

/// 掼蛋手牌合法性验证
///
/// 使用方式：
/// ```dart
/// final result = ValidateHandUsecase.validate(cards, level: 2);
/// if (result != null) { /* 合法牌型 */ }
/// ```
class ValidateHandUsecase {
  const ValidateHandUsecase._();

  /// 验证 [cards] 是否构成合法牌型（当前轮级为 [level]，2-14）。
  /// 返回 [GuandanHand]（含牌型和代表点数），非法返回 null。
  static GuandanHand? validate(List<GuandanCard> cards, int level) {
    if (cards.isEmpty) return null;

    final n = cards.length;

    // 天王炸：恰好两张大王
    if (n == 2 &&
        cards.every((c) => c.isBigJoker)) {
      return GuandanHand(cards: cards, type: HandType.kingBomb, rank: 9999);
    }

    // 炸弹类（4张及以上同点数）
    final bombResult = _tryBomb(cards, level);
    if (bombResult != null) return bombResult;

    // 同花顺炸弹（5张及以上同花色连续）
    final sfResult = _tryStraightFlushBomb(cards, level);
    if (sfResult != null) return sfResult;

    // 单张
    if (n == 1) {
      return GuandanHand(
        cards: cards,
        type: HandType.single,
        rank: _cardRank(cards[0]),
      );
    }

    // 对子
    if (n == 2) {
      return _tryPair(cards, level);
    }

    // 三张
    if (n == 3) {
      return _tryTriple(cards, level);
    }

    // 三带二（5张）
    if (n == 5) {
      final tp = _tryTriplePair(cards, level);
      if (tp != null) return tp;
    }

    // 顺子（5张及以上，含级牌百搭）
    if (n >= 5) {
      final st = _tryStraight(cards, level);
      if (st != null) return st;
    }

    // 连对（6张及以上偶数张）
    if (n >= 6 && n % 2 == 0) {
      final cp = _tryConsecutivePairs(cards, level);
      if (cp != null) return cp;
    }

    // 钢板（6张及以上，且 3 的倍数）
    if (n >= 6 && n % 3 == 0) {
      final sp = _trySteelPlate(cards, level);
      if (sp != null) return sp;
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────────
  // 单一牌型检测
  // ──────────────────────────────────────────────────────────────

  static GuandanHand? _tryPair(List<GuandanCard> cards, int level) {
    if (cards.length != 2) return null;
    final ranks = _nonWildRanks(cards, level);
    final wilds = _wildCount(cards, level);

    // 两张大王 → 天王炸（已在上层处理）
    // 小王对子（两张小王）
    if (cards.every((c) => c.isSmallJoker)) {
      return GuandanHand(cards: cards, type: HandType.pair, rank: 998);
    }
    // 一野一正
    if (wilds == 1 && ranks.length == 1 && !ranks.first.isJoker) {
      return GuandanHand(
          cards: cards, type: HandType.pair, rank: ranks.first.rank!);
    }
    // 两张同点数
    if (wilds == 0 &&
        ranks.length == 2 &&
        !ranks[0].isJoker &&
        ranks[0].rank == ranks[1].rank) {
      return GuandanHand(
          cards: cards, type: HandType.pair, rank: ranks[0].rank!);
    }
    return null;
  }

  static GuandanHand? _tryTriple(List<GuandanCard> cards, int level) {
    if (cards.length != 3) return null;
    final ranks = _nonWildRanks(cards, level);
    final wilds = _wildCount(cards, level);

    if (ranks.any((c) => c.isJoker)) return null;
    final uniqueRanks = ranks.map((c) => c.rank!).toSet();
    if (uniqueRanks.length == 1 && wilds == 0) {
      return GuandanHand(
          cards: cards, type: HandType.triple, rank: uniqueRanks.first);
    }
    if (uniqueRanks.length == 1 && wilds + ranks.length == 3) {
      return GuandanHand(
          cards: cards, type: HandType.triple, rank: uniqueRanks.first);
    }
    if (uniqueRanks.isEmpty && wilds == 3) {
      // 全是级牌，不能构成三张（级牌炸单独处理）
      return null;
    }
    return null;
  }

  static GuandanHand? _tryTriplePair(List<GuandanCard> cards, int level) {
    if (cards.length != 5) return null;
    // 枚举所有可能的三张+对子拆分
    for (int tripleRank in _possibleGroupRanks(cards, 3, level)) {
      final tripleCards = _extractGroup(cards, tripleRank, 3, level);
      if (tripleCards == null) continue;
      final remaining = _removeCards(cards, tripleCards);
      if (_tryPair(remaining, level) != null) {
        return GuandanHand(
            cards: cards, type: HandType.triplePair, rank: tripleRank);
      }
    }
    return null;
  }

  static GuandanHand? _tryBomb(List<GuandanCard> cards, int level) {
    final n = cards.length;
    if (n < 4) return null;

    // 大小王不参与普通炸弹
    if (cards.any((c) => c.isJoker)) return null;

    // 所有牌必须同点数（级牌炸也如此：4张level同点数）
    final uniqueRanks = cards.map((c) => c.rank!).toSet();
    if (uniqueRanks.length != 1) return null;

    final rank = uniqueRanks.first;
    return GuandanHand(cards: cards, type: HandType.bomb, rank: rank);
  }

  static GuandanHand? _tryStraightFlushBomb(
      List<GuandanCard> cards, int level) {
    final n = cards.length;
    if (n < 5) return null;
    if (cards.any((c) => c.isJoker)) return null;

    // 所有牌必须同花色
    final suits = cards.map((c) => c.suit!).toSet();
    if (suits.length != 1) return null;

    // 检查是否连续（不允许用级牌百搭填补同花顺炸弹缺口）
    final ranks = cards.map((c) => c.rank!).toList()..sort();
    for (int i = 1; i < ranks.length; i++) {
      if (ranks[i] != ranks[i - 1] + 1) return null;
    }
    // A(14) 不可作为同花顺炸弹高端延伸起点
    if (ranks.last == 14 && ranks.length > 1 && ranks[ranks.length - 2] != 13) {
      return null;
    }

    return GuandanHand(
        cards: cards, type: HandType.straightFlushBomb, rank: ranks.last);
  }

  // ──────────────────────────────────────────────────────────────
  // 顺子（含级牌百搭嵌入）
  // ──────────────────────────────────────────────────────────────

  /// 验证顺子合法性：
  /// 1. 排除大小王（王不参与顺子）
  /// 2. 提取非级牌，排序后检测缺口
  /// 3. 用级牌（isWild）逐个填补缺口
  /// 4. 缺口数 <= 可用级牌数，且级牌不充当两端延伸
  static GuandanHand? _tryStraight(List<GuandanCard> cards, int level) {
    if (cards.length < 5) return null;
    if (cards.any((c) => c.isJoker)) return null;

    final wildCards =
        cards.where((c) => _isWild(c, level)).toList();
    final normalCards =
        cards.where((c) => !_isWild(c, level)).toList();

    if (normalCards.isEmpty) return null;

    // 正常牌中不应有重复点数（顺子每个点数只能一张）
    final normalRanks = normalCards.map((c) => c.rank!).toList()..sort();
    if (normalRanks.toSet().length != normalRanks.length) return null;

    // A(14) 不可作为顺子延伸端（A 只能是顺子的结尾最大牌，但不可以 A 开头延伸）
    // 规则：A 不参与顺子（掼蛋标准规则：2-K 可组成顺子，A 不在顺子范围内）
    if (normalRanks.contains(14)) return null;

    final minRank = normalRanks.first;
    final maxRank = normalRanks.last;

    // 期望的连续范围（用正常牌确定两端）
    // 用 wildCards 填补中间缺口
    final expectedLength = maxRank - minRank + 1;

    // 缺口 = 期望长度 - 正常牌数量
    final gaps = expectedLength - normalRanks.length;

    if (gaps < 0) return null; // 有重复，不合法（已经过滤）
    if (gaps > wildCards.length) return null; // 级牌不足填补缺口

    // 校验：顺子总长必须等于 cards.length
    if (normalCards.length + wildCards.length != cards.length) return null;

    // 总长度检验：正常牌数 + 级牌数 = expectedLength + (wildCards.length - gaps)
    // 即：cards.length = expectedLength + 剩余野牌
    // 顺子不允许有多余野牌（野牌必须全用于填补缺口）
    final totalLength = maxRank - minRank + 1 + (wildCards.length - gaps);
    if (cards.length != totalLength) return null;

    // 禁止级牌作为两端延伸（maxRank 和 minRank 必须由正常牌确定）
    // 如果 expectedLength == cards.length 且 gaps == wildCards.length：正好填满中间缺口
    // 若有多余级牌，它们只能作为端点延伸 → 不合法
    if (wildCards.length > gaps) return null;

    return GuandanHand(
        cards: cards, type: HandType.straight, rank: maxRank);
  }

  // ──────────────────────────────────────────────────────────────
  // 连对（3对及以上连续点数的对子）
  // ──────────────────────────────────────────────────────────────

  static GuandanHand? _tryConsecutivePairs(
      List<GuandanCard> cards, int level) {
    final n = cards.length;
    if (n < 6 || n % 2 != 0) return null;
    if (cards.any((c) => c.isJoker)) return null;

    final wildCards = cards.where((c) => _isWild(c, level)).toList();
    final normalCards = cards.where((c) => !_isWild(c, level)).toList();

    // 统计正常牌中每个点数的数量
    final rankCount = <int, int>{};
    for (final c in normalCards) {
      rankCount[c.rank!] = (rankCount[c.rank!] ?? 0) + 1;
    }

    // 检查没有哪个点数超过2张
    if (rankCount.values.any((cnt) => cnt > 2)) return null;

    final ranks = rankCount.keys.toList()..sort();
    if (ranks.isEmpty) return null;
    if (ranks.contains(14)) return null; // A 不参与连对

    final minRank = ranks.first;
    final maxRank = ranks.last;

    // 期望的连续对数
    final expectedPairs = maxRank - minRank + 1;
    final existingPairs = rankCount.values.fold(0, (a, b) => a + (b == 2 ? 1 : 0));
    final halfPairs = rankCount.values.fold(0, (a, b) => a + (b == 1 ? 1 : 0));

    // 缺口 = 没有牌的点数 + 只有一张的点数需要补一张
    final missingPairs = expectedPairs - existingPairs - halfPairs;
    final wildsNeeded = missingPairs * 2 + halfPairs; // 缺整对 * 2 + 缺半对 * 1

    if (wildsNeeded > wildCards.length) return null;
    if (wildCards.length != wildsNeeded) return null; // 多余的级牌不允许

    // 验证总牌数
    if (n != expectedPairs * 2) return null;

    return GuandanHand(
        cards: cards, type: HandType.consecutivePairs, rank: maxRank);
  }

  // ──────────────────────────────────────────────────────────────
  // 钢板（3组及以上连续点数的三张）
  // ──────────────────────────────────────────────────────────────

  static GuandanHand? _trySteelPlate(List<GuandanCard> cards, int level) {
    final n = cards.length;
    if (n < 6 || n % 3 != 0) return null;
    if (cards.any((c) => c.isJoker)) return null;

    final wildCards = cards.where((c) => _isWild(c, level)).toList();
    final normalCards = cards.where((c) => !_isWild(c, level)).toList();

    final rankCount = <int, int>{};
    for (final c in normalCards) {
      rankCount[c.rank!] = (rankCount[c.rank!] ?? 0) + 1;
    }

    if (rankCount.values.any((cnt) => cnt > 3)) return null;

    final ranks = rankCount.keys.toList()..sort();
    if (ranks.isEmpty) return null;
    if (ranks.contains(14)) return null;

    final minRank = ranks.first;
    final maxRank = ranks.last;
    final expectedGroups = maxRank - minRank + 1;

    // 计算需要的级牌数量
    int wildsNeeded = 0;
    for (int r = minRank; r <= maxRank; r++) {
      final cnt = rankCount[r] ?? 0;
      wildsNeeded += (3 - cnt);
    }

    if (wildsNeeded != wildCards.length) return null;
    if (n != expectedGroups * 3) return null;

    return GuandanHand(
        cards: cards, type: HandType.steelPlate, rank: maxRank);
  }

  // ──────────────────────────────────────────────────────────────
  // 辅助方法
  // ──────────────────────────────────────────────────────────────

  static bool _isWild(GuandanCard card, int level) =>
      !card.isJoker && card.rank == level;

  static int _wildCount(List<GuandanCard> cards, int level) =>
      cards.where((c) => _isWild(c, level)).length;

  static List<GuandanCard> _nonWildRanks(List<GuandanCard> cards, int level) =>
      cards.where((c) => !_isWild(c, level)).toList();

  static int _cardRank(GuandanCard card) {
    if (card.isBigJoker) return 1000;
    if (card.isSmallJoker) return 998;
    return card.rank!;
  }

  /// 在 [cards] 中找到所有能构成 [groupSize] 张相同点数的候选点数
  static List<int> _possibleGroupRanks(
      List<GuandanCard> cards, int groupSize, int level) {
    final rankCount = <int, int>{};
    final wilds = _wildCount(cards, level);
    for (final c in _nonWildRanks(cards, level)) {
      if (c.isJoker) continue;
      rankCount[c.rank!] = (rankCount[c.rank!] ?? 0) + 1;
    }
    return rankCount.entries
        .where((e) => e.value + wilds >= groupSize)
        .map((e) => e.key)
        .toList();
  }

  /// 从 [cards] 中提取恰好 [groupSize] 张点数为 [rank] 的牌（优先取正常牌，不足用级牌补）
  static List<GuandanCard>? _extractGroup(
      List<GuandanCard> cards, int rank, int groupSize, int level) {
    final normal = cards.where((c) => !_isWild(c, level) && !c.isJoker && c.rank == rank).toList();
    final wild = cards.where((c) => _isWild(c, level)).toList();
    if (normal.length > groupSize) return null;
    final needed = groupSize - normal.length;
    if (needed > wild.length) return null;
    return [...normal, ...wild.take(needed)];
  }

  /// 从 [cards] 中移除 [toRemove] 中的牌（基于对象相等）
  static List<GuandanCard> _removeCards(
      List<GuandanCard> cards, List<GuandanCard> toRemove) {
    final remaining = List<GuandanCard>.from(cards);
    for (final c in toRemove) {
      remaining.remove(c);
    }
    return remaining;
  }
}
