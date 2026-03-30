import 'package:poke_game/domain/niuniu/entities/niuniu_game_state.dart';

/// 牛牛结算 UseCase
///
/// 将每位闲家手牌与庄家比较，按倍率结算筹码。
/// 结算后 player.betAmount 存储净盈亏（正=赢，负=输），供 UI 展示。
class SettleNiuniuUseCase {
  const SettleNiuniuUseCase();

  NiuniuGameState call(NiuniuGameState state) {
    final banker = state.banker;
    if (banker?.hand == null) return state;

    final bankerHand = banker!.hand!;
    int bankerChipsDelta = 0;

    final updatedPlayers = state.players.map((player) {
      if (player.isBanker) return player; // 庄家后处理
      if (player.hand == null || player.betAmount == 0) return player;

      final punterHand = player.hand!;
      final multiplier = punterHand.multiplier;
      final payout = player.betAmount * multiplier;

      final cmp = punterHand.compareTo(bankerHand);
      int delta;
      if (cmp > 0) {
        // 闲家胜：赢庄家 payout
        delta = payout;
        bankerChipsDelta -= payout;
      } else {
        // 庄家胜或平局（平局庄家优先）：闲家输 payout
        delta = -payout;
        bankerChipsDelta += payout;
      }

      return player.copyWith(
        chips: player.chips + delta,
        // 复用 betAmount 字段存储结算净盈亏，供 UI 显示
        betAmount: delta,
      );
    }).toList();

    // 更新庄家筹码
    final updatedWithBanker = updatedPlayers.map((p) {
      if (p.id != banker.id) return p;
      return p.copyWith(
        chips: p.chips + bankerChipsDelta,
        betAmount: bankerChipsDelta,
      );
    }).toList();

    return state.copyWith(
      players: updatedWithBanker,
      phase: NiuniuPhase.settlement,
    );
  }
}
