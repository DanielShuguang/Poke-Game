import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';

/// 斗地主 UI 状态
class DoudizhuUiState {
  /// 游戏状态
  final GameState gameState;

  /// 当前选中的牌
  final Set<Card> selectedCards;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? errorMessage;

  /// 游戏结果（获胜者ID列表）
  final List<String>? winners;

  /// 提示的牌（用于高亮显示）
  final Set<Card>? hintCards;

  /// 非阻塞性提示消息（如：全部不叫，重新发牌）
  final String? infoMessage;

  const DoudizhuUiState({
    required this.gameState,
    this.selectedCards = const {},
    this.isLoading = false,
    this.errorMessage,
    this.winners,
    this.hintCards,
    this.infoMessage,
  });

  /// 初始状态
  factory DoudizhuUiState.initial() => DoudizhuUiState(
        gameState: GameState.initial(),
      );

  /// 复制并修改
  DoudizhuUiState copyWith({
    GameState? gameState,
    Set<Card>? selectedCards,
    bool? isLoading,
    String? errorMessage,
    List<String>? winners,
    Set<Card>? hintCards,
    bool clearHintCards = false,
    String? infoMessage,
    bool clearInfoMessage = false,
  }) {
    return DoudizhuUiState(
      gameState: gameState ?? this.gameState,
      selectedCards: selectedCards ?? this.selectedCards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      winners: winners,
      hintCards: clearHintCards ? null : (hintCards ?? this.hintCards),
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
    );
  }

  /// 是否是玩家的回合
  bool isPlayerTurn(String playerId) {
    final current = gameState.currentPlayer;
    return current != null && current.id == playerId;
  }

