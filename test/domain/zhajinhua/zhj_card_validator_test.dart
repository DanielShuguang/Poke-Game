import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_card.dart';
import 'package:poke_game/domain/zhajinhua/validators/zhj_card_validator.dart';

ZhjCard c(int rank, Suit suit) => ZhjCard(rank: rank, suit: suit);

void main() {
  group('ZhjCardValidator - 牌型识别', () {
    test('豹子识别 - AAA', () {
      final cards = [c(14, Suit.spade), c(14, Suit.heart), c(14, Suit.diamond)];
      expect(ZhjCardValidator.evaluate(cards).rank, HandRank.threeOfAKind);
    });

    test('豹子识别 - 222', () {
      final cards = [c(2, Suit.spade), c(2, Suit.heart), c(2, Suit.diamond)];
      expect(ZhjCardValidator.evaluate(cards).rank, HandRank.threeOfAKind);
    });

    test('同花顺识别 - AKQ同花', () {
      final cards = [c(14, Suit.spade), c(13, Suit.spade), c(12, Suit.spade)];
      expect(ZhjCardValidator.evaluate(cards).rank, HandRank.straightFlush);
    });

    test('同花顺识别 - 345同花', () {
      final cards = [c(3, Suit.heart), c(4, Suit.heart), c(5, Suit.heart)];
      expect(ZhjCardValidator.evaluate(cards).rank, HandRank.straightFlush);
    });

    test('同花识别 - 358同花', () {
      final cards = [c(3, Suit.club), c(5, Suit.club), c(8, Suit.club)];
      expect(ZhjCardValidator.evaluate(cards).rank, HandRank.flush);
    });

    test('顺子识别 - 普通顺子', () {
      final cards = [c(7, Suit.spade), c(8, Suit.heart), c(9, Suit.diamond)];
      expect(ZhjCardValidator.evaluate(cards).rank, HandRank.straight);
    });

    test('顺子识别 - A23特例', () {
      final cards = [c(14, Suit.spade), c(2, Suit.heart), c(3, Suit.diamond)];
      expect(ZhjCardValidator.evaluate(cards).rank, HandRank.straight);
    });

    test('对子识别', () {
      final cards = [c(13, Suit.spade), c(13, Suit.heart), c(5, Suit.diamond)];
      expect(ZhjCardValidator.evaluate(cards).rank, HandRank.pair);
    });

    test('散牌识别', () {
      final cards = [c(3, Suit.spade), c(7, Suit.heart), c(10, Suit.diamond)];
      expect(ZhjCardValidator.evaluate(cards).rank, HandRank.highCard);
    });
  });

  group('ZhjCardValidator - 牌型比较', () {
    test('豹子 > 同花顺', () {
      final three = [c(5, Suit.spade), c(5, Suit.heart), c(5, Suit.diamond)];
      final sf = [c(3, Suit.club), c(4, Suit.club), c(5, Suit.club)];
      expect(ZhjCardValidator.compare(three, sf), greaterThan(0));
    });

    test('同花顺 > 同花', () {
      final sf = [c(7, Suit.spade), c(8, Suit.spade), c(9, Suit.spade)];
      final fl = [c(3, Suit.heart), c(5, Suit.heart), c(10, Suit.heart)];
      expect(ZhjCardValidator.compare(sf, fl), greaterThan(0));
    });

    test('同花 > 顺子', () {
      final fl = [c(3, Suit.diamond), c(5, Suit.diamond), c(8, Suit.diamond)];
      final st = [c(7, Suit.spade), c(8, Suit.heart), c(9, Suit.club)];
      expect(ZhjCardValidator.compare(fl, st), greaterThan(0));
    });

    test('顺子 > 对子', () {
      final st = [c(3, Suit.spade), c(4, Suit.heart), c(5, Suit.diamond)];
      final pair = [c(14, Suit.spade), c(14, Suit.heart), c(3, Suit.diamond)];
      expect(ZhjCardValidator.compare(st, pair), greaterThan(0));
    });

    test('对子 > 散牌', () {
      final pair = [c(3, Suit.spade), c(3, Suit.heart), c(4, Suit.diamond)];
      final high = [c(7, Suit.spade), c(10, Suit.heart), c(13, Suit.diamond)];
      expect(ZhjCardValidator.compare(pair, high), greaterThan(0));
    });

    test('同豹子大小比较 - AAA > KKK', () {
      final aaa = [c(14, Suit.spade), c(14, Suit.heart), c(14, Suit.diamond)];
      final kkk = [c(13, Suit.spade), c(13, Suit.heart), c(13, Suit.diamond)];
      expect(ZhjCardValidator.compare(aaa, kkk), greaterThan(0));
    });

    test('A23顺子是最小顺子（小于234）', () {
      final a23 = [c(14, Suit.spade), c(2, Suit.heart), c(3, Suit.diamond)];
      final s234 = [c(2, Suit.spade), c(3, Suit.heart), c(4, Suit.diamond)];
      expect(ZhjCardValidator.compare(a23, s234), lessThan(0));
    });

    test('AKQ同花顺是最大顺子', () {
      final akq = [c(14, Suit.spade), c(13, Suit.spade), c(12, Suit.spade)];
      final qkj = [c(12, Suit.heart), c(13, Suit.heart), c(11, Suit.heart)];
      expect(ZhjCardValidator.compare(akq, qkj), greaterThan(0));
    });

    test('相同牌型相同点数返回0', () {
      final a1 = [c(14, Suit.spade), c(14, Suit.heart), c(14, Suit.diamond)];
      final a2 = [c(14, Suit.club), c(14, Suit.spade), c(14, Suit.heart)];
      expect(ZhjCardValidator.compare(a1, a2), equals(0));
    });
  });
}
