import 'dart:math';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';
import 'package:poke_game/domain/zhajinhua/usecases/betting_usecase.dart';
import 'package:poke_game/domain/zhajinhua/validators/zhj_card_validator.dart';

/// AI 决策结果
class ZhjAiDecision {
  final BettingAction action;

  /// 是否先看牌（在下注前）
  final bool shouldPeekFirst;

  const ZhjAiDecision({required this.action, this.shouldPeekFirst = false});
}

/// 炸金花 AI 策略
class ZhjAiStrategy {
  final Random _random;

  ZhjAiStrategy({Random? random}) : _random = random ?? Random();

  /// 根据当前游戏状态和当前 AI 玩家决策
  ZhjAiDecision decideAction(ZhjGameState state, ZhjPlayer player) {
    assert(player.isAi, 'ZhjAiStrategy: only for AI players');

    // 1. 蒙牌决策：是否先看牌
    final shouldPeek = _decidePeek(player);
    final effectivePlayer = shouldPeek ? player.copyWith(hasPeeked: true) : player;

    // 2. 评估牌力（仅看牌后才有精确评估，蒙牌时用随机策略）
    final action = effectivePlayer.hasPeeked
        ? _decideWithHandStrength(state, effectivePlayer)
        : _decideBlind(player);

    return ZhjAiDecision(action: action, shouldPeekFirst: shouldPeek && !player.hasPeeked);
  }

  /// 蒙牌决策：激进度高 → 蒙牌概率高；激进度低 → 更倾向看牌
  /// 返回 true 表示"要先看牌"（peek），false 表示"保持蒙牌"
  bool _decidePeek(ZhjPlayer player) {
    if (player.hasPeeked) return false; // 已经看过了

    // 激进度越高，越不想看牌（蒙牌显得更强）
    // aggression=1.0 时蒙牌概率=0.8，即看牌概率=0.2
    // aggression=0.0 时蒙牌概率=0.2，即看牌概率=0.8
    final blindProbability = 0.2 + player.aggression * 0.6;
    return _random.nextDouble() >= blindProbability; // true = 要看牌
  }

  /// 蒙牌时的下注决策（不知道手牌）
  BettingAction _decideBlind(ZhjPlayer player) {
    final r = _random.nextDouble();
    // 激进度越高，越倾向加注
    if (r < player.aggression * 0.3) return BettingAction.raise;
    if (r < 0.7) return BettingAction.call;
    return BettingAction.fold;
  }

  /// 看牌后的下注决策（基于牌力）
  BettingAction _decideWithHandStrength(ZhjGameState state, ZhjPlayer player) {
    if (player.cards.isEmpty) return BettingAction.fold;

    final eval = ZhjCardValidator.evaluate(player.cards);
    final handStrength = _handStrengthScore(eval.rank);

    // 筹码不足时直接弃牌
    final callCost = state.currentBet * 2; // 看牌后跟注倍率×2
    if (player.chips < callCost) {
      return handStrength >= 4 ? BettingAction.call : BettingAction.fold; // 强牌 all-in
    }

    final r = _random.nextDouble();

    return switch (handStrength) {
      >= 5 => // 豹子/同花顺：强烈加注
        r < 0.7 + player.aggression * 0.2 ? BettingAction.raise : BettingAction.call,
      >= 3 => // 同花/顺子：倾向跟注或加注
        r < player.aggression * 0.4 ? BettingAction.raise : BettingAction.call,
      >= 2 => // 对子：跟注为主
        r < 0.3 ? BettingAction.fold : BettingAction.call,
      _ => // 散牌：弃牌概率高
        r < 0.5 + (1.0 - player.aggression) * 0.3 ? BettingAction.fold : BettingAction.call,
    };
  }

  /// 牌力分数 0-5
  int _handStrengthScore(HandRank rank) {
    return switch (rank) {
      HandRank.highCard => 0,
      HandRank.pair => 2,
      HandRank.straight => 3,
      HandRank.flush => 3,
      HandRank.straightFlush => 5,
      HandRank.threeOfAKind => 5,
    };
  }
}
