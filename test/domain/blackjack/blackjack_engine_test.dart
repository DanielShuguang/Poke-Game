import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_card.dart';

import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_player.dart';
import 'package:poke_game/domain/blackjack/usecases/settle_usecase.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';

void main() {
  group('BlackjackHand - 点数计算', () {
    BlackjackCard card(int rank) =>
        BlackjackCard(suit: Suit.spade, rank: rank);

    test('普通数字牌加总', () {
      final hand = BlackjackHand(
        cards: [card(5), card(8)],
        bet: 10,
      );
      expect(hand.value, 13);
    });

    test('J/Q/K 计为 10', () {
      final hand = BlackjackHand(
        cards: [card(11), card(12), card(13)],
        bet: 10,
      );
      expect(hand.value, 30);
    });

    test('A 默认计 11，不爆时保持', () {
      final hand = BlackjackHand(
        cards: [card(1), card(8)], // A + 8 = 19
        bet: 10,
      );
      expect(hand.value, 19);
      expect(hand.isSoft, isTrue);
    });

    test('A 自动切换为 1 避免爆牌', () {
      final hand = BlackjackHand(
        cards: [card(1), card(8), card(5)], // A+8+5: 11+8+5=24 → 1+8+5=14
        bet: 10,
      );
      expect(hand.value, 14);
      expect(hand.isBust, isFalse);
    });

    test('双 A：一个计 11，一个计 1', () {
      final hand = BlackjackHand(
        cards: [card(1), card(1), card(9)], // 11+1+9=21
        bet: 10,
      );
      expect(hand.value, 21);
    });

    test('爆牌判定', () {
      final hand = BlackjackHand(
        cards: [card(10), card(8), card(6)], // 24
        bet: 10,
      );
      expect(hand.isBust, isTrue);
    });

    test('Blackjack 识别 (A + K)', () {
      final hand = BlackjackHand(
        cards: [card(1), card(13)],
        bet: 10,
      );
      expect(hand.isBlackjack, isTrue);
      expect(hand.value, 21);
    });

    test('21点但非首两张不是 Blackjack', () {
      final hand = BlackjackHand(
        cards: [card(7), card(7), card(7)], // 21
        bet: 10,
      );
      expect(hand.isBlackjack, isFalse);
      expect(hand.value, 21);
    });

    test('Split 判定：两张同点值', () {
      final hand = BlackjackHand(
        cards: [card(10), card(13)], // 10 和 K 均计 10
        bet: 10,
      );
      expect(hand.canSplit, isTrue);
    });

    test('Split 判定：点值不同不可 Split', () {
      final hand = BlackjackHand(
        cards: [card(8), card(9)],
        bet: 10,
      );
      expect(hand.canSplit, isFalse);
    });
  });

  group('SettleUseCase - 结算', () {
    const settle = SettleUseCase();
    BlackjackCard card(int rank) =>
        BlackjackCard(suit: Suit.spade, rank: rank);

    BlackjackGameState makeState({
      required List<BlackjackCard> playerCards,
      required List<BlackjackCard> dealerCards,
      BlackjackHandStatus playerStatus = BlackjackHandStatus.stood,
      int bet = 100,
    }) {
      final playerHand = BlackjackHand(
        cards: playerCards,
        status: playerStatus,
        bet: bet,
      );
      final dealerHand = BlackjackHand(
        cards: dealerCards,
        status: BlackjackHandStatus.stood,
        bet: 0,
      );
      return BlackjackGameState(
        deck: const [],
        dealer: BlackjackPlayer(
          id: 'dealer',
          name: '庄家',
          isAi: true,
          isDealer: true,
          chips: 0,
          hands: [dealerHand],
        ),
        players: [
          BlackjackPlayer(
            id: 'p1',
            name: '玩家',
            isAi: false,
            chips: 900,
            hands: [playerHand],
          ),
        ],
        phase: BlackjackPhase.dealerTurn,
      );
    }

    test('玩家赢（点数更高）', () {
      final state = makeState(
        playerCards: [card(10), card(9)], // 19
        dealerCards: [card(10), card(7)], // 17
      );
      final result = settle(state);
      expect(result.players[0].chips, 900 + 100); // 净盈 100
    });

    test('玩家输（点数更低）', () {
      final state = makeState(
        playerCards: [card(10), card(6)], // 16
        dealerCards: [card(10), card(9)], // 19
      );
      final result = settle(state);
      expect(result.players[0].chips, 900 - 100);
    });

    test('平局（Push）', () {
      final state = makeState(
        playerCards: [card(10), card(8)], // 18
        dealerCards: [card(10), card(8)], // 18
      );
      final result = settle(state);
      expect(result.players[0].chips, 900); // 不变
    });

    test('庄家爆牌，玩家赢', () {
      final dealerBustHand = BlackjackHand(
        cards: [card(10), card(8), card(6)], // 24
        status: BlackjackHandStatus.bust,
        bet: 0,
      );
      final playerHand = BlackjackHand(
        cards: [card(10), card(7)], // 17
        status: BlackjackHandStatus.stood,
        bet: 100,
      );
      final state = BlackjackGameState(
        deck: const [],
        dealer: BlackjackPlayer(
          id: 'dealer',
          name: '庄家',
          isAi: true,
          isDealer: true,
          chips: 0,
          hands: [dealerBustHand],
        ),
        players: [
          BlackjackPlayer(
            id: 'p1',
            name: '玩家',
            isAi: false,
            chips: 900,
            hands: [playerHand],
          ),
        ],
        phase: BlackjackPhase.dealerTurn,
      );
      final result = settle(state);
      expect(result.players[0].chips, 900 + 100);
    });

    test('玩家 Blackjack，庄家非 Blackjack：1.5x 赔率', () {
      final state = makeState(
        playerCards: [card(1), card(13)], // Blackjack
        dealerCards: [card(10), card(8)], // 18
        playerStatus: BlackjackHandStatus.blackjack,
        bet: 100,
      );
      final result = settle(state);
      expect(result.players[0].chips, 900 + 150);
    });

    test('双方 Blackjack：平局', () {
      final dealerBJHand = BlackjackHand(
        cards: [card(1), card(13)],
        status: BlackjackHandStatus.blackjack,
        bet: 0,
      );
      final playerHand = BlackjackHand(
        cards: [card(1), card(11)],
        status: BlackjackHandStatus.blackjack,
        bet: 100,
      );
      final state = BlackjackGameState(
        deck: const [],
        dealer: BlackjackPlayer(
          id: 'dealer',
          name: '庄家',
          isAi: true,
          isDealer: true,
          chips: 0,
          hands: [dealerBJHand],
        ),
        players: [
          BlackjackPlayer(
            id: 'p1',
            name: '玩家',
            isAi: false,
            chips: 900,
            hands: [playerHand],
          ),
        ],
        phase: BlackjackPhase.dealerTurn,
      );
      final result = settle(state);
      expect(result.players[0].chips, 900); // 平局，筹码不变
    });

    test('玩家爆牌，输掉下注', () {
      final state = makeState(
        playerCards: [card(10), card(8), card(6)], // 24
        dealerCards: [card(10), card(7)],
        playerStatus: BlackjackHandStatus.bust,
      );
      final result = settle(state);
      expect(result.players[0].chips, 900 - 100);
    });

    test('结算后阶段为 settlement', () {
      final state = makeState(
        playerCards: [card(10), card(8)],
        dealerCards: [card(10), card(7)],
      );
      final result = settle(state);
      expect(result.phase, BlackjackPhase.settlement);
    });
  });
}
