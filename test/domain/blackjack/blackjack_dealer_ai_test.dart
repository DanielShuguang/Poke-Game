import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/blackjack/ai/blackjack_dealer_ai.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_card.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_config.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_player.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';

BlackjackCard c(int rank) => BlackjackCard(suit: Suit.spade, rank: rank);

BlackjackGameState stateWithDealer(
  List<BlackjackCard> dealerCards, {
  List<BlackjackCard> deck = const [],
}) {
  final hand = BlackjackHand(cards: dealerCards, bet: 0);
  return BlackjackGameState(
    deck: List.of(deck),
    dealer: BlackjackPlayer(
      id: 'dealer',
      name: '庄家',
      isAi: true,
      isDealer: true,
      chips: 0,
      hands: [hand],
    ),
    players: const [],
    phase: BlackjackPhase.dealerTurn,
  );
}

void main() {
  group('BlackjackDealerAi - Hard 17 规则', () {
    const ai = BlackjackDealerAi(
      config: BlackjackGameConfig(dealerHitSoft17: false, dealerDelayMs: 0),
    );

    test('点数 ≤ 16 时 shouldHit = true', () {
      final hand = BlackjackHand(cards: [c(10), c(6)], bet: 0); // 16
      expect(ai.shouldHit(hand), isTrue);
    });

    test('Hard 17 时 shouldHit = false', () {
      final hand = BlackjackHand(cards: [c(10), c(7)], bet: 0); // 17
      expect(ai.shouldHit(hand), isFalse);
    });

    test('点数 > 17 时 shouldHit = false', () {
      final hand = BlackjackHand(cards: [c(10), c(9)], bet: 0); // 19
      expect(ai.shouldHit(hand), isFalse);
    });

    test('Soft 17，dealerHitSoft17=false → 不摸牌', () {
      final hand = BlackjackHand(cards: [c(1), c(6)], bet: 0); // A+6=Soft17
      expect(ai.shouldHit(hand), isFalse);
    });

    test('庄家从 15 点摸牌至 ≥17 停止', () {
      // 初始 [10,5]=15，牌堆 [3, K]，摸 3 → 18，停止
      final state = stateWithDealer([c(10), c(5)], deck: [c(3), c(13)]);
      final result = ai.runSync(state);
      expect(result.dealer.hands[0].value, 18);
      expect(result.dealer.hands[0].status, BlackjackHandStatus.stood);
    });

    test('庄家爆牌时标记 bust', () {
      // 初始 [10,8]=18 → 已 ≥17，停止；改为 [10,6]=16 摸 [7]=23
      final state = stateWithDealer([c(10), c(6)], deck: [c(7)]);
      final result = ai.runSync(state);
      expect(result.dealer.hands[0].isBust, isTrue);
      expect(result.dealer.hands[0].status, BlackjackHandStatus.bust);
    });
  });

  group('BlackjackDealerAi - Soft 17 配置', () {
    const aiSoft = BlackjackDealerAi(
      config: BlackjackGameConfig(dealerHitSoft17: true, dealerDelayMs: 0),
    );

    test('Soft 17，dealerHitSoft17=true → 摸牌', () {
      final hand = BlackjackHand(cards: [c(1), c(6)], bet: 0); // Soft 17
      expect(aiSoft.shouldHit(hand), isTrue);
    });

    test('Hard 17，dealerHitSoft17=true → 不摸牌', () {
      final hand = BlackjackHand(cards: [c(10), c(7)], bet: 0); // Hard 17
      expect(aiSoft.shouldHit(hand), isFalse);
    });
  });
}
