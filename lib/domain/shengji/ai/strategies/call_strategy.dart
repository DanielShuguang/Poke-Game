import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/validators/call_validator.dart';

/// 叫牌策略接口
abstract class CallStrategy {
  /// 评估是否叫牌
  TrumpCall? evaluate(List<ShengjiCard> hand, int currentLevel);
}

/// 简单叫牌策略（随机）
class EasyCallStrategy implements CallStrategy {
  @override
  TrumpCall? evaluate(List<ShengjiCard> hand, int currentLevel) {
    // 找出所有可能的叫牌
    final possibleCalls = CallValidator.findPossibleCalls(hand, currentLevel);
    if (possibleCalls.isEmpty) return null;

    // 随机决定是否叫牌
    if (DateTime.now().millisecond % 3 == 0) {
      return null; // 有 1/3 概率不叫
    }

    return possibleCalls.first;
  }
}

/// 普通叫牌策略（基于手牌评估）
class NormalCallStrategy implements CallStrategy {
  @override
  TrumpCall? evaluate(List<ShengjiCard> hand, int currentLevel) {
    // 评估手牌强度
    final strength = _evaluateHandStrength(hand, currentLevel);

    // 强度不够则不叫
    if (strength < 0.4) return null;

    // 找出所有可能的叫牌
    final possibleCalls = CallValidator.findPossibleCalls(hand, currentLevel);
    if (possibleCalls.isEmpty) return null;

    // 选择最高优先级的叫牌
    possibleCalls.sort((a, b) => CallValidator.compare(a, b));
    return possibleCalls.last;
  }

  /// 评估手牌强度（0.0 - 1.0）
  double _evaluateHandStrength(List<ShengjiCard> hand, int currentLevel) {
    double score = 0.0;

    for (final card in hand) {
      // 大小王加分
      if (card.isBigJoker) score += 0.08;
      if (card.isSmallJoker) score += 0.06;

      // 级牌加分
      if (card.rank == currentLevel) score += 0.04;

      // A、K 加分
      if (card.rank == 14) score += 0.03;
      if (card.rank == 13) score += 0.02;
    }

    // 对子加分
    final rankCounts = <int?, int>{};
    for (final card in hand) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }
    for (final count in rankCounts.values) {
      if (count >= 2) score += 0.02;
      if (count >= 4) score += 0.03; // 两副牌可能有 4 张
    }

    return score.clamp(0.0, 1.0);
  }
}
