import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/data/zhajinhua/repositories/zhj_game_repository_impl.dart';
import 'package:poke_game/domain/zhajinhua/ai/zhj_ai_strategy.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_config.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/usecases/betting_usecase.dart';
import 'package:poke_game/domain/zhajinhua/usecases/deal_cards_usecase.dart';
import 'package:poke_game/domain/zhajinhua/usecases/peek_card_usecase.dart';
import 'package:poke_game/domain/zhajinhua/usecases/showdown_usecase.dart';

class ZhjGameNotifier extends StateNotifier<ZhjGameState> {
  final ZhjGameConfig _config;
  final DealCardsUsecase _dealCards;
  final BettingUsecase _betting;
  final PeekCardUsecase _peekCard;
  final ShowdownUsecase _showdown;
  final ZhjAiStrategy _aiStrategy;
  final ZhjGameRepositoryImpl _repository;

  static const String humanId = 'human';

  ZhjGameNotifier({
    ZhjGameConfig? config,
    DealCardsUsecase? dealCards,
    BettingUsecase? betting,
    PeekCardUsecase? peekCard,
    ShowdownUsecase? showdown,
    ZhjAiStrategy? aiStrategy,
    ZhjGameRepositoryImpl? repository,
  })  : _config = config ?? ZhjGameConfig.defaultConfig,
        _dealCards = dealCards ?? DealCardsUsecase(),
        _betting = betting ?? BettingUsecase(),
        _peekCard = peekCard ?? PeekCardUsecase(),
        _showdown = showdown ?? ShowdownUsecase(),
        _aiStrategy = aiStrategy ?? ZhjAiStrategy(),
        _repository = repository ?? ZhjGameRepositoryImpl(),
        super(ZhjGameState.initial()) {
    startGame();
  }

  // ─── 公开操作 ───────────────────────────────────────────────

  /// 开始新游戏（或再来一局，保留筹码）
  void startGame() {
    var s = _repository.initGame(_config);
    s = _dealCards.execute(s, _config);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  /// 看牌（仅对当前玩家有效）
  void playerPeek() {
    if (!_isHumanTurn) return;
    _update(_peekCard.execute(state));
  }

  /// 跟注
  void playerCall() {
    if (!_isHumanTurn) return;
    var s = _betting.execute(state, BettingAction.call);
    s = _nextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  /// 加注
  void playerRaise() {
    if (!_isHumanTurn) return;
    var s = _betting.execute(state, BettingAction.raise);
    s = _nextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  /// 弃牌
  void playerFold() {
    if (!_isHumanTurn) return;
    var s = _betting.execute(state, BettingAction.fold);
    s = _nextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  /// 比牌（向目标玩家发起）
  void playerShowdown(int targetIndex) {
    if (!_isHumanTurn) return;
    final currentIndex = state.currentPlayerIndex;
    var s = _showdown.execute(state, currentIndex, targetIndex);
    s = _checkWinOrNextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  /// 再来一局（保留现有筹码）
  void playAgain() {
    var s = state.copyWith(
      phase: ZhjGamePhase.waiting,
      clearWinner: true,
      clearMessage: true,
    );
    // 重置玩家状态，保留筹码
    final players = state.players.map((p) => p.copyWith(
          cards: [],
          hasPeeked: false,
          isFolded: false,
          betAmount: 0,
        )).toList();
    s = s.copyWith(players: players);
    s = _dealCards.execute(s, _config);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  // ─── 网络层接口 ────────────────────────────────────────────

  /// 暴露当前状态供网络适配器读取
  ZhjGameState get currentState => state;

  /// Client 接收 Host 广播的状态
  void applyNetworkState(ZhjGameState newState) {
    state = newState;
  }

  /// 网络行动：看牌（跳过 _isHumanTurn 检查）
  void networkPeek(String playerId) {
    if (state.currentPlayer.id != playerId) return;
    _update(_peekCard.execute(state));
  }

  /// 网络行动：跟注
  void networkCall(String playerId) {
    if (state.currentPlayer.id != playerId) return;
    var s = _betting.execute(state, BettingAction.call);
    s = _nextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  /// 网络行动：加注
  void networkRaise(String playerId) {
    if (state.currentPlayer.id != playerId) return;
    var s = _betting.execute(state, BettingAction.raise);
    s = _nextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  /// 网络行动：弃牌
  void networkFold(String playerId) {
    if (state.currentPlayer.id != playerId) return;
    var s = _betting.execute(state, BettingAction.fold);
    s = _nextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  /// 网络行动：比牌
  void networkShowdown(String playerId, int targetIndex) {
    if (state.currentPlayer.id != playerId) return;
    final currentIndex = state.currentPlayerIndex;
    var s = _showdown.execute(state, currentIndex, targetIndex);
    s = _checkWinOrNextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  /// Host 强制弃牌（超时触发）
  void forcePlayerFold(String playerId) {
    if (state.phase != ZhjGamePhase.betting) return;
    if (state.currentPlayer.id != playerId) return;
    var s = _betting.execute(state, BettingAction.fold);
    s = _nextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }

  // ─── 内部逻辑 ──────────────────────────────────────────────

  bool get _isHumanTurn {
    if (state.phase != ZhjGamePhase.betting) return false;
    return state.currentPlayer.id == humanId;
  }

  void _update(ZhjGameState s) {
    _repository.saveState(s);
    state = s;
  }

  /// 推进到下一个存活玩家
  ZhjGameState _nextTurn(ZhjGameState s) {
    if (s.hasOnlyOnePlayerAlive) {
      return _settleWinner(s);
    }
    int next = (s.currentPlayerIndex + 1) % s.players.length;
    while (s.players[next].isFolded) {
      next = (next + 1) % s.players.length;
    }
    return s.copyWith(currentPlayerIndex: next);
  }

  ZhjGameState _checkWinOrNextTurn(ZhjGameState s) {
    if (s.hasOnlyOnePlayerAlive) return _settleWinner(s);
    return _nextTurn(s);
  }

  ZhjGameState _settleWinner(ZhjGameState s) {
    final winner = s.alivePlayers.first;
    final players = s.players.map((p) {
      if (p.id == winner.id) return p.copyWith(chips: p.chips + s.pot);
      return p;
    }).toList();
    return s.copyWith(
      phase: ZhjGamePhase.settlement,
      players: players,
      winnerId: winner.id,
      pot: 0,
    );
  }

  /// 如果轮到 AI，延迟后自动执行
  void _scheduleAiTurnIfNeeded() {
    if (state.phase != ZhjGamePhase.betting) return;
    final current = state.currentPlayer;
    if (!current.isAi) return;

    final delay = _config.aiMinDelayMs +
        ((_config.aiMaxDelayMs - _config.aiMinDelayMs) *
         (current.id.hashCode % 100) / 100).round();

    Future.delayed(Duration(milliseconds: delay), _executeAiTurn);
  }

  Future<void> _executeAiTurn() async {
    if (!mounted) return;
    if (state.phase != ZhjGamePhase.betting) return;

    final player = state.currentPlayer;
    if (!player.isAi) return;

    final decision = _aiStrategy.decideAction(state, player);

    // 先看牌（如有需要）
    if (decision.shouldPeekFirst) {
      _update(_peekCard.execute(state));
      // 短暂等待后再下注
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || state.phase != ZhjGamePhase.betting) return;
    }

    var s = _betting.execute(state, decision.action);
    s = _nextTurn(s);
    _update(s);
    _scheduleAiTurnIfNeeded();
  }
}
