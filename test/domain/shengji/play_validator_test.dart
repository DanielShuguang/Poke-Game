import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/trump_info.dart';
import 'package:poke_game/domain/shengji/validators/play_validator.dart';

/// 创建普通牌
ShengjiCard c(int rank, Suit suit) => ShengjiCard(suit: suit, rank: rank);

/// 创建大王
ShengjiCard bigJoker() => const ShengjiCard.bigJoker();

/// 创建小王
ShengjiCard smallJoker() => const ShengjiCard.smallJoker();

void main() {
  group('PlayValidator - 首出验证', () {
    test('首出单张始终合法', () {
      final hand = [c(5, Suit.spade), c(10, Suit.heart), c(13, Suit.club)];
      final played = [c(5, Suit.spade)];
      final trump = TrumpInfo(rankLevel: 2, trumpSuit: Suit.spade);

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: [],
        trumpInfo: trump,
      );
      expect(result.isValid, isTrue);
    });

    test('首出对子合法', () {
      final hand = [c(10, Suit.spade), c(10, Suit.heart), c(5, Suit.club)];
      final played = [c(10, Suit.spade), c(10, Suit.heart)];
      final trump = TrumpInfo(rankLevel: 2);

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: [],
        trumpInfo: trump,
      );
      expect(result.isValid, isTrue);
    });

    test('首出拖拉机合法', () {
      final hand = [
        c(5, Suit.spade), c(5, Suit.spade),
        c(6, Suit.spade), c(6, Suit.spade),
        c(10, Suit.club),
      ];
      final played = [
        c(5, Suit.spade), c(5, Suit.spade),
        c(6, Suit.spade), c(6, Suit.spade),
      ];
      final trump = TrumpInfo(rankLevel: 2);

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: [],
        trumpInfo: trump,
      );
      expect(result.isValid, isTrue);
    });

    test('没有的牌不能出', () {
      final hand = [c(5, Suit.spade), c(10, Suit.heart)];
      final played = [c(13, Suit.spade)]; // K不在手中
      final trump = TrumpInfo(rankLevel: 2);

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: [],
        trumpInfo: trump,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('没有这些牌'));
    });

    test('无效牌型不能出', () {
      final hand = [c(5, Suit.spade), c(7, Suit.heart), c(9, Suit.club)];
      final played = [c(5, Suit.spade), c(7, Suit.heart), c(9, Suit.club)]; // 散牌
      final trump = TrumpInfo(rankLevel: 2);

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: [],
        trumpInfo: trump,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('无效牌型'));
    });
  });

  group('PlayValidator - 跟牌验证', () {
    test('必须跟同花色 - 有该花色', () {
      final hand = [c(5, Suit.spade), c(10, Suit.heart), c(13, Suit.club)];
      final lead = [c(3, Suit.spade)]; // 非将牌的黑桃
      final played = [c(10, Suit.heart)]; // 应该跟黑桃
      final trump = TrumpInfo(rankLevel: 2); // 2是将牌，3不是

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: lead,
        trumpInfo: trump,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('必须跟'));
    });

    test('跟同花色合法', () {
      final hand = [c(5, Suit.spade), c(10, Suit.heart), c(13, Suit.club)];
      final lead = [c(3, Suit.spade)];
      final played = [c(5, Suit.spade)]; // 跟黑桃
      final trump = TrumpInfo(rankLevel: 2);

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: lead,
        trumpInfo: trump,
      );
      expect(result.isValid, isTrue);
    });

    test('无该花色可以垫其他花色', () {
      final hand = [c(5, Suit.spade), c(10, Suit.heart), c(13, Suit.club)];
      final lead = [c(2, Suit.diamond)]; // 首出方块
      final played = [c(10, Suit.heart)]; // 没有方块，垫红桃
      final trump = TrumpInfo(rankLevel: 14); // A是级牌

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: lead,
        trumpInfo: trump,
      );
      expect(result.isValid, isTrue);
    });

    test('无该花色可以用将牌杀牌', () {
      final hand = [c(5, Suit.spade), c(2, Suit.heart), c(13, Suit.club)];
      final lead = [c(10, Suit.diamond)];
      final played = [c(2, Suit.heart)]; // 2是将牌（级牌）
      final trump = TrumpInfo(rankLevel: 2);

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: lead,
        trumpInfo: trump,
      );
      expect(result.isValid, isTrue);
    });

    test('出牌数量必须匹配', () {
      final hand = [c(5, Suit.spade), c(5, Suit.heart), c(13, Suit.club)];
      final lead = [c(3, Suit.spade), c(3, Suit.heart)]; // 对子首出
      final played = [c(5, Suit.spade)]; // 只出了一张
      final trump = TrumpInfo(rankLevel: 14); // A是级牌

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: lead,
        trumpInfo: trump,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('数量不匹配'));
    });
  });

  group('PlayValidator - 将牌跟牌', () {
    test('首出将牌时必须跟将牌', () {
      final hand = [c(5, Suit.spade), c(10, Suit.heart), c(13, Suit.club)];
      final lead = [c(2, Suit.heart)]; // 2是级牌，是将牌
      final played = [c(5, Suit.spade)];
      final trump = TrumpInfo(rankLevel: 2, trumpSuit: Suit.diamond);

      // 有将牌必须跟将牌
      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: lead,
        trumpInfo: trump,
      );
      // 手中无将牌时可以垫牌
      expect(result.isValid, isTrue);
    });

    test('有将牌花色时可以用将牌花色跟牌', () {
      final hand = [c(5, Suit.spade), c(10, Suit.diamond), c(13, Suit.club)];
      final lead = [c(2, Suit.heart)]; // 级牌首出
      final played = [c(10, Suit.diamond)]; // 将牌花色
      final trump = TrumpInfo(rankLevel: 2, trumpSuit: Suit.diamond);

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: lead,
        trumpInfo: trump,
      );
      expect(result.isValid, isTrue);
    });
  });

  group('PlayValidator - 牌大小比较', () {
    test('将牌大于非将牌', () {
      final a = [c(2, Suit.heart)]; // 级牌
      final b = [c(14, Suit.spade)]; // A
      final lead = [c(5, Suit.diamond)];
      final trump = TrumpInfo(rankLevel: 2);

      expect(
        PlayValidator.compare(a: a, b: b, leadCards: lead, trumpInfo: trump),
        greaterThan(0),
      );
    });

    test('大王大于小王', () {
      final a = [bigJoker()];
      final b = [smallJoker()];
      final lead = [c(5, Suit.spade)];
      final trump = TrumpInfo(rankLevel: 2);

      expect(
        PlayValidator.compare(a: a, b: b, leadCards: lead, trumpInfo: trump),
        greaterThan(0),
      );
    });

    test('小王大于级牌', () {
      final a = [smallJoker()];
      final b = [c(2, Suit.spade)]; // 级牌
      final lead = [c(5, Suit.heart)];
      final trump = TrumpInfo(rankLevel: 2);

      expect(
        PlayValidator.compare(a: a, b: b, leadCards: lead, trumpInfo: trump),
        greaterThan(0),
      );
    });

    test('同花色比点数', () {
      final a = [c(14, Suit.spade)]; // A
      final b = [c(10, Suit.spade)]; // 10
      final lead = [c(5, Suit.spade)];
      final trump = TrumpInfo(rankLevel: 2);

      expect(
        PlayValidator.compare(a: a, b: b, leadCards: lead, trumpInfo: trump),
        greaterThan(0),
      );
    });

    test('首出花色优先于其他花色', () {
      final a = [c(5, Suit.spade)]; // 首出花色
      final b = [c(14, Suit.heart)]; // 其他花色
      final lead = [c(3, Suit.spade)];
      final trump = TrumpInfo(rankLevel: 2);

      expect(
        PlayValidator.compare(a: a, b: b, leadCards: lead, trumpInfo: trump),
        greaterThan(0),
      );
    });

    test('将牌花色级牌大于其他花色级牌', () {
      final a = [c(2, Suit.spade)]; // 将牌花色级牌
      final b = [c(2, Suit.heart)]; // 其他花色级牌
      final lead = [c(5, Suit.club)];
      final trump = TrumpInfo(rankLevel: 2, trumpSuit: Suit.spade);

      expect(
        PlayValidator.compare(a: a, b: b, leadCards: lead, trumpInfo: trump),
        greaterThan(0),
      );
    });
  });

  group('PlayValidator - 对子跟牌', () {
    test('跟对子时必须跟同花色对子', () {
      final hand = [
        c(5, Suit.spade), c(5, Suit.spade),
        c(10, Suit.heart), c(10, Suit.club),
      ];
      final lead = [c(3, Suit.spade), c(3, Suit.heart)]; // 黑桃3对子（非将牌）
      final played = [c(10, Suit.heart), c(10, Suit.club)]; // 红桃10对子
      final trump = TrumpInfo(rankLevel: 14); // A是级牌

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: lead,
        trumpInfo: trump,
      );
      expect(result.isValid, isFalse);
    });

    test('有同花色对子时可以跟', () {
      final hand = [
        c(5, Suit.spade), c(5, Suit.spade),
        c(10, Suit.heart), c(10, Suit.club),
      ];
      final lead = [c(3, Suit.spade), c(3, Suit.heart)];
      final played = [c(5, Suit.spade), c(5, Suit.spade)];
      final trump = TrumpInfo(rankLevel: 14);

      final result = PlayValidator.validate(
        hand: hand,
        playedCards: played,
        leadCards: lead,
        trumpInfo: trump,
      );
      expect(result.isValid, isTrue);
    });
  });
}
