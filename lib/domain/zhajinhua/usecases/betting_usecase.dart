import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';

/// 下注动作类型
enum BettingAction { call, raise, fold }

/// 下注用例：处理跟注/加注/弃牌，更新底池和筹码
class BettingUsecase {
  /// 执行下注动作，返回更新后的游戏状态
  ZhjGameState execute(ZhjGameState state, BettingAction action) {
    final players = List<ZhjPlayer>.from(state.players);
    final player = players[state.currentPlayerIndex];

    switch (action) {
      case BettingAction.call:
        return _handleCall(state, players, player);
      case BettingAction.raise:
        return _handleRaise(state, players, player);
      case BettingAction.fold:
        return _handleFold(state, players, player);
    }
  }

  ZhjGameState _handleCall(
    ZhjGameState state,
    List<ZhjPlayer> players,
    ZhjPlayer player,
  ) {
    // 看牌后跟注金额 × 2，蒙牌跟注 × 1
    final multiplier = player.hasPeeked ? 2 : 1;
    final amount = (state.currentBet * multiplier).clamp(0, player.chips);
    players[state.currentPlayerIndex] = player.copyWith(
      chips: player.chips - amount,
      betAmount: player.betAmount + amount,
    );
    return state.copyWith(
      players: players,
      pot: state.pot + amount,
    );
  }

  ZhjGameState _handleRaise(
    ZhjGameState state,
    List<ZhjPlayer> players,
    ZhjPlayer player,
  ) {
    // 加注：当前底注翻倍，自己先跟注新底注
    final newBet = state.currentBet * 2;
    final multiplier = player.hasPeeked ? 2 : 1;
    final amount = (newBet * multiplier).clamp(0, player.chips);
    players[state.currentPlayerIndex] = player.copyWith(
      chips: player.chips - amount,
      betAmount: player.betAmount + amount,
    );
    return state.copyWith(
      players: players,
      pot: state.pot + amount,
      currentBet: newBet,
    );
  }

  ZhjGameState _handleFold(
    ZhjGameState state,
    List<ZhjPlayer> players,
    ZhjPlayer player,
  ) {
    players[state.currentPlayerIndex] = player.copyWith(isFolded: true);
    return state.copyWith(players: players);
  }
}
