import 'dart:math';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as poker_card;
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';
import 'package:poke_game/domain/texas_holdem/usecases/betting_usecases.dart';
import 'package:poke_game/domain/texas_holdem/ai/strategies/monte_carlo_simulator.dart';

/// AI 决策策略
///
/// 使用蒙特卡洛胜率估算 + 底池赔率，同步返回决策（使用上一次缓存的 equity 或简化估算）。
/// 异步胜率估算在 HoldemGameNotifier 中配合使用。
class HoldemAiStrategy {
  final Random _random;

  HoldemAiStrategy({Random? random}) : _random = random ?? Random();

  /// 同步决策（基于最近估算的胜率）
  BettingAction decide(HoldemGameState state, String playerId) {
    final playerIndex = state.players.indexWhere((p) => p.id == playerId);
    if (playerIndex < 0) return const FoldAction();

    final player = state.players[playerIndex];
    if (!player.canAct) return const FoldAction();

    // 快速估算：仅用底牌点数做粗略判断（无异步模拟时的降级策略）
    final equity = _quickEquityEstimate(player.holeCards, state);
    // 随机扰动 ±15%
    final jitter = (_random.nextDouble() - 0.5) * 0.3;
    final adjustedEquity = (equity + jitter).clamp(0.0, 1.0);

    return _makeDecision(state, player, adjustedEquity);
  }

  /// 基于胜率和底池赔率做出决策
  BettingAction _makeDecision(HoldemGameState state, HoldemPlayer player, double equity) {
    final callAmount = state.currentBet - player.currentBet;
    final potOdds = _potOdds(state.totalPot, callAmount);

    // 短筹码保护：筹码不足最小加注额时考虑 All-in
    if (player.chips <= state.bigBlind * 2) {
      if (equity > 0.35) return const AllInAction();
      return callAmount == 0 ? const CheckAction() : const FoldAction();
    }

    if (equity > 0.65) {
      // 强牌：倾向加注
      final raiseAmount = _calcRaise(state, player);
      return RaiseAction(raiseAmount);
    } else if (equity > 0.35) {
      // 中等牌：参考底池赔率
      if (callAmount == 0) return const CheckAction();
      if (equity > potOdds) return const CallAction();
      return const FoldAction();
    } else {
      // 弱牌：倾向弃牌
      if (callAmount == 0) return const CheckAction();
      return const FoldAction();
    }
  }

  /// 底池赔率：需要多高的胜率才值得跟注
  double _potOdds(int pot, int callAmount) {
    if (callAmount <= 0) return 0.0;
    return callAmount / (pot + callAmount);
  }

  /// 计算建议加注额（约1x底池）
  int _calcRaise(HoldemGameState state, HoldemPlayer player) {
    final pot = state.totalPot;
    final target = state.currentBet + (pot > state.bigBlind ? pot : state.bigBlind);
    final maxBet = player.currentBet + player.chips;
    final minBet = state.currentBet + state.minRaise;
    if (target < minBet) return minBet;
    if (target > maxBet) return maxBet;
    return target;
  }

  /// 快速胜率估算（基于底牌高低，仅用于降级）
  double _quickEquityEstimate(List<poker_card.Card> cards, HoldemGameState state) {
    if (cards.length < 2) return 0.3;
    final r1 = cards[0].rank;
    final r2 = cards[1].rank;
    final isPair = r1 == r2;
    final isSuited = cards[0].suit == cards[1].suit;
    final highCard = max(r1, r2);
    final lowCard = min(r1, r2);

    double base;
    if (isPair) {
      base = 0.5 + (r1 - 2) / 24.0; // 对子：0.50-0.99
    } else {
      // 高牌越大越好
      base = 0.25 + (highCard - 2) / 40.0 + (lowCard - 2) / 80.0;
      if (isSuited) base += 0.05;
      if ((highCard - lowCard) <= 4) base += 0.03; // 连牌加分
    }

    return base.clamp(0.1, 0.9);
  }
}

/// 异步 AI 决策辅助（配合 MonteCarloSimulator 使用）
class AsyncHoldemAiStrategy {
  final HoldemAiStrategy _sync;

  AsyncHoldemAiStrategy() : _sync = HoldemAiStrategy();

  Future<BettingAction> decideAsync(
    HoldemGameState state,
    String playerId, {
    int iterations = 300,
  }) async {
    final player = state.players.firstWhere((p) => p.id == playerId);
    if (!player.canAct) return const FoldAction();

    try {
      final equity = await MonteCarloSimulator.estimateEquity(
        holeCards: player.holeCards,
        communityCards: state.communityCards,
        playerCount: state.activePlayers.length,
        iterations: iterations,
      );

      // 使用 equity 重新决策
      final jitter = (Random().nextDouble() - 0.5) * 0.3;
      final adjusted = (equity + jitter).clamp(0.0, 1.0);
      return _sync._makeDecision(state, player, adjusted);
    } catch (_) {
      // 模拟失败降级到快速估算
      return _sync.decide(state, playerId);
    }
  }
}
