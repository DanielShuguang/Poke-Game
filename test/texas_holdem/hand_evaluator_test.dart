import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/texas_holdem/validators/hand_evaluator.dart';

/// 便捷创建牌的辅助函数
Card c(int rank, Suit suit) => Card(suit: suit, rank: rank);

void main() {
  group('HandEvaluator', () {
    group('牌型识别', () {
      test('皇家同花顺', () {
        final cards = [
          c(14, Suit.spade), c(13, Suit.spade), c(12, Suit.spade),
          c(11, Suit.spade), c(10, Suit.spade), c(2, Suit.heart), c(3, Suit.diamond),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.royalFlush);
      });

      test('同花顺（非皇家）', () {
        final cards = [
          c(9, Suit.heart), c(8, Suit.heart), c(7, Suit.heart),
          c(6, Suit.heart), c(5, Suit.heart), c(2, Suit.spade), c(3, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.straightFlush);
      });

      test('A低顺同花顺（A-2-3-4-5 同花）', () {
        final cards = [
          c(14, Suit.club), c(2, Suit.club), c(3, Suit.club),
          c(4, Suit.club), c(5, Suit.club), c(9, Suit.heart), c(10, Suit.diamond),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.straightFlush);
      });

      test('四条', () {
        final cards = [
          c(8, Suit.spade), c(8, Suit.heart), c(8, Suit.club),
          c(8, Suit.diamond), c(5, Suit.spade), c(2, Suit.heart), c(3, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.fourOfAKind);
      });

      test('葫芦', () {
        final cards = [
          c(7, Suit.spade), c(7, Suit.heart), c(7, Suit.club),
          c(4, Suit.spade), c(4, Suit.heart), c(2, Suit.club), c(3, Suit.diamond),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.fullHouse);
      });

      test('同花', () {
        final cards = [
          c(14, Suit.diamond), c(10, Suit.diamond), c(7, Suit.diamond),
          c(4, Suit.diamond), c(2, Suit.diamond), c(3, Suit.spade), c(5, Suit.heart),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.flush);
      });

      test('顺子', () {
        final cards = [
          c(9, Suit.spade), c(8, Suit.heart), c(7, Suit.club),
          c(6, Suit.diamond), c(5, Suit.spade), c(2, Suit.heart), c(3, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.straight);
      });

      test('A高顺（10-J-Q-K-A）', () {
        final cards = [
          c(14, Suit.spade), c(13, Suit.heart), c(12, Suit.club),
          c(11, Suit.diamond), c(10, Suit.spade), c(2, Suit.heart), c(3, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.straight);
      });

      test('A低顺（A-2-3-4-5）', () {
        final cards = [
          c(14, Suit.spade), c(2, Suit.heart), c(3, Suit.club),
          c(4, Suit.diamond), c(5, Suit.spade), c(9, Suit.heart), c(10, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.straight);
      });

      test('三条', () {
        final cards = [
          c(6, Suit.spade), c(6, Suit.heart), c(6, Suit.club),
          c(2, Suit.diamond), c(4, Suit.spade), c(9, Suit.heart), c(10, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.threeOfAKind);
      });

      test('两对', () {
        final cards = [
          c(10, Suit.spade), c(10, Suit.heart), c(7, Suit.club),
          c(7, Suit.diamond), c(2, Suit.spade), c(4, Suit.heart), c(6, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.twoPair);
      });

      test('一对', () {
        final cards = [
          c(9, Suit.spade), c(9, Suit.heart), c(3, Suit.club),
          c(5, Suit.diamond), c(7, Suit.spade), c(2, Suit.heart), c(4, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.onePair);
      });

      test('高牌', () {
        // 避免 A,2,3,4,5 组成低顺，用 A,K,9,6,3,2,8 （无法凑出5张连续牌）
        final cards = [
          c(14, Suit.spade), c(13, Suit.heart), c(9, Suit.club),
          c(6, Suit.diamond), c(3, Suit.spade), c(2, Suit.heart), c(8, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.highCard);
      });

      test('同花顺优于顺子', () {
        // 包含顺子和同花顺的7张牌
        final cards = [
          c(9, Suit.heart), c(8, Suit.heart), c(7, Suit.heart),
          c(6, Suit.heart), c(5, Suit.heart), c(10, Suit.spade), c(4, Suit.club),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.handRank, HandRank.straightFlush);
      });
    });

    group('踢脚牌比较', () {
      test('同为一对，点数大的赢', () {
        final aces = [
          c(14, Suit.spade), c(14, Suit.heart), c(2, Suit.club),
          c(3, Suit.diamond), c(4, Suit.spade), c(6, Suit.heart), c(8, Suit.club),
        ];
        final kings = [
          c(13, Suit.spade), c(13, Suit.heart), c(2, Suit.club),
          c(3, Suit.diamond), c(4, Suit.spade), c(6, Suit.heart), c(8, Suit.club),
        ];
        final aceResult = HandEvaluator.evaluate(aces);
        final kingResult = HandEvaluator.evaluate(kings);
        expect(aceResult.score, greaterThan(kingResult.score));
      });

      test('同为两对，高对更高的赢', () {
        final highTwo = [
          c(14, Suit.spade), c(14, Suit.heart), c(13, Suit.club),
          c(13, Suit.diamond), c(2, Suit.spade), c(3, Suit.heart), c(4, Suit.club),
        ];
        final lowTwo = [
          c(10, Suit.spade), c(10, Suit.heart), c(9, Suit.club),
          c(9, Suit.diamond), c(2, Suit.spade), c(3, Suit.heart), c(4, Suit.club),
        ];
        final highResult = HandEvaluator.evaluate(highTwo);
        final lowResult = HandEvaluator.evaluate(lowTwo);
        expect(highResult.score, greaterThan(lowResult.score));
      });

      test('同为高牌，踢脚牌决胜', () {
        final higher = [
          c(14, Suit.spade), c(13, Suit.heart), c(9, Suit.club),
          c(8, Suit.diamond), c(3, Suit.spade), c(2, Suit.heart), c(6, Suit.club),
        ];
        final lower = [
          c(14, Suit.spade), c(13, Suit.heart), c(7, Suit.club),
          c(8, Suit.diamond), c(3, Suit.spade), c(2, Suit.heart), c(6, Suit.club),
        ];
        final highResult = HandEvaluator.evaluate(higher);
        final lowResult = HandEvaluator.evaluate(lower);
        expect(highResult.score, greaterThan(lowResult.score));
      });

      test('完全相同的5张牌（平局）', () {
        final hand1 = [
          c(14, Suit.spade), c(13, Suit.heart), c(12, Suit.club),
          c(11, Suit.diamond), c(10, Suit.spade), c(2, Suit.heart), c(3, Suit.club),
        ];
        final hand2 = [
          c(14, Suit.heart), c(13, Suit.diamond), c(12, Suit.spade),
          c(11, Suit.club), c(10, Suit.heart), c(4, Suit.spade), c(5, Suit.diamond),
        ];
        final result1 = HandEvaluator.evaluate(hand1);
        final result2 = HandEvaluator.evaluate(hand2);
        expect(result1.score, equals(result2.score));
      });
    });
  });
}
