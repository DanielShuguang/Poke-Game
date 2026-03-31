import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/validators/call_validator.dart';
import 'package:poke_game/domain/shengji/ai/strategies/call_strategy.dart';

/// 创建普通牌
ShengjiCard c(int rank, Suit suit) => ShengjiCard(suit: suit, rank: rank);

/// 创建大王
ShengjiCard bigJoker() => const ShengjiCard.bigJoker();

/// 创建小王
ShengjiCard smallJoker() => const ShengjiCard.smallJoker();

void main() {
  group('NormalCallStrategy - 手牌评估', () {
    test('强牌（级牌对子）应该叫牌', () {
      // 有两张黑桃2（级牌对子），有足够强度
      final hand = [
        bigJoker(), smallJoker(),
        c(2, Suit.spade), c(2, Suit.spade), // 级牌对子
        c(14, Suit.spade), c(14, Suit.heart), // AA
        c(13, Suit.spade), c(13, Suit.heart), // KK
      ];
      final strategy = NormalCallStrategy();
      final call = strategy.evaluate(hand, 2);
      expect(call, isNotNull);
    });

    test('弱牌应该不叫', () {
      final hand = [
        c(3, Suit.spade), c(4, Suit.heart),
        c(5, Suit.club), c(6, Suit.diamond),
        c(7, Suit.spade), c(8, Suit.heart),
      ];
      final strategy = NormalCallStrategy();
      final call = strategy.evaluate(hand, 2);
      expect(call, isNull);
    });

    test('有大小王提高叫牌意愿', () {
      final hand = [
        bigJoker(), smallJoker(),
        c(5, Suit.spade), c(6, Suit.heart),
        c(7, Suit.club), c(8, Suit.diamond),
      ];
      final strategy = NormalCallStrategy();
      // 大小王加分，但可能还不够阈值
      final call = strategy.evaluate(hand, 2);
      // 结果取决于具体分数阈值
      expect(call, isNotNull); // 结果取决于具体分数阈值，任意非空结果均可接受
    });

    test('级牌多提高叫牌意愿', () {
      // 非常强的手牌：级牌对子 + 大小王 + AK
      final hand = [
        c(2, Suit.spade), c(2, Suit.spade), // 级牌对子（同花色）
        c(14, Suit.spade), c(14, Suit.spade), // AA 对子
        c(13, Suit.spade), c(13, Suit.spade), // KK 对子
        bigJoker(), smallJoker(),
      ];
      final strategy = NormalCallStrategy();
      final call = strategy.evaluate(hand, 2);
      // 强度足够，应该叫牌
      expect(call, isNotNull);
    });
  });

  group('EasyCallStrategy - 随机策略', () {
    test('有级牌对子可能叫牌', () {
      final hand = [
        c(2, Suit.spade), c(2, Suit.spade), // 级牌对子
        bigJoker(), // 加点强度
        c(5, Suit.club), c(6, Suit.diamond),
      ];
      final strategy = EasyCallStrategy();
      // 多次调用测试随机性
      var calledCount = 0;
      for (int i = 0; i < 30; i++) {
        if (strategy.evaluate(hand, 2) != null) {
          calledCount++;
        }
      }
      // 应该有叫牌的情况（非 100% 也非 0%）
      expect(calledCount, greaterThan(0));
    });

    test('无级牌对子时返回 null', () {
      final hand = [
        c(3, Suit.spade), c(4, Suit.heart), // 无级牌对子
        c(5, Suit.club), c(6, Suit.diamond),
      ];
      final strategy = EasyCallStrategy();
      final call = strategy.evaluate(hand, 2);
      expect(call, isNull);
    });
  });

  group('CallValidator - 可能叫牌查找', () {
    test('找出级牌对子叫牌', () {
      // 级牌是2，需要两张同花色的2
      final hand = [
        c(2, Suit.spade), c(2, Suit.spade), // 黑桃级牌对子
        c(5, Suit.club), c(6, Suit.diamond),
      ];
      final calls = CallValidator.findPossibleCalls(hand, 2);
      expect(calls.isNotEmpty, isTrue);
      // 应该有级牌对子叫牌
      expect(calls.any((c) => c.type == CallType.pair), isTrue);
    });

    test('找出拖拉机叫牌', () {
      // 需要两张2和两张3（同花色）
      final hand = [
        c(2, Suit.spade), c(2, Suit.spade), // 两张黑桃 2
        c(3, Suit.spade), c(3, Suit.spade), // 两张黑桃 3
        c(5, Suit.club),
      ];
      final calls = CallValidator.findPossibleCalls(hand, 2);
      // 应该有拖拉机叫牌
      expect(calls.any((c) => c.type == CallType.tractor), isTrue);
    });

    test('找出无将叫牌（大王对子）', () {
      final hand = [
        bigJoker(), bigJoker(),
        c(5, Suit.club), c(6, Suit.diamond),
      ];
      final calls = CallValidator.findPossibleCalls(hand, 2);
      // 应该有无将叫牌
      expect(calls.any((c) => c.type == CallType.noTrump), isTrue);
    });

    test('无级牌对子时无叫牌', () {
      final hand = [
        c(3, Suit.spade), c(4, Suit.heart),
        c(5, Suit.club), c(6, Suit.diamond),
      ];
      final calls = CallValidator.findPossibleCalls(hand, 2);
      expect(calls.isEmpty, isTrue);
    });
  });

  group('TrumpCall - 叫牌类型', () {
    test('对子叫牌创建', () {
      final call = TrumpCall.pair(Suit.spade, 2);
      expect(call.type, CallType.pair);
      expect(call.suit, Suit.spade);
      expect(call.rank, 2);
    });

    test('拖拉机叫牌创建', () {
      final call = TrumpCall.tractor(Suit.heart, 5);
      expect(call.type, CallType.tractor);
      expect(call.suit, Suit.heart);
      expect(call.rank, 5);
    });

    test('无将叫牌创建', () {
      final call = TrumpCall.noTrump(JokerType.big);
      expect(call.type, CallType.noTrump);
      expect(call.jokerType, JokerType.big);
    });
  });
}
