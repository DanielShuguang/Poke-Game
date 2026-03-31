import 'dart:math';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/entities/trump_info.dart';
import 'package:poke_game/domain/shengji/validators/play_validator.dart';

/// 出牌策略接口
abstract class PlayStrategy {
  /// 决定出什么牌
  List<ShengjiCard> decide({
    required ShengjiGameState state,
    required String playerId,
  });
}

/// 简单出牌策略（随机出合法牌）
class EasyPlayStrategy implements PlayStrategy {
  final _random = Random();

  @override
  List<ShengjiCard> decide({
    required ShengjiGameState state,
    required String playerId,
  }) {
    final player = state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null || state.trumpInfo == null) return [];

    final hand = player.hand;
    final leadCards = state.currentRound?.leadCards ?? [];

    // 找出所有合法出牌
    final validPlays = _findAllValidPlays(
      hand: hand,
      leadCards: leadCards,
      trumpInfo: state.trumpInfo!,
    );

    if (validPlays.isEmpty) return [];

    // 随机选一个
    return validPlays[_random.nextInt(validPlays.length)];
  }

  /// 找出所有合法出牌
  List<List<ShengjiCard>> _findAllValidPlays({
    required List<ShengjiCard> hand,
    required List<ShengjiCard> leadCards,
    required TrumpInfo trumpInfo,
  }) {
    final validPlays = <List<ShengjiCard>>[];

    if (leadCards.isEmpty) {
      // 首出：任意合法牌型
      // 单张
      for (final card in hand) {
        validPlays.add([card]);
      }
      // 对子
      final rankGroups = <int?, List<ShengjiCard>>{};
      for (final card in hand) {
        if (!card.isJoker) {
          rankGroups.putIfAbsent(card.rank, () => []).add(card);
        }
      }
      for (final group in rankGroups.values) {
        if (group.length >= 2) {
          validPlays.add(group.sublist(0, 2));
        }
      }
    } else {
      // 跟牌：必须匹配牌数
      final targetCount = leadCards.length;

      // 尝试找出所有合法组合
      final combinations = _generateCombinations(hand, targetCount);
      for (final combo in combinations) {
        final result = PlayValidator.validate(
          hand: hand,
          playedCards: combo,
          leadCards: leadCards,
          trumpInfo: trumpInfo,
        );
        if (result.isValid) {
          validPlays.add(combo);
        }
      }
    }

    return validPlays;
  }

  /// 生成所有可能的牌组合
  List<List<ShengjiCard>> _generateCombinations(List<ShengjiCard> cards, int count) {
    if (count == 1) {
      return cards.map((c) => [c]).toList();
    }
    if (count > cards.length) return [];

    final result = <List<ShengjiCard>>[];
    _combine(cards, count, 0, <ShengjiCard>[], result);
    return result;
  }

  void _combine(
    List<ShengjiCard> cards,
    int count,
    int start,
    List<ShengjiCard> current,
    List<List<ShengjiCard>> result,
  ) {
    if (current.length == count) {
      result.add(List<ShengjiCard>.from(current));
      return;
    }
    for (int i = start; i < cards.length; i++) {
      current.add(cards[i]);
      _combine(cards, count, i + 1, current, result);
      current.removeLast();
    }
  }
}

/// 普通出牌策略（基本策略）
class NormalPlayStrategy implements PlayStrategy {
  @override
  List<ShengjiCard> decide({
    required ShengjiGameState state,
    required String playerId,
  }) {
    final player = state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null || state.trumpInfo == null) return [];

    final hand = player.hand;
    final leadCards = state.currentRound?.leadCards ?? [];

