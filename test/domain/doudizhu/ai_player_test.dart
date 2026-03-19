import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/ai/ai_player.dart';
import 'package:poke_game/domain/doudizhu/ai/strategies/call_strategy.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';

void main() {
  group('SimpleCallStrategy', () {
    late SimpleCallStrategy strategy;

    setUp(() {
      strategy = const SimpleCallStrategy();
    });

    test('should call with strong hand (big joker)', () async {
      final handCards = [
        const Card.bigJoker(),
        const Card(suit: Suit.heart, rank: 15),
        const Card(suit: Suit.spade, rank: 15),
        ...createStandardDeck().take(14),
      ];

      final decision = await strategy.decide(handCards: handCards);
      expect(decision.shouldCall, true);
    });

    test('should call with bomb', () async {
      // 需要达到阈值10才能叫地主: 大王+5, 炸弹+4 = 9, 还需要+1
      final handCards = [
        const Card.bigJoker(), // +5
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
        const Card(suit: Suit.club, rank: 14),
        const Card(suit: Suit.diamond, rank: 14), // +4 bomb
        const Card(suit: Suit.heart, rank: 15), // +2 for 2
        ...createStandardDeck().take(11),
      ];

      final decision = await strategy.decide(handCards: handCards);
      expect(decision.shouldCall, true);
    });

    test('should pass with weak hand', () async {
      final handCards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 4),
        const Card(suit: Suit.diamond, rank: 4),
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 6),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
        const Card(suit: Suit.spade, rank: 7),
        const Card(suit: Suit.club, rank: 8),
        const Card(suit: Suit.diamond, rank: 8),
        const Card(suit: Suit.heart, rank: 9),
        const Card(suit: Suit.spade, rank: 9),
        const Card(suit: Suit.club, rank: 10),
        const Card(suit: Suit.diamond, rank: 10),
        const Card(suit: Suit.heart, rank: 11),
      ];

      final decision = await strategy.decide(handCards: handCards);
      expect(decision.shouldCall, false);
    });
  });

  group('AiPlayer', () {
    test('should create AI player with correct properties', () {
      final ai = AiPlayer(
        id: 'test-ai',
        name: 'Test AI',
      );

      expect(ai.id, 'test-ai');
      expect(ai.name, 'Test AI');
      expect(ai.handCards, isEmpty);
      expect(ai.role, isNull);
    });

    test('should have think delay for decision', () async {
      final ai = AiPlayer(
        id: 'test-ai',
        name: 'Test AI',
        thinkDelayMs: 100,
      );

      ai.handCards = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
      ];

      final stopwatch = Stopwatch()..start();
      await ai.decideCall();
      stopwatch.stop();

      // Should have at least 100ms delay
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });
  });
}
