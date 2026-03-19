import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';

void main() {
  group('Card', () {
    test('should create a card with suit and rank', () {
      const card = Card(suit: Suit.heart, rank: 14);

      expect(card.suit, Suit.heart);
      expect(card.rank, 14);
      expect(card.isJoker, false);
      expect(card.isRed, true);
    });

    test('should create small joker', () {
      const card = Card.smallJoker();

      expect(card.rank, 16);
      expect(card.isJoker, true);
      expect(card.isSmallJoker, true);
      expect(card.isBigJoker, false);
    });

    test('should create big joker', () {
      const card = Card.bigJoker();

      expect(card.rank, 17);
      expect(card.isJoker, true);
      expect(card.isBigJoker, true);
      expect(card.isSmallJoker, false);
    });

    test('should return correct display text', () {
      expect(const Card(suit: Suit.spade, rank: 3).displayText, '3');
      expect(const Card(suit: Suit.heart, rank: 11).displayText, 'J');
      expect(const Card(suit: Suit.club, rank: 12).displayText, 'Q');
      expect(const Card(suit: Suit.diamond, rank: 13).displayText, 'K');
      expect(const Card(suit: Suit.spade, rank: 14).displayText, 'A');
      expect(const Card(suit: Suit.heart, rank: 15).displayText, '2');
      expect(const Card.smallJoker().displayText, '小王');
      expect(const Card.bigJoker().displayText, '大王');
    });

    test('should return correct suit symbol', () {
      expect(const Card(suit: Suit.spade, rank: 3).suitSymbol, '♠');
      expect(const Card(suit: Suit.heart, rank: 3).suitSymbol, '♥');
      expect(const Card(suit: Suit.club, rank: 3).suitSymbol, '♣');
      expect(const Card(suit: Suit.diamond, rank: 3).suitSymbol, '♦');
    });

    test('should identify red suits correctly', () {
      expect(const Card(suit: Suit.heart, rank: 3).isRed, true);
      expect(const Card(suit: Suit.diamond, rank: 3).isRed, true);
      expect(const Card(suit: Suit.spade, rank: 3).isRed, false);
      expect(const Card(suit: Suit.club, rank: 3).isRed, false);
      expect(const Card.bigJoker().isRed, true);
      expect(const Card.smallJoker().isRed, false);
    });

    test('should compare cards correctly', () {
      // 大王 > 小王
      expect(const Card.bigJoker().compareTo(const Card.smallJoker()), -1);

      // 王 > 普通牌
      expect(const Card.smallJoker().compareTo(const Card(suit: Suit.spade, rank: 15)), -1);

      // 点数大的排前面
      expect(
        const Card(suit: Suit.spade, rank: 14).compareTo(const Card(suit: Suit.heart, rank: 3)),
        -1,
      );

      // 相同点数按花色排序
      expect(
        const Card(suit: Suit.spade, rank: 3).compareTo(const Card(suit: Suit.heart, rank: 3)),
        -1,
      );
    });

    test('should be equal when suit and rank are the same', () {
      const card1 = Card(suit: Suit.heart, rank: 14);
      const card2 = Card(suit: Suit.heart, rank: 14);
      const card3 = Card(suit: Suit.spade, rank: 14);

      expect(card1, equals(card2));
      expect(card1, isNot(equals(card3)));
    });
  });

  group('createFullDeck', () {
    test('should create 54 cards', () {
      final deck = createFullDeck();
      expect(deck.length, 54);
    });

    test('should contain both jokers', () {
      final deck = createFullDeck();
      expect(deck.any((c) => c.isSmallJoker), true);
      expect(deck.any((c) => c.isBigJoker), true);
    });

    test('should contain all standard cards', () {
      final deck = createFullDeck();

      for (final suit in Suit.values) {
        for (var rank = 3; rank <= 15; rank++) {
          expect(deck.any((c) => c.suit == suit && c.rank == rank), true);
        }
      }
    });
  });
}
