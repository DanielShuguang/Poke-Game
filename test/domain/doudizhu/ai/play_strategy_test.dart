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

  group('SimplePlayStrategy - straight', () {
    test('should find higher straight', () async {
      // 上家顺子 3-7
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
      ];

      // AI 手牌有 4-8 的顺子
      final handCards = [
        const Card(suit: Suit.heart, rank: 4),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 6),
        const Card(suit: Suit.diamond, rank: 7),
        const Card(suit: Suit.heart, rank: 8),
        const Card(suit: Suit.spade, rank: 10),
      ];

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 5);
      // 验证是顺子
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.straight);
    });

    test('should pass when no higher straight available', () async {
      // 上家顺子 10-A
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 10),
        const Card(suit: Suit.spade, rank: 11),
        const Card(suit: Suit.club, rank: 12),
        const Card(suit: Suit.diamond, rank: 13),
        const Card(suit: Suit.heart, rank: 14),
      ];

      // AI 手牌只有小牌
      final handCards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
      ];

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      expect(decision.shouldPlay, false);
    });
  });

  group('SimplePlayStrategy - triple with single', () {
    test('should find higher triple with single', () async {
      // 上家三带一 333+4
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 3),
        const Card(suit: Suit.diamond, rank: 4),
      ];

      // AI 手牌有 555+6
      final handCards = [
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
      ];

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 4);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.tripleWithSingle);
    });
  });

  group('SimplePlayStrategy - triple with pair', () {
    test('should find higher triple with pair', () async {
      // 上家三带二 333+44
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 3),
        const Card(suit: Suit.diamond, rank: 4),
        const Card(suit: Suit.heart, rank: 4),
      ];

      // AI 手牌有 555+66
      final handCards = [
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 6),
      ];

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 5);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.tripleWithPair);
    });
  });

  group('SimplePlayStrategy - pair straight', () {
    test('should find higher pair straight', () async {
      // 上家连对 33-44-55
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 4),
        const Card(suit: Suit.diamond, rank: 4),
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
      ];

      // AI 手牌有 44-55-66
      final handCards = [
        const Card(suit: Suit.heart, rank: 4),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 5),
        const Card(suit: Suit.heart, rank: 6),
        const Card(suit: Suit.spade, rank: 6),
      ];

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 6);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.pairStraight);
    });
  });

  group('SimplePlayStrategy - plane', () {
    test('should find higher plane', () async {
      // 上家飞机不带 333-444
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 3),
        const Card(suit: Suit.diamond, rank: 4),
        const Card(suit: Suit.heart, rank: 4),
        const Card(suit: Suit.spade, rank: 4),
      ];

      // AI 手牌有 555-666
      final handCards = [
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 6),
        const Card(suit: Suit.spade, rank: 6),
      ];

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 6);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.plane);
    });
  });

  group('SimplePlayStrategy - bomb', () {
    test('should play bomb to beat other combinations', () async {
      // 上家顺子
      final lastPlayed = [
        const Card(suit: Suit.heart, rank: 10),
        const Card(suit: Suit.spade, rank: 11),
        const Card(suit: Suit.club, rank: 12),
        const Card(suit: Suit.diamond, rank: 13),
        const Card(suit: Suit.heart, rank: 14),
      ];

      // AI 手牌有炸弹
      final handCards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 3),
        const Card(suit: Suit.diamond, rank: 3),
      ];

      final decision = await strategy.decide(
        handCards: handCards,
        lastPlayedCards: lastPlayed,
        lastPlayerIndex: 0,
        validator: validator,
      );

      expect(decision.shouldPlay, true);
      expect(decision.cards?.length, 4);
      final combination = validator.validate(decision.cards!);
      expect(combination, CardCombination.bomb);
    });
  });
}