    if (leadCards.isEmpty) {
      // 首出策略
      return _leadPlay(hand, state, playerId);
    } else {
      // 跟牌策略
      return _followPlay(hand, leadCards, state, playerId);
    }
  }

  /// 首出策略
  List<ShengjiCard> _leadPlay(
    List<ShengjiCard> hand,
    ShengjiGameState state,
    String playerId,
  ) {
    // 优先出单张大牌
    final sortedHand = List<ShengjiCard>.from(hand)
      ..sort((a, b) => b.baseRank.compareTo(a.baseRank));

    // 找非将牌的大牌
    for (final card in sortedHand) {
      if (!state.trumpInfo!.isTrump(card) && card.baseRank >= 12) {
        return [card];
      }
    }

    // 没有大牌，出最小的
    return [sortedHand.last];
  }

  /// 跟牌策略
  List<ShengjiCard> _followPlay(
    List<ShengjiCard> hand,
    List<ShengjiCard> leadCards,
    ShengjiGameState state,
    String playerId,
  ) {
    final trumpInfo = state.trumpInfo!;
    final targetCount = leadCards.length;

    // 检查是否有队友已经出大牌
    final isTeammateWinning = _isTeammateWinning(state, playerId);

    // 找出所有合法出牌
    final validPlays = <List<ShengjiCard>>[];
    final combinations = _generateCombinations(hand, targetCount);
    for (final combo in combinations) {
      final result = PlayValidator.validate(
        hand: hand,
        playedCards: combo,
        leadCards: leadCards,
        trumpInfo: trumpInfo,
      );
      if (result.isValid) {
        validPlays.add(combo);
      }
    }

    if (validPlays.isEmpty) return [];

    // 如果队友领先，出最小的
    if (isTeammateWinning) {
      return _findSmallestPlay(validPlays, trumpInfo);
    }

    // 尝试赢牌
    final winningPlays = validPlays.where((play) {
      final cmp = PlayValidator.compare(
        a: play,
        b: leadCards,
        leadCards: leadCards,
        trumpInfo: trumpInfo,
      );
      return cmp > 0;
    }).toList();

    if (winningPlays.isNotEmpty) {
      // 选择最小的赢牌组合
      return _findSmallestPlay(winningPlays, trumpInfo);
    }

    // 无法赢牌，出最小
    return _findSmallestPlay(validPlays, trumpInfo);
  }

  /// 检查队友是否领先
  bool _isTeammateWinning(ShengjiGameState state, String playerId) {
    final player = state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null || state.currentRound == null) return false;

    final teammateSeatIndex = (player.seatIndex + 2) % 4;
    final currentPlays = state.currentRound!.plays;

    if (currentPlays.isEmpty) return false;

    // 找当前最大的牌
    int? maxSeat;
    for (final entry in currentPlays.entries) {
      if (maxSeat == null) {
        maxSeat = entry.key;
        continue;
      }
      final cmp = PlayValidator.compare(
        a: entry.value,
        b: currentPlays[maxSeat]!,
        leadCards: state.currentRound!.leadCards,
        trumpInfo: state.trumpInfo!,
      );
      if (cmp > 0) maxSeat = entry.key;
    }

    return maxSeat == teammateSeatIndex;
  }

  /// 找最小的出牌组合
  List<ShengjiCard> _findSmallestPlay(
    List<List<ShengjiCard>> plays,
    TrumpInfo trumpInfo,
  ) {
    List<ShengjiCard>? smallest;
    for (final play in plays) {
      if (smallest == null) {
        smallest = play;
        continue;
      }
      final maxCard = play.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      final smallestMax = smallest.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      if (maxCard.compareTo(smallestMax) < 0) {
        smallest = play;
      }
    }
    return smallest ?? plays.first;
  }

  /// 生成所有可能的牌组合
  List<List<ShengjiCard>> _generateCombinations(List<ShengjiCard> cards, int count) {
    if (count == 1) {
      return cards.map((c) => [c]).toList();
    }
    if (count > cards.length) return [];

    final result = <List<ShengjiCard>>[];
    _combine(cards, count, 0, <ShengjiCard>[], result);
    return result;
  }

  void _combine(
    List<ShengjiCard> cards,
    int count,
    int start,
    List<ShengjiCard> current,
    List<List<ShengjiCard>> result,
  ) {
    if (current.length == count) {
      result.add(List<ShengjiCard>.from(current));
      return;
    }
    for (int i = start; i < cards.length; i++) {
      current.add(cards[i]);
      _combine(cards, count, i + 1, current, result);
      current.removeLast();
    }
  }
}
