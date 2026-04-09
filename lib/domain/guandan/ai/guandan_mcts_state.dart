import 'dart:math';

import 'package:poke_game/core/ai/mcts/mcts_game_state.dart';
import 'package:poke_game/domain/guandan/entities/guandan_card.dart';
import 'package:poke_game/domain/guandan/entities/guandan_hand.dart';
import 'package:poke_game/domain/guandan/usecases/hint_usecase.dart';
import 'package:poke_game/domain/guandan/usecases/validate_hand_usecase.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GuandanMctsAction
// ─────────────────────────────────────────────────────────────────────────────

/// 掼蛋 MCTS 行动值类。
/// - 出牌/贡牌：[cards] 非空，[isPass] = false
/// - 不出：[cards] 为空，[isPass] = true
/// - 贡牌阶段：[tribute] != null，[cards] = [tribute]
class GuandanMctsAction {
  final List<GuandanCard> cards;
  final bool isPass;
  final GuandanCard? tribute;

  const GuandanMctsAction({required this.cards, required this.isPass, this.tribute});
  const GuandanMctsAction.pass()
      : cards = const [],
        isPass = true,
        tribute = null;
  const GuandanMctsAction.tributeCard(GuandanCard card)
      : cards = const [],
        isPass = false,
        tribute = card;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuandanMctsAction &&
          isPass == other.isPass &&
          tribute == other.tribute &&
          cards.length == other.cards.length &&
          _listEq(cards, other.cards);

  @override
  int get hashCode => Object.hash(isPass, tribute, Object.hashAll(cards));

