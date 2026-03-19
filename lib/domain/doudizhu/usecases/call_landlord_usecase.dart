import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';

/// 叫地主用例
class CallLandlordUseCase {
  /// 处理叫地主
  GameState call(GameState state, String playerId, bool call) {
    final playerIndex = state.players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) {
      throw ArgumentError('玩家不存在');
    }

    if (call) {
      // 叫地主成功
      final player = state.players[playerIndex];
      player.role = PlayerRole.landlord;
      player.handCards = [...player.handCards, ...state.landlordCards];
      player.handCards.sort();

      // 设置其他玩家为农民
      for (var i = 0; i < state.players.length; i++) {
        if (i != playerIndex) {
          state.players[i].role = PlayerRole.peasant;
        }
      }

      return state.copyWith(
        phase: GamePhase.playing,
        landlordIndex: playerIndex,
        currentPlayerIndex: playerIndex,
        lastPlayedCards: null,
        lastPlayerIndex: null,
      );
    }

    // 不叫，检查是否全部不叫
    final newCallCount = state.callCount + 1;
    if (newCallCount >= state.players.length) {
      // 全部不叫，重新开始
      return GameState.initial();
    }

    // 下一个玩家叫地主
    final nextPlayerIndex = (playerIndex + 1) % state.players.length;
    return state.copyWith(
      callingPlayerIndex: nextPlayerIndex,
      callCount: newCallCount,
    );
  }
}
