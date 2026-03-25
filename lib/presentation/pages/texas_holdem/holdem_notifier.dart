import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';
import 'package:poke_game/domain/texas_holdem/usecases/betting_usecases.dart';
import 'package:poke_game/domain/texas_holdem/ai/strategies/holdem_ai_strategy.dart';

/// 德州扑克状态管理 Notifier
class HoldemGameNotifier extends StateNotifier<HoldemGameState> {
  final DealCardsUsecase _dealCards;
  final BettingRoundUsecase _betting;
  final PhaseAdvanceUsecase _advance;
  final ShowdownUsecase _showdown;
  final AdvanceDealerUsecase _advanceDealer;
  final HoldemAiStrategy _aiStrategy;

  Timer? _timeoutTimer;

  HoldemGameNotifier({
    required List<HoldemPlayer> players,
    int smallBlind = 10,
    int bigBlind = 20,
    bool isAiMode = true,
    String? humanPlayerId,
    DealCardsUsecase? dealCards,
    BettingRoundUsecase? betting,
    PhaseAdvanceUsecase? advance,
    ShowdownUsecase? showdown,
    AdvanceDealerUsecase? advanceDealer,
    HoldemAiStrategy? aiStrategy,
  })  : _dealCards = dealCards ?? DealCardsUsecase(),
        _betting = betting ?? BettingRoundUsecase(),
        _advance = advance ?? PhaseAdvanceUsecase(),
        _showdown = showdown ?? ShowdownUsecase(),
        _advanceDealer = advanceDealer ?? AdvanceDealerUsecase(),
        _aiStrategy = aiStrategy ?? HoldemAiStrategy(),
        super(
          HoldemGameState.initial(
            players: players,
            smallBlind: smallBlind,
            bigBlind: bigBlind,
            isAiMode: isAiMode,
            humanPlayerId: humanPlayerId,
          ),
        );

  /// 开始新局
  void startGame() {
    _cancelTimer();
    final newState = _dealCards.execute(state);
    state = newState;
    _scheduleNextAction();
  }

  /// 弃牌
  void fold() => _applyAction(const FoldAction());

  /// 过牌
  void check() => _applyAction(const CheckAction());

  /// 跟注
  void call() => _applyAction(const CallAction());

  /// 加注
  void raise(int totalBet) => _applyAction(RaiseAction(totalBet));

  /// All-in
  void allIn() => _applyAction(const AllInAction());

  void _applyAction(BettingAction action) {
    _cancelTimer();

    // 行动权限验证
    final current = state.currentPlayer;
    if (current == null) return;
    if (state.isAiMode &&
        state.humanPlayerId != null &&
        current.id != state.humanPlayerId) {
      throw StateError('当前不是人类玩家的回合');
    }

    try {
      var newState = _betting.execute(state, action);

      if (BettingRoundUsecase.isRoundComplete(newState)) {
        newState = _handleRoundEnd(newState);
      }

      state = newState;
      _scheduleNextAction();
    } catch (e) {
      // 无效操作不更新状态
      rethrow;
    }
  }

  HoldemGameState _handleRoundEnd(HoldemGameState s) {
    // 仅剩一名活跃玩家，直接结算
    if (s.activePlayers.length == 1) {
      return _showdown.execute(s);
    }
    // River 结束后摊牌
    if (s.phase == GamePhase.river) {
      return _showdown.execute(s);
    }
    // 其他阶段推进
    return _advance.advance(s);
  }

  /// 安排下一步行动（AI 自动行动 or 超时计时器）
  void _scheduleNextAction() {
    if (state.phase == GamePhase.finished ||
        state.phase == GamePhase.waiting ||
        state.phase == GamePhase.showdown) {
      return;
    }

    final current = state.currentPlayer;
    if (current == null) return;

    final isHumanTurn =
        !state.isAiMode || current.id == state.humanPlayerId;

    if (!isHumanTurn) {
      // AI 行动：延迟 500-2000ms
      final delay = Duration(
        milliseconds: 500 + (DateTime.now().millisecondsSinceEpoch % 1500),
      );
      _timeoutTimer = Timer(delay, _triggerAiAction);
    } else {
      // 人类玩家：30秒超时
      _timeoutTimer = Timer(const Duration(seconds: 30), _triggerTimeout);
    }
  }

  void _triggerAiAction() {
    final current = state.currentPlayer;
    if (current == null || !current.canAct) return;

    final action = _aiStrategy.decide(state, current.id);
    _cancelTimer();

    try {
      var newState = _betting.execute(state, action);
      if (BettingRoundUsecase.isRoundComplete(newState)) {
        newState = _handleRoundEnd(newState);
      }
      state = newState;
      _scheduleNextAction();
    } catch (_) {
      // AI 决策出错时保守 fold
      _applyFallbackAction();
    }
  }

  void _triggerTimeout() {
    final current = state.currentPlayer;
    if (current == null) return;
    // 可以 check 则 check，否则 fold
    if (current.currentBet >= state.currentBet) {
      _applyAction(const CheckAction());
    } else {
      _applyAction(const FoldAction());
    }
  }

  void _applyFallbackAction() {
    try {
      _applyAction(const FoldAction());
    } catch (_) {}
  }

  void _cancelTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// 开始下一局（轮转庄家）
  void nextRound() {
    _cancelTimer();
    final rotated = _advanceDealer.execute(state);
    final newState = _dealCards.execute(rotated);
    state = newState;
    _scheduleNextAction();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  /// 暴露当前状态（供网络层等外部使用）
  HoldemGameState get currentState => state;
}
