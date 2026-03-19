import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';

/// 叫地主策略抽象接口
abstract class CallStrategy {
  /// 决定是否叫地主
  Future<CallDecision> decide({required List<Card> handCards});
}

/// 简单叫地主策略
class SimpleCallStrategy implements CallStrategy {
  const SimpleCallStrategy();

  /// 叫地主的手牌强度阈值
  static const int _callThreshold = 10;

  @override
  Future<CallDecision> decide({required List<Card> handCards}) async {
    final strength = _calculateHandStrength(handCards);
    if (strength >= _callThreshold) {
      return const CallDecision.call();
    }
    return const CallDecision.pass();
  }

  /// 计算手牌强度
  int _calculateHandStrength(List<Card> handCards) {
    var strength = 0;

    // 大王 +5
    if (handCards.any((c) => c.isBigJoker)) {
      strength += 5;
    }

    // 小王 +3
    if (handCards.any((c) => c.isSmallJoker)) {
      strength += 3;
    }

    // 2 的数量，每个 +2
    strength += handCards.where((c) => c.rank == 15).length * 2;

    // 炸弹数量，每个 +4
    final rankCounts = <int, int>{};
    for (final card in handCards) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }
    for (final count in rankCounts.values) {
      if (count == 4) {
        strength += 4;
      }
    }

    return strength;
  }
}
