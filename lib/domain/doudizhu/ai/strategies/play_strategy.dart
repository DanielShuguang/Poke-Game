import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';

/// 出牌策略抽象接口
abstract class PlayStrategy {
  /// 决定出牌
  Future<PlayDecision> decide({
    required List<Card> handCards,
    required List<Card>? lastPlayedCards,
    required int? lastPlayerIndex,
    required CardValidator validator,
  });
}

/// 简单出牌策略
class SimplePlayStrategy implements PlayStrategy {
  const SimplePlayStrategy();

  @override
  Future<PlayDecision> decide({
    required List<Card> handCards,
    required List<Card>? lastPlayedCards,
    required int? lastPlayerIndex,
    required CardValidator validator,
  }) async {
    // 如果没有上家出牌，使用智能先手策略
    if (lastPlayedCards == null) {
      return PlayDecision.play(_findBestLeadCards(handCards, validator));
    }

    // 尝试找能打过的牌
    final validCards = _findValidCards(
      handCards: handCards,
      lastPlayedCards: lastPlayedCards,
      validator: validator,
    );

    if (validCards != null) {
      return PlayDecision.play(validCards);
    }

    // 打不过，过牌
    return const PlayDecision.pass();
  }

  /// 智能先手策略：优先出能消耗最多牌的组合
  List<Card> _findBestLeadCards(List<Card> handCards, CardValidator validator) {
    // 统计手牌中每个点数的牌
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    // 1. 尝试找顺子（优先出最长的顺子）
    final straight = _findBestStraight(handCards, validator);
    if (straight != null) return straight;

    // 2. 尝试找连对（优先出最长的连对）
    final pairStraight = _findBestPairStraight(handCards, validator);
    if (pairStraight != null) return pairStraight;

    // 3. 尝试找飞机
    final plane = _findBestPlane(handCards, validator);
    if (plane != null) return plane;

    // 4. 尝试找三带二（优先于三带一）
    final tripleWithPair = _findSmallestTripleWithPair(handCards, validator);
    if (tripleWithPair != null) return tripleWithPair;

    // 5. 尝试找三带一
    final tripleWithSingle = _findSmallestTripleWithSingle(handCards, validator);
    if (tripleWithSingle != null) return tripleWithSingle;

    // 6. 尝试找对子
    final pair = _findSmallestPair(handCards);
    if (pair != null) return pair;

    // 7. 最后出单张
    return [handCards.last];
  }

  /// 找最佳的顺子（优先最长、点数最小）
  List<Card>? _findBestStraight(List<Card> handCards, CardValidator validator) {
    // 统计每个点数的一张牌
    final rankCards = <int, Card>{};
    for (final card in handCards) {
      if (card.rank >= 15) continue; // 顺子不能包含2和王
      if (!rankCards.containsKey(card.rank)) {
        rankCards[card.rank] = card;
      }
    }

    if (rankCards.length < 5) return null;

    final sortedRanks = rankCards.keys.toList()..sort();

    // 找最长的连续序列
    List<int>? bestSequence;
    var currentStart = sortedRanks[0];
    var currentLength = 1;

    for (var i = 1; i < sortedRanks.length; i++) {
      if (sortedRanks[i] == sortedRanks[i - 1] + 1) {
        currentLength++;
      } else {
        if (currentLength >= 5 && (bestSequence == null || currentLength > bestSequence.length)) {
          bestSequence = List.generate(currentLength, (j) => currentStart + j);
        }
        currentStart = sortedRanks[i];
        currentLength = 1;
      }
    }
    // 检查最后一段
    if (currentLength >= 5 && (bestSequence == null || currentLength > bestSequence.length)) {
      bestSequence = List.generate(currentLength, (j) => currentStart + j);
    }

    if (bestSequence == null) return null;

    return bestSequence.map((rank) => rankCards[rank]!).toList();
  }

  /// 找最佳的连对（优先最长、点数最小）
  List<Card>? _findBestPairStraight(List<Card> handCards, CardValidator validator) {
    final rankPairs = <int, List<Card>>{};
    for (final card in handCards) {
      if (card.rank >= 15) continue;
      rankPairs.putIfAbsent(card.rank, () => []).add(card);
    }

    // 只保留有对子的点数
    final pairRanks = rankPairs.entries
        .where((e) => e.value.length >= 2)
        .map((e) => e.key)
        .toList()
      ..sort();

    if (pairRanks.length < 3) return null;

    // 找最长的连续对子序列
    List<int>? bestSequence;
    var currentStart = pairRanks[0];
    var currentLength = 1;

    for (var i = 1; i < pairRanks.length; i++) {
      if (pairRanks[i] == pairRanks[i - 1] + 1) {
        currentLength++;
      } else {
        if (currentLength >= 3 && (bestSequence == null || currentLength > bestSequence.length)) {
          bestSequence = List.generate(currentLength, (j) => currentStart + j);
        }
        currentStart = pairRanks[i];
        currentLength = 1;
      }
    }
    if (currentLength >= 3 && (bestSequence == null || currentLength > bestSequence.length)) {
      bestSequence = List.generate(currentLength, (j) => currentStart + j);
    }

    if (bestSequence == null) return null;

    final result = <Card>[];
    for (final rank in bestSequence) {
      result.addAll(rankPairs[rank]!.sublist(0, 2));
    }
    return result;
  }

