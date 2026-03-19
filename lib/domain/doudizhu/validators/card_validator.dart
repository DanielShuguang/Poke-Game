import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 牌型枚举
enum CardCombination {
  /// 单张
  single,

  /// 对子
  pair,

  /// 三张
  triple,

  /// 三带一
  tripleWithSingle,

  /// 三带二
  tripleWithPair,

  /// 顺子（5张以上连续单牌）
  straight,

  /// 连对（3对以上连续对子）
  pairStraight,

  /// 飞机不带（2个以上连续三张）
  plane,

  /// 飞机带单
  planeWithSingles,

  /// 飞机带对
  planeWithPairs,

  /// 四带二单
  fourWithTwoSingles,

  /// 四带二对
  fourWithTwoPairs,

  /// 炸弹
  bomb,

  /// 王炸
  rocket,
}

/// 牌型验证器
class CardValidator {
  const CardValidator();

  /// 验证牌型
  CardCombination? validate(List<Card> cards) {
    if (cards.isEmpty) return null;

    final sortedCards = List<Card>.from(cards)..sort();
    final ranks = sortedCards.map((c) => c.rank).toList();
    final rankCounts = _countRanks(ranks);

    // 检查王炸
    if (_isRocket(sortedCards)) {
      return CardCombination.rocket;
    }

    // 检查炸弹
    if (_isBomb(rankCounts)) {
      return CardCombination.bomb;
    }

    // 检查单张
    if (cards.length == 1) {
      return CardCombination.single;
    }

    // 检查对子
    if (_isPair(rankCounts)) {
      return CardCombination.pair;
    }

    // 检查三张
    if (_isTriple(rankCounts)) {
      return CardCombination.triple;
    }

    // 检查三带一
    if (_isTripleWithSingle(rankCounts)) {
      return CardCombination.tripleWithSingle;
    }

    // 检查三带二
    if (_isTripleWithPair(rankCounts)) {
      return CardCombination.tripleWithPair;
    }

    // 检查顺子
    if (_isStraight(ranks)) {
      return CardCombination.straight;
    }

    // 检查连对
    if (_isPairStraight(rankCounts, ranks)) {
      return CardCombination.pairStraight;
    }

    // 检查飞机
    if (_isPlane(rankCounts, cards.length)) {
      return CardCombination.plane;
    }

    // 检查飞机带单
    if (_isPlaneWithSingles(rankCounts, cards.length)) {
      return CardCombination.planeWithSingles;
    }

    // 检查飞机带对
    if (_isPlaneWithPairs(rankCounts, cards.length)) {
      return CardCombination.planeWithPairs;
    }

    // 检查四带二单
    if (_isFourWithTwoSingles(rankCounts)) {
      return CardCombination.fourWithTwoSingles;
    }

    // 检查四带二对
    if (_isFourWithTwoPairs(rankCounts)) {
      return CardCombination.fourWithTwoPairs;
    }

    return null;
  }

  /// 判断是否可以打过上家
  bool canBeat(List<Card> myCards, List<Card> lastCards) {
    final myCombination = validate(myCards);
    final lastCombination = validate(lastCards);

    if (myCombination == null || lastCombination == null) {
      return false;
    }

    // 王炸最大
    if (myCombination == CardCombination.rocket) {
      return true;
    }

    // 炸弹可以打任何非炸弹、非王炸
    if (myCombination == CardCombination.bomb) {
      return lastCombination != CardCombination.rocket;
    }

    // 炸弹和王炸不能被普通牌型打
    if (lastCombination == CardCombination.bomb ||
        lastCombination == CardCombination.rocket) {
      return false;
    }

    // 同类型比较大小
    if (myCombination != lastCombination) {
      return false;
    }

    // 比较牌数
    if (myCards.length != lastCards.length) {
      return false;
    }

    // 比较核心牌点数
    final myMainRank = _getMainRank(myCards);
    final lastMainRank = _getMainRank(lastCards);

    return myMainRank > lastMainRank;
  }

  /// 统计每个点数的数量
  Map<int, int> _countRanks(List<int> ranks) {
    final counts = <int, int>{};
    for (final rank in ranks) {
      counts[rank] = (counts[rank] ?? 0) + 1;
    }
    return counts;
  }

  /// 检查王炸
  bool _isRocket(List<Card> cards) {
    return cards.length == 2 &&
        cards.any((c) => c.isSmallJoker) &&
        cards.any((c) => c.isBigJoker);
  }

  /// 检查炸弹
  bool _isBomb(Map<int, int> rankCounts) {
    return rankCounts.values.any((count) => count == 4);
  }

  /// 检查对子
  bool _isPair(Map<int, int> rankCounts) {
    return rankCounts.length == 1 && rankCounts.values.first == 2;
  }

  /// 检查三张
  bool _isTriple(Map<int, int> rankCounts) {
    return rankCounts.length == 1 && rankCounts.values.first == 3;
  }

  /// 检查三带一
  bool _isTripleWithSingle(Map<int, int> rankCounts) {
    if (rankCounts.length != 2) return false;
    final counts = rankCounts.values.toList()..sort();
    return counts[0] == 1 && counts[1] == 3;
  }

