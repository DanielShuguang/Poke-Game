import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_card.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_game_state.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_player.dart';
import 'package:poke_game/domain/paodekai/usecases/calculate_score_usecase.dart';
import 'package:poke_game/domain/paodekai/usecases/deal_cards_usecase.dart';
import 'package:poke_game/domain/paodekai/usecases/validate_play_usecase.dart';

final pdkGameProvider =
    StateNotifierProvider<PdkGameNotifier, PdkGameState>(
  (ref) => PdkGameNotifier(),
);

class PdkGameNotifier extends StateNotifier<PdkGameState> {
  PdkGameNotifier() : super(PdkGameState.initial());

  static const _deal = DealCardsUseCase();
  static const _validate = ValidatePlayUseCase();
  static const _score = CalculateScoreUseCase();

  // ── 初始化 ────────────────────────────────────────────────────────────────

  void startGame(List<PdkPlayer> players) {
    state = _deal(players);
  }

  // ── 出牌 ──────────────────────────────────────────────────────────────────

  bool playCards(String playerId, List<PdkCard> cards) {
    if (state.phase != PdkGamePhase.playing) return false;
    final pidx = _playerIndex(playerId);
    if (pidx == -1 || pidx != state.currentPlayerIndex) return false;

    final hand = _validate(selectedCards: cards, state: state);
    if (hand == null) return false;

    final player = state.players[pidx];
    final remaining = _removeCards(player.hand, cards);
    final updatedPlayer = player.copyWith(hand: remaining);
    final newPlayers = List.of(state.players)..[pidx] = updatedPlayer;

    final rankings = List.of(state.rankings);
    if (remaining.isEmpty) {
      rankings.add(playerId);
    }

    final nextIndex = (pidx + 1) % 3;
    final isOver = rankings.length >= 2;

    state = state.copyWith(
      players: newPlayers,
      currentPlayerIndex: nextIndex,
      lastPlayedHand: hand,
      lastPlayedPlayerIndex: pidx,
      passCount: 0,
      isFirstPlay: false,
      rankings: rankings,
      phase: isOver ? PdkGamePhase.gameOver : PdkGamePhase.playing,
    );

    if (state.phase == PdkGamePhase.gameOver) {
      _finalizeRankings();
    }

    return true;
  }

  void pass(String playerId) {
    if (state.phase != PdkGamePhase.playing) return;
    final pidx = _playerIndex(playerId);
    if (pidx == -1 || pidx != state.currentPlayerIndex) return;

    final newPassCount = state.passCount + 1;
    final nextIndex = (pidx + 1) % 3;

    if (newPassCount >= 2) {
      // 所有其他人都 pass，新轮开始，找最后出牌者
      final lastPlayedIndex = _findLastPlayedIndex(pidx);
      state = state.copyWith(
        passCount: 0,
        clearLastHand: true,
        currentPlayerIndex: lastPlayedIndex,
      );
    } else {
      state = state.copyWith(
        passCount: newPassCount,
        currentPlayerIndex: nextIndex,
      );
    }
  }

  // ── 超时托管 ───────────────────────────────────────────────────────────────

  void forcePlayCards(String playerId) {
    if (state.phase != PdkGamePhase.playing) return;
    final pidx = _playerIndex(playerId);
    if (pidx == -1) return;
    final player = state.players[pidx];
    if (player.hand.isEmpty) return;

    final sorted = List.of(player.hand)..sort((a, b) => a.compareTo(b));
    for (final card in sorted) {
      if (playCards(playerId, [card])) return;
    }
    pass(playerId);
  }

  void forcePass(String playerId) => pass(playerId);

  // ── 积分 ──────────────────────────────────────────────────────────────────

  /// 游戏结束后返回 playerId → 积分变化，phase 不为 gameOver 时返回空 Map
  Map<String, int> getScores() {
    if (state.phase != PdkGamePhase.gameOver) return {};
    if (state.rankings.length != 3) return {};
    return _score(state.rankings);
  }

  // ── 联机接口 ───────────────────────────────────────────────────────────────

  PdkGameState get currentState => state;

  void syncState(PdkGameState newState) {
    state = newState;
  }

  // ── 私有辅助 ───────────────────────────────────────────────────────────────

  int _playerIndex(String playerId) =>
      state.players.indexWhere((p) => p.id == playerId);

  List<PdkCard> _removeCards(List<PdkCard> hand, List<PdkCard> toRemove) {
    final remaining = List.of(hand);
    for (final card in toRemove) {
      final idx = remaining.indexOf(card);
      if (idx != -1) remaining.removeAt(idx);
    }
    return remaining;
  }

  /// 当 passCount==2 时，找到最后出牌的玩家索引
  /// 两人都 pass 了，所以最后出牌者在当前 passer 的前 2 位
  int _findLastPlayedIndex(int currentPasserIndex) {
    return (currentPasserIndex - 2 + 3) % 3;
  }

  void _finalizeRankings() {
    final allIds = state.players.map((p) => p.id).toList();
    final missing = allIds.firstWhere(
      (id) => !state.rankings.contains(id),
      orElse: () => '',
    );
    if (missing.isNotEmpty) {
      final finalRankings = [...state.rankings, missing];
      state = state.copyWith(rankings: finalRankings);
    }
  }
}
