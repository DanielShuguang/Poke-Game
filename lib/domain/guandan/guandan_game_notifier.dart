import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai/guandan_ai_strategy.dart';
import 'entities/guandan_card.dart';
import 'entities/guandan_game_state.dart';
import 'entities/guandan_player.dart';
import 'usecases/deal_cards_usecase.dart';
import 'usecases/round_result_usecase.dart';
import 'usecases/validate_hand_usecase.dart';

/// 掼蛋游戏状态管理（StateNotifier）
class GuandanGameNotifier extends StateNotifier<GuandanGameState> {
  final GuandanAiStrategy _ai;

  GuandanGameNotifier({GuandanAiStrategy? ai})
      : _ai = ai ?? const GuandanAiStrategy(),
        super(GuandanGameState.initial());

  GuandanGameState get currentState => state;

  // ──────────────────────────────────────────────────────────────
  // 公开行动接口
  // ──────────────────────────────────────────────────────────────

  /// 初始化并开始游戏
  void startGame(List<GuandanPlayer> players, {int? leadSeat}) {
    final dealtPlayers = DealCardsUsecase.deal(players);
    final seat = leadSeat ?? 0;
    state = GuandanGameState(
      phase: GuandanPhase.playing,
      players: dealtPlayers,
      currentPlayerIndex: seat,
    );
    _scheduleAiIfNeeded();
  }

  /// 出牌
  void playCards(String playerId, List<GuandanCard> cards) {
    if (state.phase != GuandanPhase.playing) return;

    final playerIdx = _indexById(playerId);
    if (playerIdx == null) return;
    if (playerIdx != state.currentPlayerIndex) return;

    final level = state.levelForTeam(state.players[playerIdx].teamId);
    final hand = ValidateHandUsecase.validate(cards, level);
    if (hand == null) return;

    // 检查能否压制场上牌型
    if (state.lastPlayedHand != null &&
        !hand.beats(state.lastPlayedHand!, level)) {
      return;
    }

    // 从玩家手牌中移除打出的牌
    final updatedPlayer = state.players[playerIdx].copyWith(
      cards: _removeCards(state.players[playerIdx].cards, cards),
    );
    final updatedPlayers = List<GuandanPlayer>.from(state.players)
      ..[playerIdx] = updatedPlayer;

    // 检查玩家是否出完手牌
    final newPlayers = _checkFinish(updatedPlayers, playerIdx);

    final newState = state.copyWith(
      players: newPlayers,
      lastPlayedHand: hand,
      lastPlayerIndex: playerIdx,
      currentPlayerIndex: _nextActivePlayer(newPlayers, playerIdx),
    );

    state = newState;
    _afterAction();
  }

  /// pass（不出牌）
  void pass(String playerId) {
    if (state.phase != GuandanPhase.playing) return;
    final playerIdx = _indexById(playerId);
    if (playerIdx == null) return;
    if (playerIdx != state.currentPlayerIndex) return;
    if (state.lastPlayedHand == null) return; // 首出不能 pass

    final nextIdx = _nextActivePlayer(state.players, playerIdx);

    // 如果下一个出牌玩家是上一手牌的出牌者（所有人都 pass 了），清空场上牌
    final shouldClear = nextIdx == state.lastPlayerIndex;

    if (shouldClear) {
      state = state.copyWith(
        currentPlayerIndex: nextIdx,
        clearLastPlayedHand: true,
        clearLastPlayerIndex: true,
      );
    } else {
      state = state.copyWith(currentPlayerIndex: nextIdx);
    }

    _afterAction();
  }