  static bool _listEq(List<GuandanCard> a, List<GuandanCard> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 内部阶段枚举（MCTS 仅关注出牌和贡牌）
// ─────────────────────────────────────────────────────────────────────────────

enum _MctsPhase { playing, tribute }

// ─────────────────────────────────────────────────────────────────────────────
// 内部玩家数据
// ─────────────────────────────────────────────────────────────────────────────

class _GdPlayer {
  final String id;
  final int teamId;
  final List<GuandanCard> cards;
  final bool hasFinished;

  const _GdPlayer({
    required this.id,
    required this.teamId,
    required this.cards,
    this.hasFinished = false,
  });

  _GdPlayer withCards(List<GuandanCard> newCards) => _GdPlayer(
        id: id,
        teamId: teamId,
        cards: newCards,
        hasFinished: newCards.isEmpty ? true : hasFinished,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// GuandanMctsState
// ─────────────────────────────────────────────────────────────────────────────

/// 掼蛋 MCTS 适配器，实现 [MctsGameState<GuandanMctsAction>]。
class GuandanMctsState implements MctsGameState<GuandanMctsAction> {
  final List<_GdPlayer> _players;
  final int currentPlayerIndex;
  final int team0Level;
  final int team1Level;
  final GuandanHand? lastPlayedHand;
  final int? lastPlayerIndex;
  final _MctsPhase _phase;

  /// 贡牌阶段：待进贡的玩家 ID 映射（fromId → toId）
  final Map<String, String> pendingTributes;

  static final _random = Random();

  GuandanMctsState._({
    required List<_GdPlayer> players,
    required this.currentPlayerIndex,
    required this.team0Level,
    required this.team1Level,
    this.lastPlayedHand,
    this.lastPlayerIndex,
    _MctsPhase phase = _MctsPhase.playing,
    this.pendingTributes = const {},
  })  : _players = players,
        _phase = phase;

  // ─── 访问器 ────────────────────────────────────────────────────────────────
  int get playerCount => _players.length;
  List<GuandanCard> cardsForPlayer(int index) => _players[index].cards;
  String playerIdAt(int index) => _players[index].id;
  int teamIdForPlayer(int index) => _players[index].teamId;
  bool hasPlayerFinished(int index) => _players[index].hasFinished;

  // ─── 公开工厂构造 ───────────────────────────────────────────────────────────
  factory GuandanMctsState.fromData({
    required List<String> playerIds,
    required List<int> teamIds,
    required List<List<GuandanCard>> playerCards,
    required int currentPlayerIndex,
    required int team0Level,
    required int team1Level,
    GuandanHand? lastPlayedHand,
    int? lastPlayerIndex,
    Map<String, String>? pendingTributes,
  }) {
    assert(playerIds.length == teamIds.length &&
        teamIds.length == playerCards.length);
    final players = List.generate(
      playerIds.length,
      (i) => _GdPlayer(
        id: playerIds[i],
        teamId: teamIds[i],
        cards: List.from(playerCards[i]),
        hasFinished: playerCards[i].isEmpty,
      ),
    );
    return GuandanMctsState._(
      players: players,
      currentPlayerIndex: currentPlayerIndex,
      team0Level: team0Level,
      team1Level: team1Level,
      lastPlayedHand: lastPlayedHand,
      lastPlayerIndex: lastPlayerIndex,
      phase: (pendingTributes?.isNotEmpty ?? false)
          ? _MctsPhase.tribute
          : _MctsPhase.playing,
      pendingTributes: pendingTributes ?? const {},
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MctsGameState 接口实现
  // ─────────────────────────────────────────────────────────────────────────

  @override
  bool get isTerminal {
    // 任意一方团队均手牌清空即终局
    final t0Done =
        _players.where((p) => p.teamId == 0).every((p) => p.hasFinished);
    final t1Done =
        _players.where((p) => p.teamId == 1).every((p) => p.hasFinished);
    return t0Done || t1Done;
  }

  @override
  List<GuandanMctsAction> getLegalActions() {
    if (isTerminal) return [];
    if (_phase == _MctsPhase.tribute) return _tributeActions();
    return _playingActions();
  }

  List<GuandanMctsAction> _tributeActions() {
    final player = _players[currentPlayerIndex];
    final toId = pendingTributes[player.id];
    if (toId == null) return [const GuandanMctsAction.pass()];

    // 贡牌：必须出手牌中最大的非王牌
    final normalCards = player.cards.where((c) => !c.isJoker).toList();
    if (normalCards.isEmpty) return [const GuandanMctsAction.pass()];
    normalCards.sort((a, b) => b.rank!.compareTo(a.rank!));
    final largest = normalCards.first;
    return [GuandanMctsAction.tributeCard(largest)];
  }

  List<GuandanMctsAction> _playingActions() {
    final player = _players[currentPlayerIndex];
    if (player.hasFinished) {
      // 已完成的玩家自动跳过
      return [const GuandanMctsAction.pass()];
    }
    final level = _levelForPlayer(currentPlayerIndex);
    final hints = HintUsecase.hint(player.cards, lastPlayedHand, level);
    final actions = hints
        .map((cs) => GuandanMctsAction(cards: cs, isPass: false))
        .toList();

    if (lastPlayedHand != null && lastPlayerIndex != currentPlayerIndex) {
      actions.add(const GuandanMctsAction.pass());
    }
    if (actions.isEmpty && lastPlayedHand != null) {
      actions.add(const GuandanMctsAction.pass());
    }
    return actions;
  }

  @override
  MctsGameState<GuandanMctsAction> applyAction(GuandanMctsAction action) {
    if (_phase == _MctsPhase.tribute) return _applyTribute(action);
    return _applyPlay(action);
  }

  MctsGameState<GuandanMctsAction> _applyTribute(GuandanMctsAction action) {
    final player = _players[currentPlayerIndex];
    List<_GdPlayer> newPlayers = _players;
    Map<String, String> newPending = Map.from(pendingTributes);

    if (action.tribute != null) {
      final toId = pendingTributes[player.id];
      if (toId != null) {
        final toIdx = _players.indexWhere((p) => p.id == toId);
        final newFromCards =
            _removeOne(player.cards, action.tribute!);
        final newToCards = [..._players[toIdx].cards, action.tribute!]..sort();
        newPlayers = List.from(_players)
          ..[currentPlayerIndex] = player.withCards(newFromCards)
          ..[toIdx] = _players[toIdx].withCards(newToCards);
      }
      newPending.remove(player.id);
    }

    final nextPhase =
        newPending.isEmpty ? _MctsPhase.playing : _MctsPhase.tribute;
    final nextIdx = newPending.isNotEmpty
        ? _players.indexWhere((p) => newPending.containsKey(p.id))
        : currentPlayerIndex;

    return GuandanMctsState._(
      players: newPlayers,
      currentPlayerIndex: nextIdx,
      team0Level: team0Level,
      team1Level: team1Level,
      phase: nextPhase,
      pendingTributes: newPending,
    );
  }

  MctsGameState<GuandanMctsAction> _applyPlay(GuandanMctsAction action) {
    List<_GdPlayer> newPlayers;
    GuandanHand? newLastHand;
    int? newLastPlayerIdx;

    if (action.isPass) {
      newPlayers = _players;
      newLastHand = lastPlayedHand;
      newLastPlayerIdx = lastPlayerIndex;
    } else {
      final player = _players[currentPlayerIndex];
      final level = _levelForPlayer(currentPlayerIndex);
      final hand = ValidateHandUsecase.validate(action.cards, level);
      final newCards = _removeCards(player.cards, action.cards);
      newPlayers = List.from(_players)
        ..[currentPlayerIndex] = player.withCards(newCards);
      newLastHand = hand;
      newLastPlayerIdx = currentPlayerIndex;
    }

    final nextIdx = _nextActivePlayer(newPlayers, currentPlayerIndex);
    // 所有其他玩家均已出完 → 当前玩家是唯一活跃者，自动清场
    final onlyOneLeft = nextIdx == currentPlayerIndex;
    // 上一手牌的出牌者已打完手牌 → 跳过让下一个活跃玩家自由出牌
    final lastPlayerDone = newLastPlayerIdx != null &&
        newPlayers[newLastPlayerIdx].hasFinished;
    final shouldClear =
        onlyOneLeft ||
        lastPlayerDone ||
        (newLastPlayerIdx != null && nextIdx == newLastPlayerIdx);

    return GuandanMctsState._(
      players: newPlayers,
      currentPlayerIndex: nextIdx,
      team0Level: team0Level,
      team1Level: team1Level,
      lastPlayedHand: shouldClear ? null : newLastHand,
      lastPlayerIndex: shouldClear ? null : newLastPlayerIdx,
      phase: _MctsPhase.playing,
    );
  }

  @override
  double evaluate(String playerId) {
    final playerIdx = _players.indexWhere((p) => p.id == playerId);
    if (playerIdx < 0) return 0.5;
    final myTeam = _players[playerIdx].teamId;

    if (isTerminal) {
      final t0Done =
          _players.where((p) => p.teamId == 0).every((p) => p.hasFinished);
      return (myTeam == 0 && t0Done) || (myTeam == 1 && !t0Done) ? 1.0 : 0.0;
    }

    // 启发式：团队剩余牌数越少越好 + 百搭/炸弹加分
    final myTeamPlayers = _players.where((p) => p.teamId == myTeam).toList();
    final oppTeamPlayers = _players.where((p) => p.teamId != myTeam).toList();

    final myLevel = myTeam == 0 ? team0Level : team1Level;
    final myCards = myTeamPlayers.expand((p) => p.cards).toList();
    final oppCards = oppTeamPlayers.expand((p) => p.cards).toList();

    final myScore = _teamScore(myCards, myLevel);
    final oppScore = _teamScore(oppCards, myTeam == 0 ? team1Level : team0Level);

    if (myScore + oppScore == 0) return 0.5;
    return myScore / (myScore + oppScore);
  }

  static double _teamScore(List<GuandanCard> cards, int level) {
    if (cards.isEmpty) return 10.0; // 已打完，极高分
    final remaining = cards.length;
    // 剩余越少越高，基础分 = 54 - remaining（108/2 = 54 作参考）
    double score = (54 - remaining).toDouble().clamp(0, 54);
    // 百搭加分
    score += cards.where((c) => !c.isJoker && c.rank == level).length * 2.0;
    // 大小王加分
    score += cards.where((c) => c.isSmallJoker).length * 3.0;
    score += cards.where((c) => c.isBigJoker).length * 4.0;
    // 炸弹加分
    score += _countBombs(cards, level) * 5.0;
    return score;
  }

  static int _countBombs(List<GuandanCard> cards, int level) {
    if (cards.any((c) => c.isBigJoker) &&
        cards.where((c) => c.isBigJoker).length >= 2) {
      return 1; // 天王炸（两张大王）
    }
    int bombs = 0;
    final grouped = <int, int>{};
    for (final c in cards) {
      if (!c.isJoker) grouped[c.rank!] = (grouped[c.rank!] ?? 0) + 1;
    }
    bombs += grouped.values.where((n) => n >= 4).length;
    return bombs;
  }

  @override
  MctsGameState<GuandanMctsAction> determinize(String playerId) {
    final playerIdx = _players.indexWhere((p) => p.id == playerId);
    if (playerIdx < 0) return this;
    final myTeam = _players[playerIdx].teamId;

    // 保持我方（当前玩家 + 队友）手牌不变，随机重分配对方两名玩家手牌
    final oppPlayers =
        _players.where((p) => p.teamId != myTeam).toList();
    final unknown = <GuandanCard>[];
    for (final p in oppPlayers) {
      unknown.addAll(p.cards);
    }
    unknown.shuffle(_random);

    final newPlayers = List<_GdPlayer>.from(_players);
    int offset = 0;
    for (int i = 0; i < _players.length; i++) {
      final p = _players[i];
      if (p.teamId != myTeam) {
        final count = p.cards.length;
        final newCards = List<GuandanCard>.from(unknown.sublist(offset, offset + count))
          ..sort();
        newPlayers[i] = p.withCards(newCards);
        offset += count;
      }
    }

    return GuandanMctsState._(
      players: newPlayers,
      currentPlayerIndex: currentPlayerIndex,
      team0Level: team0Level,
      team1Level: team1Level,
      lastPlayedHand: lastPlayedHand,
      lastPlayerIndex: lastPlayerIndex,
      phase: _phase,
      pendingTributes: pendingTributes,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 辅助方法
  // ─────────────────────────────────────────────────────────────────────────

  int _levelForPlayer(int idx) {
    final teamId = _players[idx].teamId;
    return teamId == 0 ? team0Level : team1Level;
  }

  static int _nextActivePlayer(List<_GdPlayer> ps, int current) {
    final n = ps.length;
    for (int i = 1; i < n; i++) {
      final idx = (current + i) % n;
      if (!ps[idx].hasFinished) return idx;
    }
    return current;
  }

  static List<GuandanCard> _removeCards(
      List<GuandanCard> hand, List<GuandanCard> toRemove) {
    final remaining = List<GuandanCard>.from(hand);
    for (final c in toRemove) {
      remaining.remove(c);
    }
    return remaining;
  }

  static List<GuandanCard> _removeOne(
      List<GuandanCard> hand, GuandanCard card) {
    final remaining = List<GuandanCard>.from(hand);
    remaining.remove(card);
    return remaining;
  }
}
