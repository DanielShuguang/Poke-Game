import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/guandan/entities/guandan_card.dart';
import 'package:poke_game/domain/guandan/entities/guandan_hand.dart';
import 'package:poke_game/domain/guandan/entities/guandan_hand_type.dart';
import 'package:poke_game/domain/guandan/usecases/validate_hand_usecase.dart';

GuandanCard c(int rank, Suit suit) => GuandanCard(suit: suit, rank: rank);
GuandanCard cH(int rank) => c(rank, Suit.heart);
GuandanCard cS(int rank) => c(rank, Suit.spade);
GuandanCard cC(int rank) => c(rank, Suit.club);
GuandanCard cD(int rank) => c(rank, Suit.diamond);

GuandanHand hand(List<GuandanCard> cards, int level) {
  final result = ValidateHandUsecase.validate(cards, level);
  expect(result, isNotNull, reason: 'Cards should form a valid hand: $cards');
  return result!;
}

void main() {
  const level = 5; // 使用5作为当前级牌

  group('天王炸压制一切', () {
    final kingBomb = GuandanHand(
      cards: [const GuandanCard.bigJoker(), const GuandanCard.bigJoker()],
      type: HandType.kingBomb,
      rank: 9999,
    );

    test('天王炸压制普通炸弹', () {
      final normalBomb = hand([cH(8), cS(8), cC(8), cD(8)], level);
      expect(kingBomb.beats(normalBomb, level), isTrue);
    });

    test('天王炸压制同花顺炸弹', () {
      final sfCards = [cH(7), cH(8), cH(9), cH(10), cH(11)];
      final sf = hand(sfCards, level);
      expect(sf.type, HandType.straightFlushBomb);
      expect(kingBomb.beats(sf, level), isTrue);
    });

    test('天王炸压制级牌炸弹', () {
      // 4张级牌5 → 级牌炸
      final wildBomb = hand([cH(5), cS(5), cC(5), cD(5)], level);
      expect(wildBomb.type, HandType.bomb);
      expect(kingBomb.beats(wildBomb, level), isTrue);
    });
  });

  group('炸弹优先级：同花顺炸 > 普通炸', () {
    test('5张同花顺炸弹压制4张普通炸弹', () {
      final sfBomb = hand([cH(7), cH(8), cH(9), cH(10), cH(11)], level);
      final normalBomb = hand([cS(8), cH(8), cC(8), cD(8)], level);
      expect(sfBomb.beats(normalBomb, level), isTrue);
    });

    test('同花顺炸弹压制级牌炸弹', () {
      final sfBomb = hand([cH(7), cH(8), cH(9), cH(10), cH(11)], level);
      final wildBomb = hand([cH(5), cS(5), cC(5), cD(5)], level);
      expect(sfBomb.beats(wildBomb, level), isTrue);
    });
  });

  group('级牌炸 > 普通炸', () {
    test('4张级牌炸弹压制4张普通炸弹（点数更小的）', () {
      final wildBomb = hand([cH(5), cS(5), cC(5), cD(5)], level);
      final normalBomb = hand([cH(8), cS(8), cC(8), cD(8)], level);
      // 级牌炸 priority=2 > 普通炸 priority=1
      expect(wildBomb.beats(normalBomb, level), isTrue);
    });
  });

  group('相同类型比张数', () {
    test('5张普通炸弹压制4张普通炸弹（相同点数）', () {
      final bomb5 = GuandanHand(
        cards: [cH(8), cS(8), cC(8), cD(8), cH(8)],
        type: HandType.bomb,
        rank: 8,
      );
      final bomb4 = hand([cH(9), cS(9), cC(9), cD(9)], level);
      // 5张8 vs 4张9：相同类型（普通炸），先比张数：5 > 4
      expect(bomb5.beats(bomb4, level), isTrue);
    });

    test('6张同花顺炸弹压制5张同花顺炸弹', () {
      final sf6 = hand(
          [cH(6), cH(7), cH(8), cH(9), cH(10), cH(11)], level);
      final sf5 = hand([cH(7), cH(8), cH(9), cH(10), cH(11)], level);
      expect(sf6.beats(sf5, level), isTrue);
    });

    test('相同张数相同类型相同点数不能压制', () {
      final bomb4a = hand([cH(8), cS(8), cC(8), cD(8)], level);
      final bomb4b = hand([cH(8), cS(8), cC(8), cD(8)], level);
      expect(bomb4a.beats(bomb4b, level), isFalse);
    });
  });

  group('炸弹压制非炸弹', () {
    test('任意炸弹压制顺子', () {
      final bomb = hand([cH(3), cS(3), cC(3), cD(3)], level);
      // 使用不含级牌(5)的连续顺子：6 7 8 9 10
      final straight = hand([cH(6), cS(7), cC(8), cD(9), cH(10)], level);
      expect(bomb.beats(straight, level), isTrue);
    });

    test('非炸弹不能压制炸弹', () {
      final bomb = hand([cH(9), cS(9), cC(9), cD(9)], level);
      final single = GuandanHand(
        cards: [const GuandanCard.bigJoker()],
        type: HandType.single,
        rank: 1000,
      );
      expect(single.beats(bomb, level), isFalse);
    });
  });

  group('非炸弹同类型比 rank', () {
    test('大单张压制小单张', () {
      final big = GuandanHand(
          cards: [cH(10)], type: HandType.single, rank: 10);
      final small = GuandanHand(
          cards: [cH(7)], type: HandType.single, rank: 7);
      expect(big.beats(small, level), isTrue);
      expect(small.beats(big, level), isFalse);
    });

    test('不同类型不能互相压制', () {
      final pair = hand([cH(7), cS(7)], level);
      final single = GuandanHand(
          cards: [cH(10)], type: HandType.single, rank: 10);
      expect(pair.beats(single, level), isFalse);
      expect(single.beats(pair, level), isFalse);
    });

    test('不同张数的顺子不能互相压制', () {
      // 5张顺子：6 7 8 9 10；6张顺子：6 7 8 9 10 J（不含级牌5）
      final s5 = hand([cH(6), cS(7), cC(8), cD(9), cH(10)], level);
      final s6 = hand([cH(6), cS(7), cC(8), cD(9), cH(10), cS(11)], level);
      expect(s6.beats(s5, level), isFalse);
    });
  });
}
