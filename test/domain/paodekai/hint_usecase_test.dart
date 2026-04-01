import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_card.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_hand_type.dart';
import 'package:poke_game/domain/paodekai/usecases/hint_usecase.dart';

PdkCard c(PdkRank r, [PdkSuit s = PdkSuit.spade]) => PdkCard(rank: r, suit: s);

PdkPlayedHand singleHand(PdkRank rank, [PdkSuit suit = PdkSuit.spade]) {
  final card = PdkCard(rank: rank, suit: suit);
  return PdkPlayedHand(type: PdkHandType.single, cards: [card], keyCard: card);
}

PdkPlayedHand pairHand(PdkRank rank) {
  final cards = [
    PdkCard(rank: rank, suit: PdkSuit.spade),
    PdkCard(rank: rank, suit: PdkSuit.heart),
  ];
  return PdkPlayedHand(type: PdkHandType.pair, cards: cards, keyCard: cards[0]);
}

void main() {
  const hint = HintUseCase();

  // ── 起手方 ───────────────────────────────────────────────────────────────────

  group('起手方（lastPlayedHand == null）', () {
    test('返回最小单张（非炸弹/王）', () {
      final hand = [c(PdkRank.king), c(PdkRank.five), c(PdkRank.nine)];
      final result = hint(hand: hand, lastPlayedHand: null);
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].rank, PdkRank.five);
    });

    test('手牌全是炸弹时返回炸弹', () {
      final hand = [
        c(PdkRank.seven), c(PdkRank.seven, PdkSuit.heart),
        c(PdkRank.seven, PdkSuit.club), c(PdkRank.seven, PdkSuit.diamond),
      ];
      final result = hint(hand: hand, lastPlayedHand: null);
      expect(result, isNotNull);
      expect(result!.length, 4);
    });

    test('空手牌返回 null', () {
      final result = hint(hand: [], lastPlayedHand: null);
      expect(result, isNull);
    });
  });

  // ── 跟牌方 ───────────────────────────────────────────────────────────────────

  group('跟牌方（有上家出牌）', () {
    test('有能压过上家的单张时返回最小的', () {
      final hand = [c(PdkRank.three), c(PdkRank.seven), c(PdkRank.king)];
      final last = singleHand(PdkRank.five);
      final result = hint(hand: hand, lastPlayedHand: last);
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].rank, PdkRank.seven);
    });

    test('有能压过上家的对子时返回最小的', () {
      final hand = [
        c(PdkRank.five), c(PdkRank.five, PdkSuit.heart),
        c(PdkRank.nine), c(PdkRank.nine, PdkSuit.heart),
        c(PdkRank.king),
      ];
      final last = pairHand(PdkRank.four);
      final result = hint(hand: hand, lastPlayedHand: last);
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].rank, PdkRank.five);
    });

    test('无同类型但有炸弹时返回炸弹', () {
      final hand = [
        c(PdkRank.three), c(PdkRank.four),
        c(PdkRank.eight), c(PdkRank.eight, PdkSuit.heart),
        c(PdkRank.eight, PdkSuit.club), c(PdkRank.eight, PdkSuit.diamond),
      ];
      final last = singleHand(PdkRank.ace); // 压不过 A 的单张
      final result = hint(hand: hand, lastPlayedHand: last);
      expect(result, isNotNull);
      expect(result!.length, 4);
      expect(result[0].rank, PdkRank.eight);
    });

    test('无法压过上家且无炸弹时返回 null', () {
      final hand = [c(PdkRank.three), c(PdkRank.four), c(PdkRank.five)];
      final last = singleHand(PdkRank.ace);
      final result = hint(hand: hand, lastPlayedHand: last);
      expect(result, isNull);
    });

    test('王炸可压过任何牌', () {
      final hand = [
        c(PdkRank.three),
        c(PdkRank.jokerSmall, PdkSuit.none),
        c(PdkRank.jokerBig, PdkSuit.none),
      ];
      // 上家出了炸弹（4 张 A）
      final bombCards = [
        c(PdkRank.ace), c(PdkRank.ace, PdkSuit.heart),
        c(PdkRank.ace, PdkSuit.club), c(PdkRank.ace, PdkSuit.diamond),
      ];
      final last = PdkPlayedHand(
        type: PdkHandType.bomb,
        cards: bombCards,
        keyCard: bombCards[0],
      );
      final result = hint(hand: hand, lastPlayedHand: last);
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result.any((c) => c.rank == PdkRank.jokerSmall), isTrue);
      expect(result.any((c) => c.rank == PdkRank.jokerBig), isTrue);
    });
  });
}
