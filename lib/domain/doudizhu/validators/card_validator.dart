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

  /// 从给定牌中找出能打过的最小牌型（非先手情况）
  /// 返回能打过上家且最小的牌组合，若无则返回 null
  List<Card>? findMinBeatingCombination(List<Card> myCards, List<Card> lastCards) {
    if (lastCards.isEmpty) return null;

    final lastCombination = validate(lastCards);
    if (lastCombination == null) return null;

    // 按点数分组
    final rankGroups = _groupCardsByRank(myCards);

    // 根据上家牌型分类处理
    switch (lastCombination) {
      case CardCombination.single:
        return _findMinSingle(rankGroups, lastCards.first.rank);
      case CardCombination.pair:
        return _findMinPair(rankGroups, _getMainRank(lastCards));
      case CardCombination.triple:
        return _findMinTriple(rankGroups, _getMainRank(lastCards));
      case CardCombination.tripleWithSingle:
        return _findMinTripleWithSingle(rankGroups, _getMainRank(lastCards), myCards);
      case CardCombination.tripleWithPair:
        return _findMinTripleWithPair(rankGroups, _getMainRank(lastCards), myCards);
      case CardCombination.straight:
        return _findMinStraight(rankGroups, lastCards.length, _getMainRank(lastCards));
      case CardCombination.pairStraight:
        return _findMinPairStraight(rankGroups, lastCards.length, _getMainRank(lastCards));
      case CardCombination.plane:
        return _findMinPlane(rankGroups, lastCards.length ~/ 3, _getMainRank(lastCards));
      case CardCombination.planeWithSingles:
        return _findMinPlaneWithSingles(rankGroups, lastCards.length ~/ 4, _getMainRank(lastCards), myCards);
      case CardCombination.planeWithPairs:
        return _findMinPlaneWithPairs(rankGroups, lastCards.length ~/ 5, _getMainRank(lastCards), myCards);
      case CardCombination.fourWithTwoSingles:
        return _findMinFourWithTwoSingles(rankGroups, _getMainRank(lastCards), myCards);
      case CardCombination.fourWithTwoPairs:
        return _findMinFourWithTwoPairs(rankGroups, _getMainRank(lastCards), myCards);
      case CardCombination.bomb:
        return _findMinBomb(rankGroups, _getMainRank(lastCards));
      case CardCombination.rocket:
        return null; // 王炸无法被打过
    }
  }

  /// 从给定牌中找出最优牌型（先手情况）
  /// 优先级：飞机带对 > 飞机带单 > 飞机 > 连对 > 顺子 > 四带二对 > 四带二单 > 三带二 > 三带一 > 三张 > 对子 > 单张
  List<Card>? findBestCombination(List<Card> myCards) {
    if (myCards.isEmpty) return null;

    final rankGroups = _groupCardsByRank(myCards);

    // 尝试各种牌型，按优先级从高到低
    final planeWithPairs = _findBestPlaneWithPairs(rankGroups, myCards);
    if (planeWithPairs != null) return planeWithPairs;

    final planeWithSingles = _findBestPlaneWithSingles(rankGroups, myCards);
    if (planeWithSingles != null) return planeWithSingles;

    final plane = _findBestPlane(rankGroups);
    if (plane != null) return plane;

    final pairStraight = _findBestPairStraight(rankGroups);
    if (pairStraight != null) return pairStraight;

    final straight = _findBestStraight(rankGroups);
    if (straight != null) return straight;

    final fourWithTwoPairs = _findBestFourWithTwoPairs(rankGroups, myCards);
    if (fourWithTwoPairs != null) return fourWithTwoPairs;

    final fourWithTwoSingles = _findBestFourWithTwoSingles(rankGroups, myCards);
    if (fourWithTwoSingles != null) return fourWithTwoSingles;

    final tripleWithPair = _findBestTripleWithPair(rankGroups, myCards);
    if (tripleWithPair != null) return tripleWithPair;

    final tripleWithSingle = _findBestTripleWithSingle(rankGroups, myCards);
    if (tripleWithSingle != null) return tripleWithSingle;

    final triple = _findBestTriple(rankGroups);
    if (triple != null) return triple;

    final pair = _findBestPair(rankGroups);
    if (pair != null) return pair;

    // 返回最大的单张
    final sorted = List<Card>.from(myCards)..sort();
    return [sorted.first];
  }

  /// 按点数分组
  Map<int, List<Card>> _groupCardsByRank(List<Card> cards) {
    final groups = <int, List<Card>>{};
    for (final card in cards) {
      groups.putIfAbsent(card.rank, () => []).add(card);
    }
    return groups;
  }

  // ========== 非先手情况：找最小能打过的牌型 ==========

  List<Card>? _findMinSingle(Map<int, List<Card>> rankGroups, int lastRank) {
    final sortedRanks = rankGroups.keys.toList()..sort();
    for (final rank in sortedRanks) {
      if (rank > lastRank) {
        return [rankGroups[rank]!.first];
      }
    }
    return null;
  }

  List<Card>? _findMinPair(Map<int, List<Card>> rankGroups, int lastMainRank) {
    final sortedRanks = rankGroups.keys.toList()..sort();
    for (final rank in sortedRanks) {
      if (rank > lastMainRank && rankGroups[rank]!.length >= 2) {
        return rankGroups[rank]!.take(2).toList();
      }
    }
    // 没有对子能打过，尝试炸弹
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinTriple(Map<int, List<Card>> rankGroups, int lastMainRank) {
    final sortedRanks = rankGroups.keys.toList()..sort();
    for (final rank in sortedRanks) {
      if (rank > lastMainRank && rankGroups[rank]!.length >= 3) {
        return rankGroups[rank]!.take(3).toList();
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinTripleWithSingle(Map<int, List<Card>> rankGroups, int lastMainRank, List<Card> allCards) {
    final sortedRanks = rankGroups.keys.toList()..sort();
    for (final rank in sortedRanks) {
      if (rank > lastMainRank && rankGroups[rank]!.length >= 3) {
        // 找一张单牌（不能是三张本身的牌）
        for (final otherRank in sortedRanks) {
          if (otherRank != rank && rankGroups[otherRank]!.isNotEmpty) {
            return [...rankGroups[rank]!.take(3), rankGroups[otherRank]!.first];
          }
        }
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinTripleWithPair(Map<int, List<Card>> rankGroups, int lastMainRank, List<Card> allCards) {
    final sortedRanks = rankGroups.keys.toList()..sort();
    for (final rank in sortedRanks) {
      if (rank > lastMainRank && rankGroups[rank]!.length >= 3) {
        // 找一对牌（不能是三张本身的牌）
        for (final otherRank in sortedRanks) {
          if (otherRank != rank && rankGroups[otherRank]!.length >= 2) {
            return [...rankGroups[rank]!.take(3), ...rankGroups[otherRank]!.take(2)];
          }
        }
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinStraight(Map<int, List<Card>> rankGroups, int length, int lastMainRank) {
    // 顺子主牌是最小的那张
    final availableRanks = rankGroups.keys.where((r) => r < 15).toList()..sort();

    for (int start = 3; start <= 14 - length + 1; start++) {
      // 检查是否有连续的牌
      bool hasAll = true;
      for (int i = 0; i < length; i++) {
        if (!availableRanks.contains(start + i)) {
          hasAll = false;
          break;
        }
      }
      if (hasAll && start > lastMainRank) {
        final cards = <Card>[];
        for (int i = 0; i < length; i++) {
          cards.add(rankGroups[start + i]!.first);
        }
        return cards;
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinPairStraight(Map<int, List<Card>> rankGroups, int totalLength, int lastMainRank) {
    final pairCount = totalLength ~/ 2;
    final availableRanks = rankGroups.keys
        .where((r) => r < 15 && rankGroups[r]!.length >= 2)
        .toList()..sort();

    for (int start = 3; start <= 14 - pairCount + 1; start++) {
      bool hasAll = true;
      for (int i = 0; i < pairCount; i++) {
        if (!availableRanks.contains(start + i)) {
          hasAll = false;
          break;
        }
      }
      if (hasAll && start > lastMainRank) {
        final cards = <Card>[];
        for (int i = 0; i < pairCount; i++) {
          cards.addAll(rankGroups[start + i]!.take(2));
        }
        return cards;
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinPlane(Map<int, List<Card>> rankGroups, int tripleCount, int lastMainRank) {
    final availableRanks = rankGroups.keys
        .where((r) => r < 15 && rankGroups[r]!.length >= 3)
        .toList()..sort();

    for (int start = 3; start <= 14 - tripleCount + 1; start++) {
      bool hasAll = true;
      for (int i = 0; i < tripleCount; i++) {
        if (!availableRanks.contains(start + i)) {
          hasAll = false;
          break;
        }
      }
      if (hasAll && start > lastMainRank) {
        final cards = <Card>[];
        for (int i = 0; i < tripleCount; i++) {
          cards.addAll(rankGroups[start + i]!.take(3));
        }
        return cards;
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinPlaneWithSingles(Map<int, List<Card>> rankGroups, int tripleCount, int lastMainRank, List<Card> allCards) {
    final availableRanks = rankGroups.keys
        .where((r) => r < 15 && rankGroups[r]!.length >= 3)
        .toList()..sort();

    for (int start = 3; start <= 14 - tripleCount + 1; start++) {
      bool hasAll = true;
      final tripleRanks = <int>[];
      for (int i = 0; i < tripleCount; i++) {
        if (!availableRanks.contains(start + i)) {
          hasAll = false;
          break;
        }
        tripleRanks.add(start + i);
      }
      if (hasAll && start > lastMainRank) {
        // 找单牌
        final singles = <Card>[];
        final sortedRanks = rankGroups.keys.toList()..sort();
        for (final rank in sortedRanks) {
          if (!tripleRanks.contains(rank) && singles.length < tripleCount) {
            singles.add(rankGroups[rank]!.first);
          }
        }
        if (singles.length == tripleCount) {
          final cards = <Card>[];
          for (final rank in tripleRanks) {
            cards.addAll(rankGroups[rank]!.take(3));
          }
          cards.addAll(singles);
          return cards;
        }
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinPlaneWithPairs(Map<int, List<Card>> rankGroups, int tripleCount, int lastMainRank, List<Card> allCards) {
    final availableRanks = rankGroups.keys
        .where((r) => r < 15 && rankGroups[r]!.length >= 3)
        .toList()..sort();

    for (int start = 3; start <= 14 - tripleCount + 1; start++) {
      bool hasAll = true;
      final tripleRanks = <int>[];
      for (int i = 0; i < tripleCount; i++) {
        if (!availableRanks.contains(start + i)) {
          hasAll = false;
          break;
        }
        tripleRanks.add(start + i);
      }
      if (hasAll && start > lastMainRank) {
        // 找对子
        final pairs = <Card>[];
        final pairRanks = rankGroups.keys
            .where((r) => !tripleRanks.contains(r) && rankGroups[r]!.length >= 2)
            .toList()..sort();
        for (final rank in pairRanks) {
          if (pairs.length < tripleCount * 2) {
            pairs.addAll(rankGroups[rank]!.take(2));
          }
        }
        if (pairs.length == tripleCount * 2) {
          final cards = <Card>[];
          for (final rank in tripleRanks) {
            cards.addAll(rankGroups[rank]!.take(3));
          }
          cards.addAll(pairs);
          return cards;
        }
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinFourWithTwoSingles(Map<int, List<Card>> rankGroups, int lastMainRank, List<Card> allCards) {
    final sortedRanks = rankGroups.keys.toList()..sort();
    for (final rank in sortedRanks) {
      if (rank > lastMainRank && rankGroups[rank]!.length >= 4) {
        // 找两张单牌
        final singles = <Card>[];
        for (final otherRank in sortedRanks) {
          if (otherRank != rank && singles.length < 2) {
            singles.add(rankGroups[otherRank]!.first);
          }
        }
        if (singles.length == 2) {
          return [...rankGroups[rank]!.take(4), ...singles];
        }
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinFourWithTwoPairs(Map<int, List<Card>> rankGroups, int lastMainRank, List<Card> allCards) {
    final sortedRanks = rankGroups.keys.toList()..sort();
    for (final rank in sortedRanks) {
      if (rank > lastMainRank && rankGroups[rank]!.length >= 4) {
        // 找两对牌
        final pairs = <Card>[];
        for (final otherRank in sortedRanks) {
          if (otherRank != rank && rankGroups[otherRank]!.length >= 2 && pairs.length < 4) {
            pairs.addAll(rankGroups[otherRank]!.take(2));
          }
        }
        if (pairs.length == 4) {
          return [...rankGroups[rank]!.take(4), ...pairs];
        }
      }
    }
    return _findAnyBomb(rankGroups);
  }

  List<Card>? _findMinBomb(Map<int, List<Card>> rankGroups, int lastMainRank) {
    final sortedRanks = rankGroups.keys.toList()..sort();
    for (final rank in sortedRanks) {
      if (rank > lastMainRank && rankGroups[rank]!.length >= 4) {
        return rankGroups[rank]!.take(4).toList();
      }
    }
    // 尝试王炸
    return _findRocket(rankGroups);
  }

  List<Card>? _findAnyBomb(Map<int, List<Card>> rankGroups) {
    final sortedRanks = rankGroups.keys.toList()..sort();
    for (final rank in sortedRanks) {
      if (rankGroups[rank]!.length >= 4) {
        return rankGroups[rank]!.take(4).toList();
      }
    }
    return _findRocket(rankGroups);
  }

  List<Card>? _findRocket(Map<int, List<Card>> rankGroups) {
    final smallJoker = rankGroups[16]?.isNotEmpty == true;
    final bigJoker = rankGroups[17]?.isNotEmpty == true;
    if (smallJoker && bigJoker) {
      return [rankGroups[16]!.first, rankGroups[17]!.first];
    }
    return null;
  }

  // ========== 先手情况：找最优牌型 ==========

  List<Card>? _findBestPlaneWithPairs(Map<int, List<Card>> rankGroups, List<Card> allCards) {
    final tripleRanks = rankGroups.keys
        .where((r) => r < 15 && rankGroups[r]!.length >= 3)
        .toList()..sort();

    if (tripleRanks.length < 2) return null;

    // 找最长的连续三张
    int bestStart = -1;
    int bestLength = 0;
    int currentStart = tripleRanks.first;
    int currentLength = 1;

    for (int i = 1; i < tripleRanks.length; i++) {
      if (tripleRanks[i] == tripleRanks[i - 1] + 1) {
        currentLength++;
      } else {
        if (currentLength > bestLength) {
          bestLength = currentLength;
          bestStart = currentStart;
        }
        currentStart = tripleRanks[i];
        currentLength = 1;
      }
    }
    if (currentLength > bestLength) {
      bestLength = currentLength;
      bestStart = currentStart;
    }

    if (bestLength < 2) return null;

    // 检查是否有足够的对子
    final selectedTripleRanks = List.generate(bestLength, (i) => bestStart + i);
    final pairRanks = rankGroups.keys
        .where((r) => !selectedTripleRanks.contains(r) && rankGroups[r]!.length >= 2)
        .toList();

    if (pairRanks.length >= bestLength) {
      final cards = <Card>[];
      for (final rank in selectedTripleRanks) {
        cards.addAll(rankGroups[rank]!.take(3));
      }
      for (int i = 0; i < bestLength; i++) {
        cards.addAll(rankGroups[pairRanks[i]]!.take(2));
      }
      return cards;
    }
    return null;
  }

  List<Card>? _findBestPlaneWithSingles(Map<int, List<Card>> rankGroups, List<Card> allCards) {
    final tripleRanks = rankGroups.keys
        .where((r) => r < 15 && rankGroups[r]!.length >= 3)
        .toList()..sort();

    if (tripleRanks.length < 2) return null;

    // 找最长的连续三张
    int bestStart = -1;
    int bestLength = 0;
    int currentStart = tripleRanks.first;
    int currentLength = 1;

    for (int i = 1; i < tripleRanks.length; i++) {
      if (tripleRanks[i] == tripleRanks[i - 1] + 1) {
        currentLength++;
      } else {
        if (currentLength > bestLength) {
          bestLength = currentLength;
          bestStart = currentStart;
        }
        currentStart = tripleRanks[i];
        currentLength = 1;
      }
    }
    if (currentLength > bestLength) {
      bestLength = currentLength;
      bestStart = currentStart;
    }

    if (bestLength < 2) return null;

    // 检查是否有足够的单牌
    final selectedTripleRanks = List.generate(bestLength, (i) => bestStart + i);
    final singleRanks = rankGroups.keys
        .where((r) => !selectedTripleRanks.contains(r))
        .toList();

    if (singleRanks.length >= bestLength) {
      final cards = <Card>[];
      for (final rank in selectedTripleRanks) {
        cards.addAll(rankGroups[rank]!.take(3));
      }
      for (int i = 0; i < bestLength; i++) {
        cards.add(rankGroups[singleRanks[i]]!.first);
      }
      return cards;
    }
    return null;
  }

  List<Card>? _findBestPlane(Map<int, List<Card>> rankGroups) {
    final tripleRanks = rankGroups.keys
        .where((r) => r < 15 && rankGroups[r]!.length >= 3)
        .toList()..sort();

    if (tripleRanks.length < 2) return null;

    // 找最长的连续三张
    int bestStart = -1;
    int bestLength = 0;
    int currentStart = tripleRanks.first;
    int currentLength = 1;

    for (int i = 1; i < tripleRanks.length; i++) {
      if (tripleRanks[i] == tripleRanks[i - 1] + 1) {
        currentLength++;
      } else {
        if (currentLength > bestLength) {
          bestLength = currentLength;
          bestStart = currentStart;
        }
        currentStart = tripleRanks[i];
        currentLength = 1;
      }
    }
    if (currentLength > bestLength) {
      bestLength = currentLength;
      bestStart = currentStart;
    }

    if (bestLength < 2) return null;

    final cards = <Card>[];
    for (int i = 0; i < bestLength; i++) {
      cards.addAll(rankGroups[bestStart + i]!.take(3));
    }
    return cards;
  }

  List<Card>? _findBestPairStraight(Map<int, List<Card>> rankGroups) {
    final pairRanks = rankGroups.keys
        .where((r) => r < 15 && rankGroups[r]!.length >= 2)
        .toList()..sort();

    if (pairRanks.length < 3) return null;

    // 找最长的连续对子
    int bestStart = -1;
    int bestLength = 0;
    int currentStart = pairRanks.first;
    int currentLength = 1;

    for (int i = 1; i < pairRanks.length; i++) {
      if (pairRanks[i] == pairRanks[i - 1] + 1) {
        currentLength++;
      } else {
        if (currentLength > bestLength) {
          bestLength = currentLength;
          bestStart = currentStart;
        }
        currentStart = pairRanks[i];
        currentLength = 1;
      }
    }
    if (currentLength > bestLength) {
      bestLength = currentLength;
      bestStart = currentStart;
    }

    if (bestLength < 3) return null;

    final cards = <Card>[];
    for (int i = 0; i < bestLength; i++) {
      cards.addAll(rankGroups[bestStart + i]!.take(2));
    }
    return cards;
  }

  List<Card>? _findBestStraight(Map<int, List<Card>> rankGroups) {
    final singleRanks = rankGroups.keys.where((r) => r < 15).toList()..sort();

    if (singleRanks.length < 5) return null;

    // 找最长的连续牌
    int bestStart = -1;
    int bestLength = 0;
    int currentStart = singleRanks.first;
    int currentLength = 1;

    for (int i = 1; i < singleRanks.length; i++) {
      if (singleRanks[i] == singleRanks[i - 1] + 1) {
        currentLength++;
      } else {
        if (currentLength > bestLength) {
          bestLength = currentLength;
          bestStart = currentStart;
        }
        currentStart = singleRanks[i];
        currentLength = 1;
      }
    }
    if (currentLength > bestLength) {
      bestLength = currentLength;
      bestStart = currentStart;
    }

    if (bestLength < 5) return null;

    final cards = <Card>[];
    for (int i = 0; i < bestLength; i++) {
      cards.add(rankGroups[bestStart + i]!.first);
    }
    return cards;
  }

  List<Card>? _findBestFourWithTwoPairs(Map<int, List<Card>> rankGroups, List<Card> allCards) {
    final fourRanks = rankGroups.keys.where((r) => rankGroups[r]!.length >= 4).toList();

    if (fourRanks.isEmpty) return null;

    // 找任意四张
    final fourRank = fourRanks.first;
    final pairRanks = rankGroups.keys
        .where((r) => r != fourRank && rankGroups[r]!.length >= 2)
        .toList()..sort();

    if (pairRanks.length < 2) return null;

    final cards = rankGroups[fourRank]!.take(4).toList();
    cards.addAll(rankGroups[pairRanks[0]]!.take(2));
    cards.addAll(rankGroups[pairRanks[1]]!.take(2));
    return cards;
  }

  List<Card>? _findBestFourWithTwoSingles(Map<int, List<Card>> rankGroups, List<Card> allCards) {
    final fourRanks = rankGroups.keys.where((r) => rankGroups[r]!.length >= 4).toList();

    if (fourRanks.isEmpty) return null;

    final fourRank = fourRanks.first;
    final singleRanks = rankGroups.keys.where((r) => r != fourRank).toList()..sort();

    if (singleRanks.length < 2) return null;

    final cards = rankGroups[fourRank]!.take(4).toList();
    cards.add(rankGroups[singleRanks[0]]!.first);
    cards.add(rankGroups[singleRanks[1]]!.first);
    return cards;
  }

  List<Card>? _findBestTripleWithPair(Map<int, List<Card>> rankGroups, List<Card> allCards) {
    final tripleRanks = rankGroups.keys.where((r) => rankGroups[r]!.length >= 3).toList()..sort();

    if (tripleRanks.isEmpty) return null;

    final tripleRank = tripleRanks.first;
    final pairRanks = rankGroups.keys
        .where((r) => r != tripleRank && rankGroups[r]!.length >= 2)
        .toList()..sort();

    if (pairRanks.isEmpty) return null;

    return [...rankGroups[tripleRank]!.take(3), ...rankGroups[pairRanks.first]!.take(2)];
  }

  List<Card>? _findBestTripleWithSingle(Map<int, List<Card>> rankGroups, List<Card> allCards) {
    final tripleRanks = rankGroups.keys.where((r) => rankGroups[r]!.length >= 3).toList()..sort();

    if (tripleRanks.isEmpty) return null;

    final tripleRank = tripleRanks.first;
    final singleRanks = rankGroups.keys.where((r) => r != tripleRank).toList()..sort();

    if (singleRanks.isEmpty) return null;

    return [...rankGroups[tripleRank]!.take(3), rankGroups[singleRanks.first]!.first];
  }

  List<Card>? _findBestTriple(Map<int, List<Card>> rankGroups) {
    final tripleRanks = rankGroups.keys.where((r) => rankGroups[r]!.length >= 3).toList()..sort();

    if (tripleRanks.isEmpty) return null;

    return rankGroups[tripleRanks.first]!.take(3).toList();
  }

  List<Card>? _findBestPair(Map<int, List<Card>> rankGroups) {
    final pairRanks = rankGroups.keys.where((r) => rankGroups[r]!.length >= 2).toList()..sort();

    if (pairRanks.isEmpty) return null;

    return rankGroups[pairRanks.first]!.take(2).toList();
  }
}
