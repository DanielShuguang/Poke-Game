import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';

/// 结算 Use Case：比较每手牌与庄家，计算赔付并更新筹码
class SettleUseCase {
  const SettleUseCase();

  /// 执行结算，返回阶段为 settlement 的新状态
  BlackjackGameState call(BlackjackGameState state) {
    final dealerHand = state.dealer.hands.isNotEmpty
        ? state.dealer.hands[0]
        : null;
    final dealerValue = dealerHand?.value ?? 0;
    final dealerBust = dealerHand?.isBust ?? false;
    final dealerBlackjack = dealerHand?.isBlackjack ?? false;

    final settledPlayers = state.players.map((player) {
      final settledHands = player.hands.map((hand) {
        final payout = _calculatePayout(
          hand: hand,
          dealerValue: dealerValue,
          dealerBust: dealerBust,
          dealerBlackjack: dealerBlackjack,
        );
        return hand.copyWith(bet: payout); // 用 bet 字段暂存赔付额（UI 显示用）
      }).toList();

      final totalPayout = settledHands.fold<int>(0, (sum, h) => sum + h.bet);
      return player.copyWith(
        hands: settledHands,
        chips: player.chips + totalPayout,
      );
    }).toList();

    return state.copyWith(
      players: settledPlayers,
      phase: BlackjackPhase.settlement,
    );
  }

  /// 计算单手牌赔付（正数=获得筹码，负数=损失筹码）
  /// 注意：Double 时 bet 已经翻倍，此处直接使用
  int _calculatePayout({
    required BlackjackHand hand,
    required int dealerValue,
    required bool dealerBust,
    required bool dealerBlackjack,
  }) {
    // 已投降：已在 Surrender 操作时退还半注，此处赔付 0
    if (hand.status == BlackjackHandStatus.surrendered) return 0;

    // 爆牌：输掉下注
    if (hand.status == BlackjackHandStatus.bust) return -hand.bet;

    // 五小龙：自动赢（按普通胜利 1:1 赔付）
    if (hand.status == BlackjackHandStatus.fiveCardCharlie) return hand.bet;

    final playerValue = hand.value;
    final playerBlackjack = hand.status == BlackjackHandStatus.blackjack;

    // 双方都是 Blackjack：平局，返还原注（净 0）
    if (playerBlackjack && dealerBlackjack) return 0;

    // 玩家 Blackjack，庄家非 Blackjack：1.5 倍赢利
    if (playerBlackjack && !dealerBlackjack) return (hand.bet * 1.5).toInt();

    // 庄家 Blackjack，玩家非 Blackjack：输掉下注
    if (dealerBlackjack && !playerBlackjack) return -hand.bet;

    // 庄家爆牌：玩家赢（1:1）
    if (dealerBust) return hand.bet;

    // 比点数
    if (playerValue > dealerValue) return hand.bet;
    if (playerValue == dealerValue) return 0; // 平局
    return -hand.bet; // 输
  }
}