  /// 获取玩家的手牌
  List<Card> getPlayerHand(String playerId) {
    final player = gameState.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => throw StateError('玩家不存在'),
    );
    return player.handCards;
  }

  /// 检查玩家是否能打过上家（使用提供的验证器）
  bool canPlayerBeatLastPlayer(String playerId, CardValidator validator) {
    // 如果是新一轮，可以出牌
    if (gameState.lastPlayedCards == null) {
      return true;
    }

    // 如果上家是自己，可以出牌
    if (gameState.lastPlayerIndex != null) {
      final playerIndex = gameState.players.indexWhere((p) => p.id == playerId);
      if (playerIndex == gameState.lastPlayerIndex) {
        return true;
      }
    }

    // 检查玩家手牌是否有能打过的牌
    final playerHand = getPlayerHand(playerId);
    return _hasCardsToBeat(playerHand, gameState.lastPlayedCards!, validator);
  }

  /// 检查手牌中是否有能打过目标牌的组合
  bool _hasCardsToBeat(List<Card> handCards, List<Card> lastPlayedCards, CardValidator validator) {
    final lastCombination = validator.validate(lastPlayedCards);
    if (lastCombination == null) return false;

    // 检查是否有同类型更大的牌
    if (_hasSameTypeToBeat(handCards, lastPlayedCards, lastCombination, validator)) {
      return true;
    }

    // 如果上家不是炸弹/王炸，检查是否有炸弹或王炸
    if (lastCombination != CardCombination.bomb &&
        lastCombination != CardCombination.rocket) {
      // 检查炸弹
      final rankCounts = <int, int>{};
      for (final card in handCards) {
        rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
      }
      for (final count in rankCounts.values) {
        if (count == 4) return true;
      }
      // 检查王炸
      final hasSmallJoker = handCards.any((c) => c.isSmallJoker);
      final hasBigJoker = handCards.any((c) => c.isBigJoker);
      if (hasSmallJoker && hasBigJoker) return true;
    }

    return false;
  }

  /// 检查是否有同类型更大的牌
  bool _hasSameTypeToBeat(
    List<Card> handCards,
    List<Card> lastPlayedCards,
    CardCombination lastCombination,
    CardValidator validator,
  ) {
    // 获取上家牌的主要点数
    final lastRank = _getMainRank(lastPlayedCards, lastCombination);

    // 统计手牌中每个点数的牌
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    switch (lastCombination) {
      case CardCombination.single:
        for (var i = handCards.length - 1; i >= 0; i--) {
          if (handCards[i].rank > lastRank) return true;
        }
        return false;

      case CardCombination.pair:
        for (final entry in rankCounts.entries) {
          if (entry.value.length >= 2 && entry.key > lastRank) return true;
        }
        return false;

      case CardCombination.triple:
        for (final entry in rankCounts.entries) {
          if (entry.value.length >= 3 && entry.key > lastRank) return true;
        }
        return false;

      case CardCombination.tripleWithSingle:
      case CardCombination.tripleWithPair:
        // 找三张
        for (final entry in rankCounts.entries) {
          if (entry.value.length >= 3 && entry.key > lastRank) {
            // 检查是否有带的牌
            if (lastCombination == CardCombination.tripleWithSingle) {
              for (final other in rankCounts.entries) {
                if (other.key != entry.key && other.value.isNotEmpty) return true;
              }
            } else {
              for (final other in rankCounts.entries) {
                if (other.key != entry.key && other.value.length >= 2) return true;
              }
            }
          }
        }
        return false;

      case CardCombination.straight:
        return _hasStraightToBeat(handCards, lastPlayedCards);

      case CardCombination.pairStraight:
        return _hasPairStraightToBeat(handCards, lastPlayedCards);

      case CardCombination.plane:
      case CardCombination.planeWithSingles:
      case CardCombination.planeWithPairs:
        return _hasPlaneToBeat(handCards, lastPlayedCards, lastCombination);

      case CardCombination.fourWithTwoSingles:
      case CardCombination.fourWithTwoPairs:
        return _hasFourWithToBeat(handCards, lastPlayedCards, lastCombination);

      case CardCombination.bomb:
        for (final entry in rankCounts.entries) {
          if (entry.value.length == 4 && entry.key > lastRank) return true;
        }
        // 王炸可以打炸弹
        final hasSmallJoker = handCards.any((c) => c.isSmallJoker);
        final hasBigJoker = handCards.any((c) => c.isBigJoker);
        return hasSmallJoker && hasBigJoker;

      case CardCombination.rocket:
        return false;
    }
  }

  /// 获取牌组的主要点数
  int _getMainRank(List<Card> cards, CardCombination combination) {
    final sortedCards = List<Card>.from(cards)..sort();
    final rankCounts = <int, int>{};
    for (final card in cards) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }
    final maxCount = rankCounts.values.reduce((a, b) => a > b ? a : b);

    // 顺子和连对返回最小点数
    if (maxCount == 1 || (maxCount == 2 && rankCounts.values.every((c) => c == 2))) {
      return sortedCards.last.rank; // 降序排列，最后是最小
    }

    // 找到数量最多的点数
    for (final entry in rankCounts.entries) {
      if (entry.value == maxCount) {
        return entry.key;
      }
    }
    return sortedCards.last.rank;
  }

  /// 检查是否有更大的顺子
  bool _hasStraightToBeat(List<Card> handCards, List<Card> lastPlayedCards) {
    final length = lastPlayedCards.length;
    final lastRanks = lastPlayedCards.map((c) => c.rank).toList()..sort();
    final lastMinRank = lastRanks.first;

    // 统计每个点数（取一张即可）
    final rankCards = <int, Card>{};
    for (final card in handCards) {
      if (card.rank >= 15) continue; // 顺子不能包含2和王
      if (!rankCards.containsKey(card.rank)) {
        rankCards[card.rank] = card;
      }
    }

    final sortedRanks = rankCards.keys.toList()..sort();
    for (var i = 0; i <= sortedRanks.length - length; i++) {
      final startRank = sortedRanks[i];
      var isConsecutive = true;
      for (var j = 1; j < length; j++) {
        if (sortedRanks[i + j] != startRank + j) {
          isConsecutive = false;
          break;
        }
      }
      if (isConsecutive && startRank > lastMinRank) return true;
    }
    return false;
  }

  /// 检查是否有更大的连对
  bool _hasPairStraightToBeat(List<Card> handCards, List<Card> lastPlayedCards) {
    final pairCount = lastPlayedCards.length ~/ 2;
    final lastRanks = lastPlayedCards.map((c) => c.rank).toList()..sort();
    final lastMinRank = lastRanks.first;

    final rankPairs = <int, List<Card>>{};
    for (final card in handCards) {
      if (card.rank >= 15) continue;
      rankPairs.putIfAbsent(card.rank, () => []).add(card);
    }

    final pairRanks = rankPairs.entries
        .where((e) => e.value.length >= 2)
        .map((e) => e.key)
        .toList()
      ..sort();

    for (var i = 0; i <= pairRanks.length - pairCount; i++) {
      final startRank = pairRanks[i];
      var isConsecutive = true;
      for (var j = 1; j < pairCount; j++) {
        if (pairRanks[i + j] != startRank + j) {
          isConsecutive = false;
          break;
        }
      }
      if (isConsecutive && startRank > lastMinRank) return true;
    }
    return false;
  }

  /// 检查是否有更大的飞机
  bool _hasPlaneToBeat(List<Card> handCards, List<Card> lastPlayedCards, CardCombination combination) {
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
    if (lastMinTripleRank == null) return false;

    final tripleCount = lastTripleRanks.length;

    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    final tripleRanks = rankCounts.entries
        .where((e) => e.value.length >= 3 && e.key < 15)
        .map((e) => e.key)
        .toList()
      ..sort();

    for (var i = 0; i <= tripleRanks.length - tripleCount; i++) {
      final startRank = tripleRanks[i];
      var isConsecutive = true;
      for (var j = 1; j < tripleCount; j++) {
        if (tripleRanks[i + j] != startRank + j) {
          isConsecutive = false;
          break;
        }
      }
      if (isConsecutive && startRank > lastMinTripleRank) {
        // 检查带的牌
        if (combination == CardCombination.plane) return true;
        final needed = combination == CardCombination.planeWithSingles ? tripleCount : tripleCount * 2;
        var available = 0;
        for (final entry in rankCounts.entries) {
          if (!tripleRanks.sublist(i, i + tripleCount).contains(entry.key)) {
            if (combination == CardCombination.planeWithSingles) {
              available += entry.value.length;
            } else if (entry.value.length >= 2) {
              available += 2;
            }
          }
        }
        if (available >= needed) return true;
      }
    }
    return false;
  }

  /// 检查是否有更大的四带二
  bool _hasFourWithToBeat(List<Card> handCards, List<Card> lastPlayedCards, CardCombination combination) {
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
    if (lastFourRank == null) return false;

    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    for (final entry in rankCounts.entries) {
      if (entry.value.length == 4 && entry.key > lastFourRank) {
        // 检查带的牌
        if (combination == CardCombination.fourWithTwoSingles) {
          for (final other in rankCounts.entries) {
            if (other.key != entry.key && other.value.isNotEmpty) return true;
          }
        } else {
          for (final other in rankCounts.entries) {
            if (other.key != entry.key && other.value.length >= 2) return true;
          }
        }
      }
    }
    return false;
  }
}