  /// 找最佳的飞机（带牌）
  List<Card>? _findBestPlane(List<Card> handCards, CardValidator validator) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    // 找所有三张的点数
    final tripleRanks = rankCounts.entries
        .where((e) => e.value.length >= 3 && e.key < 15)
        .map((e) => e.key)
        .toList()
      ..sort();

    if (tripleRanks.length < 2) return null;

    // 找最长的连续三张序列
    List<int>? bestSequence;
    var currentStart = tripleRanks[0];
    var currentLength = 1;

    for (var i = 1; i < tripleRanks.length; i++) {
      if (tripleRanks[i] == tripleRanks[i - 1] + 1) {
        currentLength++;
      } else {
        if (currentLength >= 2 && (bestSequence == null || currentLength > bestSequence.length)) {
          bestSequence = List.generate(currentLength, (j) => currentStart + j);
        }
        currentStart = tripleRanks[i];
        currentLength = 1;
      }
    }
    if (currentLength >= 2 && (bestSequence == null || currentLength > bestSequence.length)) {
      bestSequence = List.generate(currentLength, (j) => currentStart + j);
    }

    if (bestSequence == null) return null;

    final tripleCards = <Card>[];
    for (final rank in bestSequence) {
      tripleCards.addAll(rankCounts[rank]!.sublist(0, 3));
    }

    // 尝试带对子
    final pairs = <Card>[];
    for (final entry in rankCounts.entries) {
      if (!bestSequence.contains(entry.key) && entry.value.length >= 2) {
        pairs.addAll(entry.value.sublist(0, 2));
        if (pairs.length >= bestSequence.length * 2) break;
      }
    }
    if (pairs.length >= bestSequence.length * 2) {
      return [...tripleCards, ...pairs.sublist(0, bestSequence.length * 2)];
    }

    // 尝试带单张
    final singles = <Card>[];
    for (final entry in rankCounts.entries) {
      if (!bestSequence.contains(entry.key)) {
        singles.addAll(entry.value);
        if (singles.length >= bestSequence.length) break;
      }
    }
    if (singles.length >= bestSequence.length) {
      return [...tripleCards, ...singles.sublist(0, bestSequence.length)];
    }

