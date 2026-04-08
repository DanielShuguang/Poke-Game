import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/guandan/entities/guandan_card.dart';
import 'package:poke_game/domain/guandan/entities/guandan_hand_type.dart';
import 'package:poke_game/domain/guandan/usecases/validate_hand_usecase.dart';

GuandanCard c(int rank, Suit suit) => GuandanCard(suit: suit, rank: rank);
GuandanCard cH(int rank) => c(rank, Suit.heart);
GuandanCard cS(int rank) => c(rank, Suit.spade);
GuandanCard cC(int rank) => c(rank, Suit.club);
GuandanCard cD(int rank) => c(rank, Suit.diamond);

const bigJoker = GuandanCard.bigJoker();
const smallJoker = GuandanCard.smallJoker();

void main() {
  const level = 2; // 默认使用 2 作为级牌

  group('单张', () {
    test('单张合法', () {
      final result = ValidateHandUsecase.validate([cH(5)], level);
      expect(result?.type, HandType.single);
      expect(result?.rank, 5);
    });

    test('大王单张合法', () {
      final result = ValidateHandUsecase.validate([bigJoker], level);
      expect(result?.type, HandType.single);
      expect(result?.rank, 1000);
    });
  });

  group('对子', () {
    test('两张同点数合法', () {
      final result = ValidateHandUsecase.validate([cH(7), cS(7)], level);
      expect(result?.type, HandType.pair);
      expect(result?.rank, 7);
    });

    test('两张不同点数不合法', () {
      final result = ValidateHandUsecase.validate([cH(5), cS(7)], level);
      expect(result, isNull);
    });

    test('两张小王对子合法', () {
      final result = ValidateHandUsecase.validate(
          [smallJoker, smallJoker], level);
      expect(result?.type, HandType.pair);
      expect(result?.rank, 998);
    });

    test('两张大王 → 天王炸而非对子', () {
      final result = ValidateHandUsecase.validate([bigJoker, bigJoker], level);
      expect(result?.type, HandType.kingBomb);
    });
  });

  group('三张', () {
    test('三张同点数合法', () {
      final result = ValidateHandUsecase.validate(
          [cH(9), cS(9), cC(9)], level);
      expect(result?.type, HandType.triple);
      expect(result?.rank, 9);
    });

    test('三张不同点数不合法', () {
      final result = ValidateHandUsecase.validate(
          [cH(3), cS(4), cC(5)], level);
      expect(result, isNull);
    });
  });

  group('三带二', () {
    test('三带二合法', () {
      final result = ValidateHandUsecase.validate(
          [cH(8), cS(8), cC(8), cH(5), cS(5)], level);
      expect(result?.type, HandType.triplePair);
      expect(result?.rank, 8);
    });

    test('四张+一张不是三带二也不是炸弹', () {
      // 四张8 + 一张5，不是合法牌型
      final result = ValidateHandUsecase.validate(
          [cH(8), cS(8), cC(8), cD(8), cH(5)], level);
      expect(result, isNull);
    });
  });

  group('顺子', () {
    test('5张连续合法', () {
      final cards = [cH(3), cS(4), cC(5), cD(6), cH(7)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, HandType.straight);
      expect(result?.rank, 7);
    });

    test('7张连续合法', () {
      final cards = [cH(5), cS(6), cC(7), cD(8), cH(9), cS(10), cC(11)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, HandType.straight);
      expect(result?.rank, 11);
    });

    test('含A不合法（A不延伸顺子）', () {
      final cards = [cH(10), cS(11), cC(12), cD(13), cH(14)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result, isNull);
    });

    test('4张不构成顺子', () {
      final cards = [cH(3), cS(4), cC(5), cD(6)];
      final result = ValidateHandUsecase.validate(cards, level);
      // 4张不是顺子
      expect(result?.type, isNot(HandType.straight));
    });
  });

  // 级牌（level=5）百搭顺子测试
  group('级牌百搭嵌入顺子', () {
    const wildLevel = 5;

    test('级牌填补单缺口合法', () {
      // 3 4 _ 6 7，用一张5填补
      final cards = [cH(3), cS(4), cH(5), cC(6), cD(7)];
      // 注意：cH(5) 是级牌，充当百搭填补缺口
      final result = ValidateHandUsecase.validate(cards, wildLevel);
      expect(result?.type, HandType.straight);
    });

    test('级牌数量不足以填补多缺口', () {
      // 3 _ 5(wild) _ 6 7 → 缺口2，只有1张级牌
      final cards = [cH(3), cH(5), cC(6), cD(7), cS(9)]; // 缺4和8，非连续
      final result = ValidateHandUsecase.validate(cards, wildLevel);
      // 不是合法顺子（两处缺口）
      // 注意：3 5 6 7 9 不连续，缺 4 和 8
      expect(result?.type, isNot(HandType.straight));
    });

    test('级牌不可作为顺子两端延伸', () {
      // 正常牌 3 4 6 7，想用2张5延伸两端 → 不合法
      // cards: 5(wild) 3 4 6 7 5(wild) → 试图构成 3 4 5 6 7 + 两端延伸
      final cards = [
        cH(5), // wild
        cS(3),
        cC(4),
        cD(6),
        cH(7),
        cS(5), // wild
      ];
      // 正常牌范围：3-7，缺 5；有2张5，但只需1张填缺口，多余1张 → 不合法
      final result = ValidateHandUsecase.validate(cards, wildLevel);
      expect(result, isNull);
    });

    test('两张级牌填补两缺口合法', () {
      // 3 _ 5(w1) 5(w2) 6 7 8 → 3 4 5 6 7 8（缺4，用一张5）
      // 改为：正常牌 3 6 7 8，两个缺口 4 和 5，用两张5填补
      final cards = [
        cH(5),
        cS(5),
        cC(3),
        cD(6),
        cH(7),
        cS(8),
      ];
      // 正常牌（非级牌）：3 6 7 8，范围 3-8，缺 4 和 5，两个缺口
      // 有两张级牌5，可填补
      final result = ValidateHandUsecase.validate(cards, wildLevel);
      expect(result?.type, HandType.straight);
    });
  });

  group('连对', () {
    test('3对连续合法', () {
      final cards = [cH(4), cS(4), cH(5), cS(5), cH(6), cS(6)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, HandType.consecutivePairs);
      expect(result?.rank, 6);
    });

    test('2对连续不合法（少于3对）', () {
      final cards = [cH(4), cS(4), cH(5), cS(5)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, isNot(HandType.consecutivePairs));
    });

    test('3对不连续不合法', () {
      final cards = [cH(3), cS(3), cH(5), cS(5), cH(7), cS(7)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, isNot(HandType.consecutivePairs));
    });
  });

  group('钢板', () {
    test('3组连续三张合法', () {
      final cards = [
        cH(4), cS(4), cC(4),
        cH(5), cS(5), cC(5),
        cH(6), cS(6), cC(6),
      ];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, HandType.steelPlate);
      expect(result?.rank, 6);
    });
  });

  group('炸弹', () {
    test('4张同点数炸弹合法', () {
      final cards = [cH(8), cS(8), cC(8), cD(8)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, HandType.bomb);
      expect(result?.rank, 8);
    });

    test('5张同点数炸弹合法', () {
      final cards = [cH(8), cS(8), cC(8), cD(8), cH(8)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, HandType.bomb);
      expect(result?.count, 5);
    });

    test('3张同点数不是炸弹', () {
      final result = ValidateHandUsecase.validate(
          [cH(8), cS(8), cC(8)], level);
      expect(result?.type, HandType.triple);
    });
  });

  group('同花顺炸弹', () {
    test('5张同花色连续合法', () {
      final cards = [cH(3), cH(4), cH(5), cH(6), cH(7)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, HandType.straightFlushBomb);
      expect(result?.rank, 7);
    });

    test('5张连续但非同花色不是同花顺炸', () {
      final cards = [cH(3), cS(4), cH(5), cH(6), cH(7)];
      final result = ValidateHandUsecase.validate(cards, level);
      expect(result?.type, HandType.straight);
    });
  });

  group('天王炸', () {
    test('两张大王是天王炸', () {
      final result = ValidateHandUsecase.validate([bigJoker, bigJoker], level);
      expect(result?.type, HandType.kingBomb);
    });

    test('大王+小王不是天王炸', () {
      final result = ValidateHandUsecase.validate([bigJoker, smallJoker], level);
      expect(result, isNull);
    });
  });

  group('非法牌型', () {
    test('空牌组不合法', () {
      expect(ValidateHandUsecase.validate([], level), isNull);
    });

    test('6张不连续不合法', () {
      final cards = [cH(3), cS(5), cC(7), cD(9), cH(11), cS(13)];
      expect(ValidateHandUsecase.validate(cards, level), isNull);
    });
  });
}
