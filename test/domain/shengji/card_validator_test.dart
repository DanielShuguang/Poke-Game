import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/trump_info.dart';
import 'package:poke_game/domain/shengji/validators/card_validator.dart';

/// 创建普通牌
ShengjiCard c(int rank, Suit suit) => ShengjiCard(suit: suit, rank: rank);

/// 创建大王
ShengjiCard bigJoker() => const ShengjiCard.bigJoker();

/// 创建小王
ShengjiCard smallJoker() => const ShengjiCard.smallJoker();

void main() {
  group('CardValidator - 单张识别', () {
    test('识别单张普通牌', () {
      final card = c(14, Suit.spade);
      final shape = CardValidator.identify([card]);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.single);
      expect(shape.length, 1);
      expect(shape.mainRank, 14);
    });

    test('识别单张大王', () {
      final card = bigJoker();
      final shape = CardValidator.identify([card]);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.single);
      expect(shape.length, 1);
    });

    test('识别单张小王', () {
      final card = smallJoker();
      final shape = CardValidator.identify([card]);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.single);
    });
  });

  group('CardValidator - 对子识别', () {
    test('识别普通对子 - AA', () {
      final cards = [c(14, Suit.spade), c(14, Suit.heart)];
      final shape = CardValidator.identify(cards);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.pair);
      expect(shape.length, 2);
      expect(shape.mainRank, 14);
    });

    test('识别普通对子 - 22', () {
      final cards = [c(2, Suit.club), c(2, Suit.diamond)];
      final shape = CardValidator.identify(cards);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.pair);
      expect(shape.mainRank, 2);
    });

    test('识别大王对子', () {
      final cards = [bigJoker(), bigJoker()];
      final shape = CardValidator.identify(cards);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.pair);
    });

    test('识别小王对子', () {
      final cards = [smallJoker(), smallJoker()];
      final shape = CardValidator.identify(cards);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.pair);
    });

    test('大小王不能组成对子', () {
      final cards = [bigJoker(), smallJoker()];
      final shape = CardValidator.identify(cards);
      expect(shape, isNull);
    });

    test('不同点数不能组成对子', () {
      final cards = [c(14, Suit.spade), c(13, Suit.heart)];
      final shape = CardValidator.identify(cards);
      expect(shape, isNull);
    });
  });

  group('CardValidator - 拖拉机识别', () {
    test('识别最小拖拉机 - 2233 同花色', () {
      final cards = [
        c(2, Suit.spade), c(2, Suit.spade),
        c(3, Suit.spade), c(3, Suit.spade),
      ];
      final shape = CardValidator.identify(cards);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.tractor);
      expect(shape.length, 4);
    });

    test('识别三对拖拉机 - JQK同花色', () {
      final cards = [
        c(11, Suit.spade), c(11, Suit.spade),
        c(12, Suit.spade), c(12, Suit.spade),
        c(13, Suit.spade), c(13, Suit.spade),
      ];
      final shape = CardValidator.identify(cards);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.tractor);
      expect(shape.length, 6);
    });

    test('识别两对拖拉机 - 8899同花色', () {
      final cards = [
        c(8, Suit.club), c(8, Suit.club),
        c(9, Suit.club), c(9, Suit.club),
      ];
      final shape = CardValidator.identify(cards);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.tractor);
    });

    test('点数不连续不是拖拉机 - 2244', () {
      final cards = [
        c(2, Suit.spade), c(2, Suit.heart),
        c(4, Suit.spade), c(4, Suit.heart),
      ];
      final shape = CardValidator.identify(cards);
      expect(shape, isNull);
    });

    test('拖拉机必须同花色', () {
      final cards = [
        c(5, Suit.spade), c(5, Suit.heart),
        c(6, Suit.club), c(6, Suit.diamond),
      ];
      final shape = CardValidator.identify(cards);
      expect(shape, isNull);
    });

    test('拖拉机不能包含大小王', () {
      final cards = [
        bigJoker(), bigJoker(),
        smallJoker(), smallJoker(),
      ];
      final shape = CardValidator.identify(cards);
      expect(shape, isNull);
    });

    test('每点数必须恰好两张 - 222333', () {
      final cards = [
        c(2, Suit.spade), c(2, Suit.heart), c(2, Suit.diamond),
        c(3, Suit.spade), c(3, Suit.heart), c(3, Suit.diamond),
      ];
      final shape = CardValidator.identify(cards);
      expect(shape, isNull);
    });

    test('奇数张牌不能是拖拉机', () {
      final cards = [
        c(2, Suit.spade), c(2, Suit.heart),
        c(3, Suit.spade),
      ];
      final shape = CardValidator.identify(cards);
      expect(shape, isNull);
    });
  });

  group('CardValidator - 工具方法', () {
    test('hasSuit - 检查手牌中是否有足够花色牌', () {
      final hand = [
        c(14, Suit.spade), c(13, Suit.spade),
        c(10, Suit.heart), c(5, Suit.heart),
      ];
      expect(CardValidator.hasSuit(hand, Suit.spade, 2), isTrue);
      expect(CardValidator.hasSuit(hand, Suit.spade, 3), isFalse);
      expect(CardValidator.hasSuit(hand, Suit.club, 1), isFalse);
    });

    test('getSuitCards - 获取指定花色的牌', () {
      final hand = [
        c(14, Suit.spade), c(13, Suit.spade),
        c(10, Suit.heart), c(5, Suit.club),
      ];
      final spades = CardValidator.getSuitCards(hand, Suit.spade);
      expect(spades.length, 2);
      expect(spades.every((c) => c.suit == Suit.spade), isTrue);
    });

    test('getMainSuit - 获取牌组主花色', () {
      final cards = [c(14, Suit.spade), c(13, Suit.spade)];
      expect(CardValidator.getMainSuit(cards), Suit.spade);
    });

    test('getMainSuit - 大小王无花色', () {
      final cards = [bigJoker(), smallJoker()];
      expect(CardValidator.getMainSuit(cards), isNull);
    });
  });

  group('CardValidator - 有效牌型判断', () {
    test('单张是有效牌型', () {
      expect(CardValidator.isValidPlay([c(5, Suit.spade)]), isTrue);
    });

    test('对子是有效牌型', () {
      expect(CardValidator.isValidPlay([c(10, Suit.heart), c(10, Suit.club)]), isTrue);
    });

    test('拖拉机是有效牌型', () {
      final cards = [
        c(7, Suit.diamond), c(7, Suit.diamond),
        c(8, Suit.diamond), c(8, Suit.diamond),
      ];
      expect(CardValidator.isValidPlay(cards), isTrue);
    });

    test('散牌不是有效牌型', () {
      final cards = [c(5, Suit.spade), c(7, Suit.heart), c(9, Suit.club)];
      expect(CardValidator.isValidPlay(cards), isFalse);
    });
  });

  group('CardValidator - 将牌拖拉机识别', () {
    // 黑桃2级
    const trumpInfo = TrumpInfo(trumpSuit: Suit.spade, rankLevel: 2);

    test('王炸（大王对+小王对）识别为将牌拖拉机', () {
      final cards = [bigJoker(), bigJoker(), smallJoker(), smallJoker()];
      final shape = CardValidator.identify(cards, trumpInfo: trumpInfo);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.tractor);
      expect(shape.length, 4);
    });

    test('无 TrumpInfo 时王炸不识别为拖拉机', () {
      final cards = [bigJoker(), bigJoker(), smallJoker(), smallJoker()];
      final shape = CardValidator.identify(cards);
      expect(shape, isNull);
    });

    test('将牌花色连续对子跨越级牌空位识别为拖拉机', () {
      // rank=7, trump=♠：6♠ 和 8♠ 在将牌排序中相邻（7♠ 是级牌被跳过）
      const ti = TrumpInfo(trumpSuit: Suit.spade, rankLevel: 7);
      final cards = [
        c(6, Suit.spade), c(6, Suit.spade),
        c(8, Suit.spade), c(8, Suit.spade),
      ];
      final shape = CardValidator.identify(cards, trumpInfo: ti);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.tractor);
    });

    test('将牌花色非连续对子不是拖拉机', () {
      // rank=7, trump=♠：5♠×2 + 8♠×2，中间缺 6♠×2
      const ti = TrumpInfo(trumpSuit: Suit.spade, rankLevel: 7);
      final cards = [
        c(5, Suit.spade), c(5, Suit.spade),
        c(8, Suit.spade), c(8, Suit.spade),
      ];
      final shape = CardValidator.identify(cards, trumpInfo: ti);
      expect(shape, isNull);
    });

    test('相邻花色级牌对子组成将牌拖拉机', () {
      // rank=2, trump=♠：2♦×2 + 2♣×2（diamond=200, club=201，相邻）
      final cards = [
        c(2, Suit.diamond), c(2, Suit.diamond),
        c(2, Suit.club), c(2, Suit.club),
      ];
      final shape = CardValidator.identify(cards, trumpInfo: trumpInfo);
      expect(shape, isNotNull);
      expect(shape!.type, PlayType.tractor);
    });

    test('非相邻花色级牌对子不是将牌拖拉机', () {
      // rank=2, trump=♠：2♦×2 + 2♥×2（diamond=200, heart=202，中间缺 club=201）
      final cards = [
        c(2, Suit.diamond), c(2, Suit.diamond),
        c(2, Suit.heart), c(2, Suit.heart),
      ];
      final shape = CardValidator.identify(cards, trumpInfo: trumpInfo);
      expect(shape, isNull);
    });

    test('将牌花色普通牌与级牌不相邻（不能组成拖拉机）', () {
      // rank=2, trump=♠：A♠×2 + 2♠×2（A在zone1=pos13，2♠是级牌=pos400，不相邻）
      final cards = [
        c(14, Suit.spade), c(14, Suit.spade),
        c(2, Suit.spade), c(2, Suit.spade),
      ];
      final shape = CardValidator.identify(cards, trumpInfo: trumpInfo);
      expect(shape, isNull);
    });
  });
}