  /// 进贡（贡牌阶段）
  void tribute(String fromPlayerId, GuandanCard card) {
    if (state.phase != GuandanPhase.tribute) return;
    final tributeState = state.tributeState;
    if (tributeState == null) return;

    final toPlayerId = tributeState.pendingTributes[fromPlayerId];
    if (toPlayerId == null) return;

    final fromPlayer = state.getPlayerById(fromPlayerId);
    if (fromPlayer == null) return;

    // 验证：必须是手牌中最大的单张
    final nonJokers = fromPlayer.cards
        .where((c) => !c.isJoker)
        .toList()
      ..sort((a, b) => b.rank!.compareTo(a.rank!));
    if (nonJokers.isEmpty || nonJokers.first != card) return;

    // 移除进贡者的牌，交给受贡者
    final newPlayers = List<GuandanPlayer>.from(state.players);
    final fromIdx = _indexById(fromPlayerId)!;
    final toIdx = _indexById(toPlayerId)!;

    newPlayers[fromIdx] = newPlayers[fromIdx].copyWith(
      cards: _removeCards(newPlayers[fromIdx].cards, [card]),
    );
    newPlayers[toIdx] = newPlayers[toIdx].copyWith(
      cards: ([...newPlayers[toIdx].cards, card]..sort()),
    );

    final newCompleted =
        Map<String, GuandanCard>.from(tributeState.completedTributes)
          ..[fromPlayerId] = card;
    final newPending =
        Map<String, String>.from(tributeState.pendingTributes)
          ..remove(fromPlayerId);

    final newTributeState = tributeState.copyWith(
      pendingTributes: newPending,
      completedTributes: newCompleted,
    );

    final newPhase = newPending.isEmpty
        ? GuandanPhase.returnTribute
        : GuandanPhase.tribute;

    state = state.copyWith(
      players: newPlayers,
      tributeState: newTributeState,
      phase: newPhase,
    );

    _scheduleAiIfNeeded();
  }

  /// 还贡（还贡阶段）
  void returnTribute(String fromPlayerId, GuandanCard card) {
    if (state.phase != GuandanPhase.returnTribute) return;
    final tributeState = state.tributeState;
    if (tributeState == null) return;

    final toPlayerId = tributeState.pendingReturnTributes[fromPlayerId];
    if (toPlayerId == null) return;

    // 还贡没有强制要求最小牌，只需是手牌中的牌
    final fromPlayer = state.getPlayerById(fromPlayerId)!;
    if (!fromPlayer.cards.contains(card)) return;

    final newPlayers = List<GuandanPlayer>.from(state.players);
    final fromIdx = _indexById(fromPlayerId)!;
    final toIdx = _indexById(toPlayerId)!;

    newPlayers[fromIdx] = newPlayers[fromIdx].copyWith(
      cards: _removeCards(newPlayers[fromIdx].cards, [card]),
    );
    newPlayers[toIdx] = newPlayers[toIdx].copyWith(
      cards: ([...newPlayers[toIdx].cards, card]..sort()),
    );

    final newCompleted =
        Map<String, GuandanCard>.from(tributeState.completedReturnTributes)
          ..[fromPlayerId] = card;
    final newPending =
        Map<String, String>.from(tributeState.pendingReturnTributes)
          ..remove(fromPlayerId);

    final newTributeState = tributeState.copyWith(
      pendingReturnTributes: newPending,
      completedReturnTributes: newCompleted,
    );

    final allDone = newPending.isEmpty;
    final newPhase =
        allDone ? GuandanPhase.playing : GuandanPhase.returnTribute;

    final nextLead = state.nextLeadSeatIndex ?? 0;

    state = state.copyWith(
      players: newPlayers,
      tributeState: newTributeState,
      phase: newPhase,
      currentPlayerIndex: allDone ? nextLead : state.currentPlayerIndex,
    );

    if (allDone) _scheduleAiIfNeeded();
  }

  /// Host/AI 超时强制 pass（单机模式超时调用）
  void forcePass(String playerId) => pass(playerId);

  /// Host 超时强制出最小牌（单机模式首出超时调用）
  void forcePlayCards(String playerId) {
    final playerIdx = _indexById(playerId);
    if (playerIdx == null) return;
    final player = state.players[playerIdx];
    if (player.cards.isEmpty) return;

    final level = state.levelForTeam(player.teamId);
    final hints = _availableHints(player, level);
    if (hints.isNotEmpty) {
      playCards(playerId, hints.first);
    }
  }

  /// 接收网络广播状态（Client 端直接替换本地状态）
  void applyNetworkState(GuandanGameState newState) {
    state = newState;
  }

  // ──────────────────────────────────────────────────────────────
  // 内部辅助
  // ──────────────────────────────────────────────────────────────

  void _afterAction() {
    if (state.isRoundOver) {
      _settleRound();
      return;
    }
    _scheduleAiIfNeeded();
  }

  void _settleRound() {
    final settled = RoundResultUsecase.calculate(state);
    state = settled;

    if (settled.phase == GuandanPhase.finished) return;

    // 判断是否需要贡牌
    if (RoundResultUsecase.needsTribute(settled)) {
      _initTributePhase(settled);
    }
  }

