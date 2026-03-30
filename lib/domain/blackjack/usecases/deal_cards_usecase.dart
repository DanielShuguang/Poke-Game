import 'dart:math';

import 'package:poke_game/domain/blackjack/entities/blackjack_card.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_config.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';

/// 发牌 Use Case：洗牌并向所有玩家和庄家各发两张牌
class DealCardsUseCase {
  /// 生成并洗好的牌堆（[config.deckCount] 副标准牌）
  static List<BlackjackCard> buildShuffledDeck(BlackjackGameConfig config) {
    final deck = <BlackjackCard>[];
    for (int i = 0; i < config.deckCount; i++) {
      deck.addAll(BlackjackCard.standardDeck());
    }
    deck.shuffle(Random());
    return deck;
  }

  /// 执行发牌：从 [state] 中取牌堆，向所有玩家和庄家各发 2 张
  /// 返回更新后的 [BlackjackGameState]（阶段变为 playerTurn）
  BlackjackGameState call(BlackjackGameState state) {
    final deck = List<BlackjackCard>.of(state.deck);

    BlackjackCard drawCard() {
      if (deck.isEmpty) {
        throw StateError('牌堆已空，无法继续发牌');
      }
      return deck.removeAt(0);
    }

    // 为每位玩家发两张牌（保留已下注金额）
    final dealtPlayers = state.players.map((player) {
      final bet = player.hands.isNotEmpty ? player.hands[0].bet : 0;
      final hand = BlackjackHand(
        cards: [drawCard(), drawCard()],
        bet: bet,
      );
      // 判断 Blackjack
      final handWithStatus = hand.isBlackjack
          ? hand.copyWith(status: BlackjackHandStatus.blackjack)
          : hand;
      return player.copyWith(hands: [handWithStatus], activeHandIndex: 0);
    }).toList();

    // 庄家发两张牌（明牌 + 暗牌，暗牌在 index 1）
    final dealerHand = BlackjackHand(
      cards: [drawCard(), drawCard()],
      bet: 0,
    );
    final dealtDealer = state.dealer.copyWith(
      hands: [dealerHand],
      activeHandIndex: 0,
    );

    // 若所有玩家都是 Blackjack，直接进入庄家阶段
    final allBlackjack =
        dealtPlayers.every((p) => p.hands[0].status == BlackjackHandStatus.blackjack);

    return state.copyWith(
      deck: deck,
      players: dealtPlayers,
      dealer: dealtDealer,
      currentPlayerIndex: 0,
      phase: allBlackjack ? BlackjackPhase.dealerTurn : BlackjackPhase.playerTurn,
      clearMessage: true,
    );
  }
}