  /// 检查三带二
  bool _isTripleWithPair(Map<int, int> rankCounts) {
    if (rankCounts.length != 2) return false;
    final counts = rankCounts.values.toList()..sort();
    return counts[0] == 2 && counts[1] == 3;
  }

  /// 检查顺子（5张以上连续单牌，不包含2和王）
  bool _isStraight(List<int> ranks) {
    if (ranks.length < 5) return false;
    // 不能包含2和王
    if (ranks.any((r) => r >= 15)) return false;
    // 检查是否连续（ranks 是降序排列，从大到小）
    for (var i = 1; i < ranks.length; i++) {
      if (ranks[i - 1] - ranks[i] != 1) return false;
    }
    return true;
  }

  /// 检查连对（3对以上连续对子）
  bool _isPairStraight(Map<int, int> rankCounts, List<int> ranks) {
    if (ranks.length < 6) return false;
    // 每个点数都是2张
    if (!rankCounts.values.every((c) => c == 2)) return false;
    // 不能包含2和王
    if (ranks.any((r) => r >= 15)) return false;
    // 检查是否连续
    final uniqueRanks = rankCounts.keys.toList()..sort();
    for (var i = 1; i < uniqueRanks.length; i++) {
      if (uniqueRanks[i] - uniqueRanks[i - 1] != 1) return false;
    }
    return uniqueRanks.length >= 3;
  }

  /// 检查飞机不带（2个以上连续三张）
  bool _isPlane(Map<int, int> rankCounts, int totalCards) {
    final triples = rankCounts.entries.where((e) => e.value == 3).toList();
    if (triples.length < 2) return false;
    // 检查三张是否连续
    final tripleRanks = triples.map((e) => e.key).toList()..sort();
    // 不能包含2和王
    if (tripleRanks.any((r) => r >= 15)) return false;
    for (var i = 1; i < tripleRanks.length; i++) {
      if (tripleRanks[i] - tripleRanks[i - 1] != 1) return false;
    }
    // 总牌数应该等于三张的数量 * 3
    return totalCards == tripleRanks.length * 3;
  }

  /// 检查飞机带单
  bool _isPlaneWithSingles(Map<int, int> rankCounts, int totalCards) {
    final triples = rankCounts.entries.where((e) => e.value == 3).toList();
    if (triples.length < 2) return false;
    final tripleRanks = triples.map((e) => e.key).toList()..sort();
    // 不能包含2和王
    if (tripleRanks.any((r) => r >= 15)) return false;
    for (var i = 1; i < tripleRanks.length; i++) {
      if (tripleRanks[i] - tripleRanks[i - 1] != 1) return false;
    }
    // 总牌数应该等于三张的数量 * 4
    return totalCards == tripleRanks.length * 4;
  }

  /// 检查飞机带对
  bool _isPlaneWithPairs(Map<int, int> rankCounts, int totalCards) {
    final triples = rankCounts.entries.where((e) => e.value == 3).toList();
    if (triples.length < 2) return false;
    final tripleRanks = triples.map((e) => e.key).toList()..sort();
    // 不能包含2和王
    if (tripleRanks.any((r) => r >= 15)) return false;
    for (var i = 1; i < tripleRanks.length; i++) {
      if (tripleRanks[i] - tripleRanks[i - 1] != 1) return false;
    }
    // 总牌数应该等于三张的数量 * 5
    return totalCards == tripleRanks.length * 5;
  }

  /// 检查四带二单
  bool _isFourWithTwoSingles(Map<int, int> rankCounts) {
    if (rankCounts.length != 3) return false;
    final counts = rankCounts.values.toList()..sort();
    return counts[0] == 1 && counts[1] == 1 && counts[2] == 4;
  }

  /// 检查四带二对
  bool _isFourWithTwoPairs(Map<int, int> rankCounts) {
    if (rankCounts.length != 3) return false;
    final counts = rankCounts.values.toList()..sort();
    return counts[0] == 2 && counts[1] == 2 && counts[2] == 4;
  }

  /// 获取核心牌点数（用于比较大小）
  int _getMainRank(List<Card> cards) {
    final sortedCards = List<Card>.from(cards)..sort();
    final rankCounts = _countRanks(sortedCards.map((c) => c.rank).toList());

    // 对于顺子、连对等牌型，返回最小点数
    // 对于三张、三带一、三带二、飞机等牌型，返回三张的点数
    // 对于炸弹，返回炸弹的点数

    final maxCount = rankCounts.values.reduce((a, b) => a > b ? a : b);

    // 如果所有牌数量相同（顺子、连对、单张、对子），返回最小点数
    if (maxCount == 1 || (maxCount == 2 && rankCounts.values.every((c) => c == 2))) {
      return sortedCards.last.rank; // 降序排列后，最后一张是最小的
    }

    // 找到数量最多的牌的点数（三张、四张等）
    for (final entry in rankCounts.entries) {
      if (entry.value == maxCount) {
        return entry.key;
      }
    }

    return sortedCards.last.rank;
  }
}