  void _initTributePhase(GuandanGameState settled) {
    final result = settled.roundResult!;
    final winnerTeamId = result.winnerTeamId;
    if (winnerTeamId == null) return;

    final loserTeamId = 1 - winnerTeamId;
    final losers = settled.players.where((p) => p.teamId == loserTeamId).toList();
    final winners = settled.players.where((p) => p.teamId == winnerTeamId).toList();

    // 两个输家各进贡给对应赢家（头游赢家收输家1，二游赢家收输家2）
    final pendingTributes = <String, String>{};
    for (int i = 0; i < losers.length && i < winners.length; i++) {
      pendingTributes[losers[i].id] = winners[i].id;
    }

    // 还贡：两个赢家各还一张给对应输家
    final pendingReturnTributes = <String, String>{};
    for (int i = 0; i < winners.length && i < losers.length; i++) {
      pendingReturnTributes[winners[i].id] = losers[i].id;
    }

    state = settled.copyWith(
      phase: GuandanPhase.tribute,
      tributeState: TributeState(
        pendingTributes: pendingTributes,
        pendingReturnTributes: pendingReturnTributes,
      ),
    );

    _scheduleAiIfNeeded();
  }

  void _scheduleAiIfNeeded() {
    if (state.phase == GuandanPhase.playing) {
      final current = state.currentPlayer;
      if (current.isAi) {
        Timer(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          _executeAiAction(current.id);
        });
      }
    } else if (state.phase == GuandanPhase.tribute ||
        state.phase == GuandanPhase.returnTribute) {
      _scheduleAiTribute();
    }
  }

  void _scheduleAiTribute() {
    final tributeState = state.tributeState;
    if (tributeState == null) return;

    final pendingIds = state.phase == GuandanPhase.tribute
        ? tributeState.pendingTributes.keys.toList()
        : tributeState.pendingReturnTributes.keys.toList();

    for (final playerId in pendingIds) {
      final player = state.getPlayerById(playerId);
      if (player == null || !player.isAi) continue;

      Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        final action = _ai.decideAction(state, playerId);
        if (action is TributeAction) tribute(playerId, action.card);
        if (action is ReturnTributeAction) returnTribute(playerId, action.card);
      });
    }
  }

  void _executeAiAction(String playerId) {
    final action = _ai.decideAction(state, playerId);
    switch (action) {
      case PlayCardsAction(:final cards):
        final prevIndex = state.currentPlayerIndex;
        playCards(playerId, cards);
        // playCards 可能因牌型无效静默返回，此时兜底 pass
        if (state.currentPlayerIndex == prevIndex &&
            state.phase == GuandanPhase.playing) {
          pass(playerId);
        }
      case PassAction():
        // pass 在首出时会静默返回（lastPlayedHand == null），
        // 此时强制出第一张牌避免卡死
        if (state.lastPlayedHand == null) {
          final playerIdx = _indexById(playerId);
          if (playerIdx != null) {
            final cards = state.players[playerIdx].cards;
            if (cards.isNotEmpty) playCards(playerId, [cards.first]);
          }
        } else {
          pass(playerId);
        }
      case TributeAction(:final card):
        tribute(playerId, card);
      case ReturnTributeAction(:final card):
        returnTribute(playerId, card);
    }
  }

  int? _indexById(String id) {
    final idx = state.players.indexWhere((p) => p.id == id);
    return idx == -1 ? null : idx;
  }

  /// 找下一个还有手牌的玩家（跳过已完成的）
  int _nextActivePlayer(List<GuandanPlayer> players, int current) {
    int next = (current + 1) % players.length;
    while (next != current) {
      if (!players[next].hasFinished) return next;
      next = (next + 1) % players.length;
    }
    return current;
  }

  List<GuandanPlayer> _checkFinish(
      List<GuandanPlayer> players, int playerIdx) {
    if (players[playerIdx].cards.isNotEmpty) return players;

    // 统计已完成人数
    final finishedCount = players.where((p) => p.hasFinished).length;
    final rank = FinishRank.values[finishedCount];

    final updated = List<GuandanPlayer>.from(players);
    updated[playerIdx] = updated[playerIdx].copyWith(finishRank: rank);
    return updated;
  }

  List<GuandanCard> _removeCards(
      List<GuandanCard> hand, List<GuandanCard> toRemove) {
    final remaining = List<GuandanCard>.from(hand);
    for (final c in toRemove) {
      remaining.remove(c);
    }
    return remaining;
  }

  List<List<GuandanCard>> _availableHints(GuandanPlayer player, int level) {
    return [
      [player.cards.first]
    ].where((h) => ValidateHandUsecase.validate(h, level) != null).toList();
  }
}

final guandanGameProvider =
    StateNotifierProvider<GuandanGameNotifier, GuandanGameState>(
  (ref) => GuandanGameNotifier(),
);
