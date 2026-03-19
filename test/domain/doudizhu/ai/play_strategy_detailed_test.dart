import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/ai/strategies/play_strategy.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';

void main() {
  late SimplePlayStrategy strategy;
  late CardValidator validator;

  setUp(() {
    strategy = const SimplePlayStrategy();
    validator = const CardValidator();
  });

  group('SimplePlayStrategy - pass scenario', () {
    test('second AI should find correct straight after first AI passes', () async {
      // 上家出的顺子 3-7
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
      ];

      // 第二个 AI 的手牌（有更大的顺子 5-9）
      final handCards = [
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 6),
        const Card(suit: Suit.club, rank: 7),
        const Card(suit: Suit.diamond, rank: 8),
        const Card(suit: Suit.heart, rank: 9),
        const Card(suit: Suit.spade, rank: 10),
        const Card(suit: Suit.club, rank: 11),
      ]..sort(); // 确保排序

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 5);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.straight);

      // 验证能打过上家
      expect(validator.canBeat(decision.cards!, lastPlayed), true);
    });

    test('second AI should pass when no bigger straight and no bomb', () async {
      // 上家出的顺子 10-A
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 10),
        const Card(suit: Suit.spade, rank: 11),
        const Card(suit: Suit.club, rank: 12),
        const Card(suit: Suit.diamond, rank: 13),
        const Card(suit: Suit.heart, rank: 14),
      ];

      // 第二个 AI 的手牌（没有更大的顺子，也没有炸弹）
      final handCards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
        const Card(suit: Suit.spade, rank: 8),
        const Card(suit: Suit.club, rank: 9),
      ]..sort();

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      // 没有更大的顺子，也没有炸弹，应该过牌
      expect(decision.shouldPlay, false);
    });

    test('AI should correctly identify straight vs single', () async {
      // 上家出的顺子 3-7
      final straightPlayed = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
      ];

      // AI 手牌只有单张大牌（没有顺子）
      final handCards = [
        const Card(suit: Suit.heart, rank: 14), // A
        const Card(suit: Suit.spade, rank: 13), // K
      ]..sort();

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: straightPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      // 应该过牌（不能拿单张打顺子）
      expect(decision.shouldPlay, false);
    });

    test('AI should not play wrong card type against straight', () async {
      // 上家出的顺子 5-9
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 6),
        const Card(suit: Suit.club, rank: 7),
        const Card(suit: Suit.diamond, rank: 8),
        const Card(suit: Suit.heart, rank: 9),
      ];

      // AI 手牌有对子但没有更大的顺子
      final handCards = [
        const Card(suit: Suit.heart, rank: 10),
        const Card(suit: Suit.spade, rank: 10), // 对子 10
        const Card(suit: Suit.club, rank: 11),
        const Card(suit: Suit.diamond, rank: 13),
      ]..sort();

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      // 应该过牌（对子不能打顺子）
      expect(decision.shouldPlay, false);
    });
  });

  group('SimplePlayStrategy - unsorted hand cards', () {
    test('should work with unsorted hand cards', () async {
      // 上家出的顺子 3-7
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
      ];

      // 手牌故意不排序
      final unsortedHandCards = [
        const Card(suit: Suit.heart, rank: 9),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 7),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 8),
      ];

      final decision = await strategy.decide(
        handCards: unsortedHandCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 5);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.straight);
    });
  });

  group('SimplePlayStrategy - new round', () {
    test('should play smallest single when starting new round', () async {
      // 新一轮，lastPlayedCards 为 null
      final handCards = [
        const Card(suit: Suit.heart, rank: 14), // A
        const Card(suit: Suit.spade, rank: 10),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 3),
      ]..sort(); // 排序后: A, 10, 5, 3 (从大到小)

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: null,
        lastPlayerIndex: null,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 1);
      // 应该打最小的牌（排序后最后一张）
      expect(decision.cards?.first.rank, 3);
    });

    test('should play straight when starting new round with straight', () async {
      // 手牌有顺子 3-7
      final handCards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
        const Card(suit: Suit.spade, rank: 10),
        const Card(suit: Suit.club, rank: 14), // A
      ]..sort();

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: null,
        lastPlayerIndex: null,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 5);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.straight);
      // 顺子应该从3开始
      final ranks = decision.cards!.map((c) => c.rank).toList()..sort();
      expect(ranks.first, 3);
    });

    test('should play pair straight when starting new round', () async {
      // 手牌有连对 3-3, 4-4, 5-5
      final handCards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.heart, rank: 4),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 10),
      ]..sort();

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: null,
        lastPlayerIndex: null,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 6);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.pairStraight);
    });

    test('should play triple with pair when starting new round', () async {
      // 手牌有三张和一对
      final handCards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 3),
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 10),
      ]..sort();

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: null,
        lastPlayerIndex: null,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 5);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.tripleWithPair);
    });

    test('should play pair when no better combination', () async {
      // 手牌只有对子和单张，没有顺子/连对/三张
      final handCards = [
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 10),
        const Card(suit: Suit.diamond, rank: 14), // A
      ]..sort();

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: null,
        lastPlayerIndex: null,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 2);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.pair);
      // 应该打最小的对子
      expect(decision.cards!.first.rank, 5);
    });
  });
}
