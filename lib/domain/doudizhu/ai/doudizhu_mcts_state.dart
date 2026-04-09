import 'dart:math';

import 'package:poke_game/core/ai/mcts/mcts_game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DoudizhuAction
// ─────────────────────────────────────────────────────────────────────────────

/// 斗地主出牌行动值类。
/// - 出牌：[cards] 为出的牌，[isPass] = false
/// - 不出：[cards] 为空列表，[isPass] = true
class DoudizhuAction {
  final List<Card> cards;
  final bool isPass;

  const DoudizhuAction({required this.cards, required this.isPass});
  const DoudizhuAction.pass()
      : cards = const [],
        isPass = true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoudizhuAction &&
          isPass == other.isPass &&
          cards.length == other.cards.length &&
          _cardListEquals(cards, other.cards);

  @override
  int get hashCode => Object.hash(isPass, Object.hashAll(cards));

  static bool _cardListEquals(List<Card> a, List<Card> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 内部玩家数据（不可变）
// ─────────────────────────────────────────────────────────────────────────────

class _DdzPlayer {
  final String id;
  final List<Card> cards;
  final PlayerRole? role;

  const _DdzPlayer({required this.id, required this.cards, this.role});

  _DdzPlayer withCards(List<Card> newCards) =>
      _DdzPlayer(id: id, cards: newCards, role: role);
}

// ─────────────────────────────────────────────────────────────────────────────
// DoudizhuMctsState
// ─────────────────────────────────────────────────────────────────────────────

/// 斗地主 MCTS 适配器，实现 [MctsGameState<DoudizhuAction>]。
class DoudizhuMctsState implements MctsGameState<DoudizhuAction> {
  final List<_DdzPlayer> _players;
  final int currentPlayerIndex;
  final List<Card>? lastPlayedCards;
  final int? lastPlayerIndex;
  final int landlordIndex;

  static const _validator = CardValidator();
  static final _random = Random();

  DoudizhuMctsState._({
    required List<_DdzPlayer> players,
    required this.currentPlayerIndex,
    required this.landlordIndex,
    this.lastPlayedCards,
    this.lastPlayerIndex,
  }) : _players = players;

  // ─── 访问器（供外部代码 / 测试读取玩家数据）───────────────────────────────
  int get playerCount => _players.length;
  List<Card> cardsForPlayer(int index) => _players[index].cards;
  String playerIdAt(int index) => _players[index].id;
  PlayerRole? roleForPlayer(int index) => _players[index].role;

  // ─── 公开工厂构造函数 ────────────────────────────────────────────────────
  factory DoudizhuMctsState.fromPlayers({
    required List<String> playerIds,
    required List<List<Card>> playerCards,
    required List<PlayerRole?> playerRoles,
    required int currentPlayerIndex,
    required int landlordIndex,
    List<Card>? lastPlayedCards,
    int? lastPlayerIndex,
  }) {
    assert(playerIds.length == playerCards.length &&
        playerCards.length == playerRoles.length);
    final players = List.generate(
      playerIds.length,
      (i) => _DdzPlayer(
        id: playerIds[i],
        cards: List.from(playerCards[i]),
        role: playerRoles[i],
      ),
    );
    return DoudizhuMctsState._(
      players: players,
      currentPlayerIndex: currentPlayerIndex,
      landlordIndex: landlordIndex,
      lastPlayedCards: lastPlayedCards,
      lastPlayerIndex: lastPlayerIndex,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MctsGameState 接口实现
  // ─────────────────────────────────────────────────────────────────────────

  @override
  bool get isTerminal => _players.any((p) => p.cards.isEmpty);

  @override
  List<DoudizhuAction> getLegalActions() {
    if (isTerminal) return [];
    final hand = _players[currentPlayerIndex].cards;
    final actions = <DoudizhuAction>[];

    if (lastPlayedCards == null) {
      for (final combo in _enumerateCombinations(hand)) {
        actions.add(DoudizhuAction(cards: combo, isPass: false));
      }
    } else {
      for (final combo in _enumerateCombinations(hand)) {
        if (_validator.canBeat(combo, lastPlayedCards!)) {
          actions.add(DoudizhuAction(cards: combo, isPass: false));
        }
      }
      if (lastPlayerIndex != currentPlayerIndex) {
        actions.add(const DoudizhuAction.pass());
      }
    }

    if (actions.isEmpty && lastPlayedCards != null) {
      actions.add(const DoudizhuAction.pass());
    }
    return actions;
  }

  @override
  MctsGameState<DoudizhuAction> applyAction(DoudizhuAction action) {
    List<_DdzPlayer> newPlayers;
    List<Card>? newLastPlayed;
    int? newLastPlayerIdx;

    if (action.isPass) {
      newPlayers = _players;
      newLastPlayed = lastPlayedCards;
      newLastPlayerIdx = lastPlayerIndex;
    } else {
      final player = _players[currentPlayerIndex];
      final newCards = _removeCards(player.cards, action.cards);
      newPlayers = List.from(_players)
        ..[currentPlayerIndex] = player.withCards(newCards);
      newLastPlayed = action.cards;
      newLastPlayerIdx = currentPlayerIndex;
    }

    final nextIdx = _nextActivePlayer(newPlayers, currentPlayerIndex);
    final shouldClear =
        newLastPlayerIdx != null && nextIdx == newLastPlayerIdx;

    return DoudizhuMctsState._(
      players: newPlayers,
      currentPlayerIndex: nextIdx,
      landlordIndex: landlordIndex,
      lastPlayedCards: shouldClear ? null : newLastPlayed,
      lastPlayerIndex: shouldClear ? null : newLastPlayerIdx,
    );
  }

  @override
  double evaluate(String playerId) {
    if (isTerminal) {
      final winner = _players.firstWhere((p) => p.cards.isEmpty);
      final isWinnerLandlord = winner.role == PlayerRole.landlord;
      final evalPlayer = _players.firstWhere(
        (p) => p.id == playerId,
        orElse: () => _players.first,
      );
      final evalIsLandlord = evalPlayer.role == PlayerRole.landlord;
      if (evalIsLandlord) return isWinnerLandlord ? 1.0 : 0.0;
      return isWinnerLandlord ? 0.0 : 1.0;
    }
    return _heuristicScore(playerId);
  }

  @override
  MctsGameState<DoudizhuAction> determinize(String playerId) {
    final unknown = <Card>[];
    for (final p in _players) {
      if (p.id != playerId) unknown.addAll(p.cards);
    }
    unknown.shuffle(_random);

    final newPlayers = <_DdzPlayer>[];
    int offset = 0;
    for (final p in _players) {
      if (p.id == playerId) {
        newPlayers.add(p);
      } else {
        final count = p.cards.length;
        final newCards = List<Card>.from(unknown.sublist(offset, offset + count))
          ..sort();
        newPlayers.add(p.withCards(newCards));
        offset += count;
      }
    }

    return DoudizhuMctsState._(
      players: newPlayers,
      currentPlayerIndex: currentPlayerIndex,
      landlordIndex: landlordIndex,
      lastPlayedCards: lastPlayedCards,
      lastPlayerIndex: lastPlayerIndex,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 启发式评估
  // ─────────────────────────────────────────────────────────────────────────

  double _heuristicScore(String playerId) {
    final evalPlayer = _players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => _players.first,
    );
    final isLandlord = evalPlayer.role == PlayerRole.landlord;
    final initialCards = isLandlord ? 20 : 17;

    final cardCountScore = 1.0 - evalPlayer.cards.length / initialCards;
    final bombBonus = _countBombs(evalPlayer.cards) * 0.05;

    double teamBonus = 0.0;
    if (!isLandlord) {
      final partner = _players.firstWhere(
        (p) => p.id != playerId && p.role == PlayerRole.peasant,
        orElse: () => evalPlayer,
      );
      teamBonus = (1.0 - partner.cards.length / 17) * 0.2;
    }

    return (cardCountScore + bombBonus + teamBonus).clamp(0.0, 1.0);
  }

  static int _countBombs(List<Card> cards) {
    int bombs = 0;
    if (cards.any((c) => c.isSmallJoker) && cards.any((c) => c.isBigJoker)) {
      bombs++;
    }
    final grouped = <int, int>{};
    for (final c in cards) {
      grouped[c.rank] = (grouped[c.rank] ?? 0) + 1;
    }
    bombs += grouped.values.where((n) => n >= 4).length;
    return bombs;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 辅助工具方法
  // ─────────────────────────────────────────────────────────────────────────

  static int _nextActivePlayer(List<_DdzPlayer> ps, int current) {
    final n = ps.length;
    for (int i = 1; i < n; i++) {
      final idx = (current + i) % n;
      if (ps[idx].cards.isNotEmpty) return idx;
    }
    return current;
  }

  static List<Card> _removeCards(List<Card> hand, List<Card> toRemove) {
    final remaining = List<Card>.from(hand);
    for (final c in toRemove) {
      remaining.remove(c);
    }
    return remaining;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 合法出牌组合枚举
  // ─────────────────────────────────────────────────────────────────────────

  static List<List<Card>> _enumerateCombinations(List<Card> hand) {
    final result = <List<Card>>[];
    final grouped = <int, List<Card>>{};
    for (final c in hand) {
      grouped.putIfAbsent(c.rank, () => []).add(c);
    }
    final sortedRanks = grouped.keys.toList()..sort();

    // 单张
    for (final c in hand) {
      result.add([c]);
    }
    // 对子
    for (final entry in grouped.entries) {
      if (entry.value.length >= 2) result.add(entry.value.sublist(0, 2));
    }
    // 三张、三带一、三带二
    for (final entry in grouped.entries) {
      if (entry.value.length >= 3) {
        final triple = entry.value.sublist(0, 3);
        result.add(triple);
        for (final se in grouped.entries) {
          if (se.key != entry.key) result.add([...triple, se.value.first]);
        }
        for (final se in grouped.entries) {
          if (se.key != entry.key && se.value.length >= 2) {
            result.add([...triple, ...se.value.sublist(0, 2)]);
          }
        }
      }
    }
    // 炸弹
    for (final entry in grouped.entries) {
      if (entry.value.length == 4) result.add(List.from(entry.value));
    }
    // 王炸
    final smallJokers = hand.where((c) => c.isSmallJoker).toList();
    final bigJokers = hand.where((c) => c.isBigJoker).toList();
    if (smallJokers.isNotEmpty && bigJokers.isNotEmpty) {
      result.add([smallJokers.first, bigJokers.first]);
    }

    _enumerateStraights(sortedRanks, grouped, result);
    _enumeratePairStraights(sortedRanks, grouped, result);
    _enumeratePlanes(sortedRanks, grouped, hand, result);
    _enumerateFourWithTwo(grouped, hand, result);

    return result;
  }

  static void _enumerateStraights(
    List<int> sortedRanks,
    Map<int, List<Card>> grouped,
    List<List<Card>> result,
  ) {
    final validRanks = sortedRanks.where((r) => r >= 3 && r <= 14).toList();
    for (int len = 5; len <= validRanks.length; len++) {
      for (int i = 0; i <= validRanks.length - len; i++) {
        final start = validRanks[i];
        bool ok = true;
        for (int j = 1; j < len; j++) {
          if (validRanks[i + j] != start + j) { ok = false; break; }
        }
        if (ok) {
          result.add([for (int j = 0; j < len; j++) grouped[start + j]!.first]);
        }
      }
    }
  }

  static void _enumeratePairStraights(
    List<int> sortedRanks,
    Map<int, List<Card>> grouped,
    List<List<Card>> result,
  ) {
    final pairRanks =
        sortedRanks.where((r) => r <= 14 && grouped[r]!.length >= 2).toList();
    for (int len = 3; len <= pairRanks.length; len++) {
      for (int i = 0; i <= pairRanks.length - len; i++) {
        final start = pairRanks[i];
        bool ok = true;
        for (int j = 1; j < len; j++) {
          if (pairRanks[i + j] != start + j) { ok = false; break; }
        }
        if (ok) {
          result.add([
            for (int j = 0; j < len; j++) ...grouped[start + j]!.sublist(0, 2),
          ]);
        }
      }
    }
  }

  static void _enumeratePlanes(
    List<int> sortedRanks,
    Map<int, List<Card>> grouped,
    List<Card> hand,
    List<List<Card>> result,
  ) {
    final tripleRanks =
        sortedRanks.where((r) => r <= 14 && grouped[r]!.length >= 3).toList();
    for (int len = 2; len <= tripleRanks.length; len++) {
      for (int i = 0; i <= tripleRanks.length - len; i++) {
        final start = tripleRanks[i];
        bool ok = true;
        for (int j = 1; j < len; j++) {
          if (tripleRanks[i + j] != start + j) { ok = false; break; }
        }
        if (!ok) continue;

        final plane = <Card>[
          for (int j = 0; j < len; j++) ...grouped[start + j]!.sublist(0, 3),
        ];
        final usedRanks = {for (int j = 0; j < len; j++) start + j};

        result.add(plane);

        final singles = hand.where((c) => !usedRanks.contains(c.rank)).toList();
        if (singles.length >= len) {
          result.add([...plane, ...singles.sublist(0, len)]);
        }

        final pairEntries = grouped.entries
            .where((e) => !usedRanks.contains(e.key) && e.value.length >= 2)
            .toList();
        if (pairEntries.length >= len) {
          result.add([
            ...plane,
            for (int j = 0; j < len; j++) ...pairEntries[j].value.sublist(0, 2),
          ]);
        }
      }
    }
  }

  static void _enumerateFourWithTwo(
    Map<int, List<Card>> grouped,
    List<Card> hand,
    List<List<Card>> result,
  ) {
    for (final entry in grouped.entries) {
      if (entry.value.length < 4) continue;
      final four = entry.value.sublist(0, 4);
      final others = hand.where((c) => c.rank != entry.key).toList();
      if (others.length >= 2) result.add([...four, others[0], others[1]]);
      final pairEntries = grouped.entries
          .where((e) => e.key != entry.key && e.value.length >= 2)
          .toList();
      if (pairEntries.length >= 2) {
        result.add([
          ...four,
          ...pairEntries[0].value.sublist(0, 2),
          ...pairEntries[1].value.sublist(0, 2),
        ]);
      }
    }
  }
}
