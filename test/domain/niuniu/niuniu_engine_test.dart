import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_card.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_game_state.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_hand.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_player.dart';
import 'package:poke_game/domain/niuniu/usecases/settle_niuniu_usecase.dart';

NiuniuCard c(Suit suit, int rank) => NiuniuCard(suit: suit, rank: rank);
const s = Suit.spade;
const h = Suit.heart;
const d = Suit.diamond;
const cl = Suit.club;

NiuniuHand hand(List<NiuniuCard> cards) => NiuniuHand(cards: cards);

void main() {
  group('NiuniuHand.rank', () {
    test('无牛', () {
      // 1,2,4,6,8 → 无任何3张之和为10的倍数
      final hand = NiuniuHand(cards: [c(s,1),c(s,2),c(s,4),c(s,6),c(s,8)]);
      expect(hand.rank, NiuniuRank.noPoints);
      expect(hand.multiplier, 1);
    });

    test('牛6', () {
      // 1+2+7=10（有牛），剩余3+3=6
      final h1 = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,3),c(h,3)]);
      expect(h1.rank, NiuniuRank.niu6);
      expect(h1.multiplier, 1);
    });

    test('牛7', () {
      // 1+2+7=10，剩余4+3=7
      final h1 = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,4),c(h,3)]);
      expect(h1.rank, NiuniuRank.niu7);
      expect(h1.multiplier, 2);
    });

    test('牛8', () {
      // 1+2+7=10，剩余5+3=8
      final h1 = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,5),c(h,3)]);
      expect(h1.rank, NiuniuRank.niu8);
      expect(h1.multiplier, 2);
    });

    test('牛9', () {
      // 1+2+7=10，剩余5+4=9
      final h1 = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,5),c(h,4)]);
      expect(h1.rank, NiuniuRank.niu9);
      expect(h1.multiplier, 2);
    });

    test('牛牛', () {
      // 1+2+7=10，剩余5+5=10 → mod10=0
      final h1 = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,5),c(h,5)]);
      expect(h1.rank, NiuniuRank.niuNiu);
      expect(h1.multiplier, 3);
    });

    test('五小牛', () {
      // A,2,3,4,5 点值之和=15>10 → 不是五小牛
      // A,1,1,2,2 → A+1+1=3, sum=7 ≤10 全≤5
      final h1 = NiuniuHand(cards: [c(s,1),c(h,1),c(d,1),c(s,2),c(h,2)]);
      // sum=7≤10，全≤5 → 五小牛
      expect(h1.rank, NiuniuRank.fiveSmall);
      expect(h1.multiplier, 5);
    });

    test('炸弹', () {
      // 4张K+1张A
      final h1 = NiuniuHand(cards: [c(s,13),c(h,13),c(d,13),c(cl,13),c(s,1)]);
      expect(h1.rank, NiuniuRank.bomb);
      expect(h1.multiplier, 5);
    });

    test('炸弹优先于五小牛', () {
      // 理论上4张A+2 → A点值=1，全≤5，sum=6≤10，同时4张同点=炸弹
      final h1 = NiuniuHand(cards: [c(s,1),c(h,1),c(d,1),c(cl,1),c(s,2)]);
      expect(h1.rank, NiuniuRank.bomb);
    });

    test('J/Q/K 的 pointValue 均为 10', () {
      expect(NiuniuCard(suit: s, rank: 11).pointValue, 10);
      expect(NiuniuCard(suit: s, rank: 12).pointValue, 10);
      expect(NiuniuCard(suit: s, rank: 13).pointValue, 10);
      expect(NiuniuCard(suit: s, rank: 10).pointValue, 10);
    });
  });

  group('NiuniuHand.compareTo', () {
    test('牛牛 > 牛9', () {
      final niuNiu = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,5),c(h,5)]);
      final niu9 = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,5),c(h,4)]);
      expect(niuNiu.compareTo(niu9), greaterThan(0));
    });

    test('同为牛6，按最大点值比较', () {
      // 两手都是牛6，但一手有K(点值10)，另一手最大是7
      final h1 = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,3),c(h,3)]); // 牛6，max=7
      final h2 = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,3),c(h,3)]); // 相同
      expect(h1.compareTo(h2), 0);
    });

    test('炸弹 > 五小牛', () {
      final bomb = NiuniuHand(cards: [c(s,13),c(h,13),c(d,13),c(cl,13),c(s,1)]);
      final fs = NiuniuHand(cards: [c(s,1),c(h,1),c(d,1),c(s,2),c(h,2)]);
      expect(bomb.compareTo(fs), greaterThan(0));
    });
  });

  group('SettleNiuniuUseCase', () {
    const settle = SettleNiuniuUseCase();

    NiuniuGameState makeState({
      required NiuniuHand bankerHand,
      required List<({NiuniuHand hand, int bet, int chips})> punters,
    }) {
      final banker = NiuniuPlayer(
        id: 'banker',
        name: '庄家',
        role: NiuniuRole.banker,
        chips: 1000,
        betAmount: 0,
        hand: bankerHand,
        status: NiuniuPlayerStatus.bet,
      );
      final punterPlayers = punters.asMap().entries.map((e) {
        return NiuniuPlayer(
          id: 'punter${e.key}',
          name: '闲家${e.key}',
          role: NiuniuRole.punter,
          chips: e.value.chips,
          betAmount: e.value.bet,
          hand: e.value.hand,
          status: NiuniuPlayerStatus.bet,
        );
      }).toList();
      return NiuniuGameState(
        deck: const [],
        bankerId: 'banker',
        players: [banker, ...punterPlayers],
        phase: NiuniuPhase.showdown,
      );
    }

    test('闲家牛牛(×3)胜庄家牛6(×1)，正确结算', () {
      final state = makeState(
        bankerHand: NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,3),c(h,3)]), // 牛6
        punters: [(hand: NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,5),c(h,5)]), bet: 100, chips: 900)], // 牛牛
      );
      final result = settle(state);
      final punter = result.players.firstWhere((p) => p.id == 'punter0');
      final banker = result.players.firstWhere((p) => p.id == 'banker');
      // 牛牛倍率×3，闲家赢 100×3=300
      expect(punter.chips, 900 + 300);
      expect(banker.chips, 1000 - 300);
      expect(result.phase, NiuniuPhase.settlement);
    });

    test('庄家牛牛(×3)胜闲家牛6(×1)，按闲家倍率结算', () {
      final state = makeState(
        bankerHand: NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,5),c(h,5)]), // 牛牛
        punters: [(hand: NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,3),c(h,3)]), bet: 100, chips: 900)], // 牛6
      );
      final result = settle(state);
      final punter = result.players.firstWhere((p) => p.id == 'punter0');
      final banker = result.players.firstWhere((p) => p.id == 'banker');
      // 闲家牛6倍率×1，庄家赢 100×1=100
      expect(punter.chips, 900 - 100);
      expect(banker.chips, 1000 + 100);
    });

    test('平局时庄家优先赢', () {
      final sameHand = NiuniuHand(cards: [c(s,1),c(s,2),c(s,7),c(s,3),c(h,3)]); // 牛6
      final state = makeState(
        bankerHand: sameHand,
        punters: [(hand: NiuniuHand(cards: [c(h,1),c(h,2),c(h,7),c(h,3),c(d,3)]), bet: 100, chips: 900)],
      );
      final result = settle(state);
      final punter = result.players.firstWhere((p) => p.id == 'punter0');
      // 平局庄家优先，闲家输 100×1=100
      expect(punter.chips, 900 - 100);
    });
  });
}