    // 飞机不带
    return tripleCards;
  }

  /// 找最小的三带二
  List<Card>? _findSmallestTripleWithPair(List<Card> handCards, CardValidator validator) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    // 找最小的三张
    int? smallestTripleRank;
    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 3 && entry.key < 15) {
        if (smallestTripleRank == null || entry.key < smallestTripleRank) {
          smallestTripleRank = entry.key;
        }
      }
    }

    if (smallestTripleRank == null) return null;

    final triple = rankCounts[smallestTripleRank]!.sublist(0, 3);

    // 找一对带的牌（优先最小的对子）
    List<Card>? smallestPair;
    for (final entry in rankCounts.entries) {
      if (entry.key != smallestTripleRank && entry.value.length >= 2) {
        if (smallestPair == null || entry.key < smallestPair.first.rank) {
          smallestPair = entry.value.sublist(0, 2);
        }
      }
    }

    if (smallestPair == null) return null;

    return [...triple, ...smallestPair];
  }

  /// 找最小的三带一
  List<Card>? _findSmallestTripleWithSingle(List<Card> handCards, CardValidator validator) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    // 找最小的三张
    int? smallestTripleRank;
    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 3) {
        if (smallestTripleRank == null || entry.key < smallestTripleRank) {
          smallestTripleRank = entry.key;
        }
      }
    }

    if (smallestTripleRank == null) return null;

    final triple = rankCounts[smallestTripleRank]!.sublist(0, 3);

    // 找一张带的牌（优先最小的单张）
    Card? smallestSingle;
    for (final entry in rankCounts.entries) {
      if (entry.key != smallestTripleRank && entry.value.isNotEmpty) {
        if (smallestSingle == null || entry.key < smallestSingle.rank) {
          smallestSingle = entry.value.first;
        }
      }
    }

    if (smallestSingle == null) return null;

    return [...triple, smallestSingle];
  }

  /// 找最小的对子
  List<Card>? _findSmallestPair(List<Card> handCards) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    int? smallestPairRank;
    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 2) {
        if (smallestPairRank == null || entry.key < smallestPairRank) {
          smallestPairRank = entry.key;
        }
      }
    }

    if (smallestPairRank == null) return null;
    return rankCounts[smallestPairRank]!.sublist(0, 2);
  }

  /// 找到能打过的牌
  List<Card>? _findValidCards({
    required List<Card> handCards,
    required List<Card> lastPlayedCards,
    required CardValidator validator,
  }) {
    final lastCombination = validator.validate(lastPlayedCards);
    if (lastCombination == null) return null;

    List<Card>? result;

    // 根据上家的牌型找对应的牌
    switch (lastCombination) {
      case CardCombination.single:
        result = _findSingleToPlay(handCards, lastPlayedCards.first.rank);
      case CardCombination.pair:
        result = _findPairToPlay(handCards, lastPlayedCards.first.rank);
      case CardCombination.triple:
        result = _findTripleToPlay(handCards, lastPlayedCards.first.rank);
      case CardCombination.tripleWithSingle:
        result = _findTripleWithSingleToPlay(handCards, lastPlayedCards, validator);
      case CardCombination.tripleWithPair:
        result = _findTripleWithPairToPlay(handCards, lastPlayedCards, validator);
      case CardCombination.straight:
        result = _findStraightToPlay(handCards, lastPlayedCards, validator);
      case CardCombination.pairStraight:
        result = _findPairStraightToPlay(handCards, lastPlayedCards, validator);
      case CardCombination.plane:
      case CardCombination.planeWithSingles:
      case CardCombination.planeWithPairs:
        result = _findPlaneToPlay(handCards, lastPlayedCards, validator, lastCombination);
      case CardCombination.fourWithTwoSingles:
      case CardCombination.fourWithTwoPairs:
        result = _findFourWithToPlay(handCards, lastPlayedCards, validator, lastCombination);
      case CardCombination.bomb:
        result = _findBombToPlay(handCards, lastPlayedCards, validator);
      case CardCombination.rocket:
        // 王炸无法被打过
        result = null;
    }

    // 如果找不到同类型更大的牌，且上家不是炸弹/王炸，尝试用炸弹压制
    if (result == null &&
        lastCombination != CardCombination.bomb &&
        lastCombination != CardCombination.rocket) {
      result = _findBombToPlay(handCards, lastPlayedCards, validator);
    }

    return result;
  }

  /// 找单张
  List<Card>? _findSingleToPlay(List<Card> handCards, int lastRank) {
    for (var i = handCards.length - 1; i >= 0; i--) {
      if (handCards[i].rank > lastRank) {
        return [handCards[i]];
      }
    }
    return null;
  }

  /// 找对子
  List<Card>? _findPairToPlay(List<Card> handCards, int lastRank) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 2 && entry.key > lastRank) {
        return entry.value.sublist(0, 2);
      }
    }
    return null;
  }

  /// 找三张
  List<Card>? _findTripleToPlay(List<Card> handCards, int lastRank) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 3 && entry.key > lastRank) {
        return entry.value.sublist(0, 3);
      }
    }
    return null;
  }

  /// 找炸弹
  List<Card>? _findBombToPlay(List<Card> handCards, List<Card> lastPlayedCards, CardValidator validator) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    // 找炸弹
    for (final entry in rankCounts.entries) {
      if (entry.value.length == 4) {
        // 如果上家也是炸弹，需要更大的
        final lastCombination = validator.validate(lastPlayedCards);
        if (lastCombination == CardCombination.bomb) {
          if (entry.key > lastPlayedCards.first.rank) {
            return entry.value;
          }
        } else {
          return entry.value;
        }
      }
    }

    // 找王炸
    final hasSmallJoker = handCards.any((c) => c.isSmallJoker);
    final hasBigJoker = handCards.any((c) => c.isBigJoker);
    if (hasSmallJoker && hasBigJoker) {
      return handCards.where((c) => c.isJoker).toList();
    }

    return null;
  }

  /// 找三带一
  List<Card>? _findTripleWithSingleToPlay(
    List<Card> handCards,
    List<Card> lastPlayedCards,
    CardValidator validator,
  ) {
    // 找到上家三张的点数
    final lastRankCounts = <int, int>{};
    for (final card in lastPlayedCards) {
      lastRankCounts[card.rank] = (lastRankCounts[card.rank] ?? 0) + 1;
    }
    int? lastTripleRank;
    for (final entry in lastRankCounts.entries) {
      if (entry.value == 3) {
        lastTripleRank = entry.key;
        break;
      }
    }
    if (lastTripleRank == null) return null;

    // 统计手牌
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    // 找三张
    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 3 && entry.key > lastTripleRank) {
        final triple = entry.value.sublist(0, 3);
        // 找一张带的单牌
        for (final singleEntry in rankCounts.entries) {
          if (singleEntry.key != entry.key && singleEntry.value.isNotEmpty) {
            return [...triple, singleEntry.value.first];
          }
        }
      }
    }

    return null;
  }

  /// 找三带二
  List<Card>? _findTripleWithPairToPlay(
    List<Card> handCards,
    List<Card> lastPlayedCards,
    CardValidator validator,
  ) {
    // 找到上家三张的点数
    final lastRankCounts = <int, int>{};
    for (final card in lastPlayedCards) {
      lastRankCounts[card.rank] = (lastRankCounts[card.rank] ?? 0) + 1;
    }
    int? lastTripleRank;
    for (final entry in lastRankCounts.entries) {
      if (entry.value == 3) {
        lastTripleRank = entry.key;
        break;
      }
    }
    if (lastTripleRank == null) return null;

    // 统计手牌
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    // 找三张
    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 3 && entry.key > lastTripleRank) {
        final triple = entry.value.sublist(0, 3);
        // 找一对带的牌
        for (final pairEntry in rankCounts.entries) {
          if (pairEntry.key != entry.key && pairEntry.value.length >= 2) {
            return [...triple, ...pairEntry.value.sublist(0, 2)];
          }
        }
      }
    }

    return null;
  }

  /// 找顺子
  List<Card>? _findStraightToPlay(
    List<Card> handCards,
    List<Card> lastPlayedCards,
    CardValidator validator,
  ) {
    final length = lastPlayedCards.length;
    // 找到上家顺子的最小点数
    final lastRanks = lastPlayedCards.map((c) => c.rank).toList()..sort();
    final lastMinRank = lastRanks.first;

    // 统计手牌中每个点数的牌（取一张即可）
    final rankCards = <int, Card>{};
    for (final card in handCards) {
      // 顺子不能包含2和王
      if (card.rank >= 15) continue;
      if (!rankCards.containsKey(card.rank)) {
        rankCards[card.rank] = card;
      }
    }

    // 找连续的顺子
    final sortedRanks = rankCards.keys.toList()..sort();
    for (var i = 0; i <= sortedRanks.length - length; i++) {
      final startRank = sortedRanks[i];
      // 检查是否连续
      var isConsecutive = true;
      for (var j = 1; j < length; j++) {
        if (sortedRanks[i + j] != startRank + j) {
          isConsecutive = false;
          break;
        }
      }
      if (isConsecutive && startRank > lastMinRank) {
        return List.generate(length, (j) => rankCards[startRank + j]!);
      }
    }

    return null;
  }

  /// 找连对
  List<Card>? _findPairStraightToPlay(
    List<Card> handCards,
    List<Card> lastPlayedCards,
    CardValidator validator,
  ) {
    // 连对的数量（对子数）
    final pairCount = lastPlayedCards.length ~/ 2;
    // 找到上家连对的最小点数
    final lastRanks = lastPlayedCards.map((c) => c.rank).toList()..sort();
    final lastMinRank = lastRanks.first;

    // 统计手牌中每个点数的对子
    final rankPairs = <int, List<Card>>{};
    for (final card in handCards) {
      // 连对不能包含2和王
      if (card.rank >= 15) continue;
      rankPairs.putIfAbsent(card.rank, () => []).add(card);
    }

    // 只保留有对子的点数
    final pairRanks = rankPairs.entries
        .where((e) => e.value.length >= 2)
        .map((e) => e.key)
        .toList()
      ..sort();

    // 找连续的连对
    for (var i = 0; i <= pairRanks.length - pairCount; i++) {
      final startRank = pairRanks[i];
      // 检查是否连续
      var isConsecutive = true;
      for (var j = 1; j < pairCount; j++) {
        if (pairRanks[i + j] != startRank + j) {
          isConsecutive = false;
          break;
        }
      }
      if (isConsecutive && startRank > lastMinRank) {
        final result = <Card>[];
        for (var j = 0; j < pairCount; j++) {
          result.addAll(rankPairs[startRank + j]!.sublist(0, 2));
        }
        return result;
      }
    }

    return null;
  }

  /// 找飞机
  List<Card>? _findPlaneToPlay(
    List<Card> handCards,
    List<Card> lastPlayedCards,
    CardValidator validator,
    CardCombination lastCombination,
  ) {
    // 找到上家飞机的三张部分
    final lastRankCounts = <int, int>{};
    for (final card in lastPlayedCards) {
      lastRankCounts[card.rank] = (lastRankCounts[card.rank] ?? 0) + 1;
    }
    final lastTripleRanks = lastRankCounts.entries
        .where((e) => e.value == 3)
        .map((e) => e.key)
        .toList()
      ..sort();
    final lastMinTripleRank = lastTripleRanks.firstOrNull;
    if (lastMinTripleRank == null) return null;

    final tripleCount = lastTripleRanks.length;

    // 统计手牌
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    // 找连续的三张
    final tripleRanks = rankCounts.entries
        .where((e) => e.value.length >= 3 && e.key < 15) // 飞机不能包含2和王
        .map((e) => e.key)
        .toList()
      ..sort();

    // 找连续的三张序列
    for (var i = 0; i <= tripleRanks.length - tripleCount; i++) {
      final startRank = tripleRanks[i];
      // 检查是否连续
      var isConsecutive = true;
      for (var j = 1; j < tripleCount; j++) {
        if (tripleRanks[i + j] != startRank + j) {
          isConsecutive = false;
          break;
        }
      }
      if (isConsecutive && startRank > lastMinTripleRank) {
        final tripleCards = <Card>[];
        for (var j = 0; j < tripleCount; j++) {
          tripleCards.addAll(rankCounts[startRank + j]!.sublist(0, 3));
        }

        // 根据牌型添加带的牌
        if (lastCombination == CardCombination.plane) {
          // 飞机不带
          return tripleCards;
        } else if (lastCombination == CardCombination.planeWithSingles) {
          // 飞机带单
          final singles = <Card>[];
          for (final entry in rankCounts.entries) {
            if (!tripleRanks.sublist(i, i + tripleCount).contains(entry.key)) {
              singles.addAll(entry.value);
              if (singles.length >= tripleCount) break;
            }
          }
          if (singles.length >= tripleCount) {
            return [...tripleCards, ...singles.sublist(0, tripleCount)];
          }
        } else if (lastCombination == CardCombination.planeWithPairs) {
          // 飞机带对
          final pairs = <Card>[];
          for (final entry in rankCounts.entries) {
            if (!tripleRanks.sublist(i, i + tripleCount).contains(entry.key) &&
                entry.value.length >= 2) {
              pairs.addAll(entry.value.sublist(0, 2));
              if (pairs.length >= tripleCount * 2) break;
            }
          }
          if (pairs.length >= tripleCount * 2) {
            return [...tripleCards, ...pairs];
          }
        }
      }
    }

    return null;
  }

  /// 找四带二
  List<Card>? _findFourWithToPlay(
    List<Card> handCards,
    List<Card> lastPlayedCards,
    CardValidator validator,
    CardCombination lastCombination,
  ) {
    // 找到上家四张的点数
    final lastRankCounts = <int, int>{};
    for (final card in lastPlayedCards) {
      lastRankCounts[card.rank] = (lastRankCounts[card.rank] ?? 0) + 1;
    }
    int? lastFourRank;
    for (final entry in lastRankCounts.entries) {
      if (entry.value == 4) {
        lastFourRank = entry.key;
        break;
      }
    }
    if (lastFourRank == null) return null;

    // 统计手牌
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    // 找四张
    for (final entry in rankCounts.entries) {
      if (entry.value.length == 4 && entry.key > lastFourRank) {
        final four = entry.value;
        if (lastCombination == CardCombination.fourWithTwoSingles) {
          // 四带二单
          final singles = <Card>[];
          for (final singleEntry in rankCounts.entries) {
            if (singleEntry.key != entry.key) {
              singles.addAll(singleEntry.value);
              if (singles.length >= 2) break;
            }
          }
          if (singles.length >= 2) {
            return [...four, ...singles.sublist(0, 2)];
          }
        } else if (lastCombination == CardCombination.fourWithTwoPairs) {
          // 四带二对
          final pairs = <Card>[];
          for (final pairEntry in rankCounts.entries) {
            if (pairEntry.key != entry.key && pairEntry.value.length >= 2) {
              pairs.addAll(pairEntry.value.sublist(0, 2));
              if (pairs.length >= 4) break;
            }
          }
          if (pairs.length >= 4) {
            return [...four, ...pairs];
          }
        }
      }
    }

    return null;
  }
}
