import 'package:poke_game/domain/blackjack/entities/blackjack_game_config.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';

/// AI 庄家策略：Hard 17 规则（Soft 17 可配置）
class BlackjackDealerAi {
  final BlackjackGameConfig config;

  const BlackjackDealerAi({required this.config});

  /// 判断庄家是否需要继续摸牌
  bool shouldHit(BlackjackHand hand) {
    final value = hand.value;
    if (value > 17) return false;
    if (value < 17) return true;
    // value == 17：Soft 17 时根据配置决定
    return hand.isSoft && config.dealerHitSoft17;
  }

  /// 执行庄家行动直到停止，每次 Hit 前等待 [config.dealerDelayMs]ms（可用 await 调用）
  /// 返回最终状态
  Future<BlackjackGameState> runAsync(BlackjackGameState state) async {
    var current = state;
    while (true) {
      final dealerHand =
          current.dealer.hands.isNotEmpty ? current.dealer.hands[0] : null;
      if (dealerHand == null || !shouldHit(dealerHand)) break;
      if (current.deck.isEmpty) break;

      await Future.delayed(Duration(milliseconds: config.dealerDelayMs));
      current = _dealerHit(current);
    }
    return _dealerStand(current);
  }

  /// 同步版本（测试用，无延迟）
  BlackjackGameState runSync(BlackjackGameState state) {
    var current = state;
    while (true) {
      final dealerHand =
          current.dealer.hands.isNotEmpty ? current.dealer.hands[0] : null;
      if (dealerHand == null || !shouldHit(dealerHand)) break;
      if (current.deck.isEmpty) break;
      current = _dealerHit(current);
    }
    return _dealerStand(current);
  }

  BlackjackGameState _dealerHit(BlackjackGameState state) {
    final deck = List.of(state.deck);
    final newCard = deck.removeAt(0);
    final hand = state.dealer.hands[0];
    final updatedHand = hand.copyWith(cards: [...hand.cards, newCard]);
    final newDealer = state.dealer.copyWith(hands: [updatedHand]);
    return state.copyWith(deck: deck, dealer: newDealer);
  }

  BlackjackGameState _dealerStand(BlackjackGameState state) {
    if (state.dealer.hands.isEmpty) return state;
    final hand = state.dealer.hands[0];
    final status = hand.isBust
        ? BlackjackHandStatus.bust
        : BlackjackHandStatus.stood;
    final updatedHand = hand.copyWith(status: status);
    final newDealer = state.dealer.copyWith(hands: [updatedHand]);
    return state.copyWith(dealer: newDealer);
  }
}
