import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';

void main() {
  late CardValidator validator;

  setUp(() {
    validator = const CardValidator();
  });

  group('CardValidator - single', () {
    test('should validate single card', () {
      final cards = [const Card(suit: Suit.heart, rank: 14)];
      expect(validator.validate(cards), CardCombination.single);
    });
  });

  group('CardValidator - pair', () {
    test('should validate pair', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
      ];
      expect(validator.validate(cards), CardCombination.pair);
    });

    test('should not validate different ranks as pair', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 13),
      ];
      expect(validator.validate(cards), isNull);
    });
  });

  group('CardValidator - triple', () {
    test('should validate triple', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
        const Card(suit: Suit.club, rank: 14),
      ];
      expect(validator.validate(cards), CardCombination.triple);
    });
  });

  group('CardValidator - triple with single', () {
    test('should validate triple with single (三带一)', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
        const Card(suit: Suit.club, rank: 14),
        const Card(suit: Suit.diamond, rank: 3),
      ];
      expect(validator.validate(cards), CardCombination.tripleWithSingle);
    });
  });

  group('CardValidator - triple with pair', () {
    test('should validate triple with pair (三带二)', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
        const Card(suit: Suit.club, rank: 14),
        const Card(suit: Suit.diamond, rank: 3),
        const Card(suit: Suit.heart, rank: 3),
      ];
      expect(validator.validate(cards), CardCombination.tripleWithPair);
    });
  });

  group('CardValidator - straight', () {
    test('should validate straight with 5 cards', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
      ]..sort(); // Sort cards first
      expect(validator.validate(cards), CardCombination.straight);
    });

    test('should validate straight with 12 cards (3 to A)', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
        const Card(suit: Suit.spade, rank: 8),
        const Card(suit: Suit.club, rank: 9),
        const Card(suit: Suit.diamond, rank: 10),
        const Card(suit: Suit.heart, rank: 11),
        const Card(suit: Suit.spade, rank: 12),
        const Card(suit: Suit.club, rank: 13),
        const Card(suit: Suit.diamond, rank: 14),
      ]..sort(); // Sort cards first
      expect(validator.validate(cards), CardCombination.straight);
    });

    test('should not validate straight containing 2', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 13),
        const Card(suit: Suit.spade, rank: 14),
        const Card(suit: Suit.club, rank: 15),
        const Card(suit: Suit.diamond, rank: 3),
        const Card(suit: Suit.heart, rank: 4),
      ];
      expect(validator.validate(cards), isNull);
    });

    test('should not validate non-consecutive cards as straight', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 6),
        const Card(suit: Suit.diamond, rank: 7),
        const Card(suit: Suit.heart, rank: 8),
      ];
      expect(validator.validate(cards), isNull);
    });
  });

  group('CardValidator - pair straight', () {
    test('should validate pair straight with 3 pairs', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 4),
        const Card(suit: Suit.diamond, rank: 4),
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
      ];
      expect(validator.validate(cards), CardCombination.pairStraight);
    });
  });

  group('CardValidator - bomb', () {
    test('should validate bomb', () {
      final cards = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
        const Card(suit: Suit.club, rank: 14),
        const Card(suit: Suit.diamond, rank: 14),
      ];
      expect(validator.validate(cards), CardCombination.bomb);
    });
  });

  group('CardValidator - rocket', () {
    test('should validate rocket (王炸)', () {
      final cards = [
        const Card.smallJoker(),
        const Card.bigJoker(),
      ];
      expect(validator.validate(cards), CardCombination.rocket);
    });
  });

  group('CardValidator - canBeat', () {
    test('rocket beats everything', () {
      final rocket = [const Card.smallJoker(), const Card.bigJoker()];
      final bomb = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
        const Card(suit: Suit.club, rank: 14),
        const Card(suit: Suit.diamond, rank: 14),
      ];

      expect(validator.canBeat(rocket, bomb), true);
    });

    test('bomb beats non-bomb', () {
      final bomb = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 3),
        const Card(suit: Suit.diamond, rank: 3),
      ];
      final triple = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
        const Card(suit: Suit.club, rank: 14),
      ];

      expect(validator.canBeat(bomb, triple), true);
    });

    test('higher single beats lower single', () {
      final higher = [const Card(suit: Suit.heart, rank: 14)];
      final lower = [const Card(suit: Suit.spade, rank: 13)];

      expect(validator.canBeat(higher, lower), true);
      expect(validator.canBeat(lower, higher), false);
    });

    test('higher pair beats lower pair', () {
      final higher = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
      ];
      final lower = [
        const Card(suit: Suit.heart, rank: 13),
        const Card(suit: Suit.spade, rank: 13),
      ];

      expect(validator.canBeat(higher, lower), true);
    });

    test('different card counts cannot beat', () {
      final pair = [
        const Card(suit: Suit.heart, rank: 14),
        const Card(suit: Suit.spade, rank: 14),
      ];
      final triple = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 3),
      ];

      expect(validator.canBeat(pair, triple), false);
      expect(validator.canBeat(triple, pair), false);
    });

    test('higher straight beats lower straight', () {
      // 顺子 3-7
      final lower = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
      ]..sort();
      // 顺子 5-9
      final higher = [
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 6),
        const Card(suit: Suit.club, rank: 7),
        const Card(suit: Suit.diamond, rank: 8),
        const Card(suit: Suit.heart, rank: 9),
      ]..sort();

      expect(validator.canBeat(higher, lower), true);
      expect(validator.canBeat(lower, higher), false);
    });

    test('higher pair straight beats lower pair straight', () {
      // 连对 33-44-55
      final lower = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 4),
        const Card(suit: Suit.diamond, rank: 4),
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
      ];
      // 连对 55-66-77
      final higher = [
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 6),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
        const Card(suit: Suit.spade, rank: 7),
      ];

      expect(validator.canBeat(higher, lower), true);
      expect(validator.canBeat(lower, higher), false);
    });

    test('higher triple with single beats lower', () {
      // 三带一 333+4
      final lower = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 3),
        const Card(suit: Suit.club, rank: 3),
        const Card(suit: Suit.diamond, rank: 4),
      ];
      // 三带一 555+6
      final higher = [
        const Card(suit: Suit.heart, rank: 5),
        const Card(suit: Suit.spade, rank: 5),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
      ];

      expect(validator.canBeat(higher, lower), true);
    });
  });
}
