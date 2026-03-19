import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';

/// 叫地主结果
class CallLandlordResult {
  final GameState gameState;
  final bool allPassed;

  const CallLandlordResult({
    required this.gameState,
    this.allPassed = false,
  });
}

/// 叫地主用例
class CallLandlordUseCase {
  /// 是否为人机对战模式
  final bool isHumanVsAi;

  const CallLandlordUseCase({this.isHumanVsAi = true});

  /// 处理叫地主
  CallLandlordResult call(GameState state, String playerId, bool call) {
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

      return CallLandlordResult(
        gameState: state.copyWith(
          phase: GamePhase.playing,
          landlordIndex: playerIndex,
          currentPlayerIndex: playerIndex,
          lastPlayedCards: null,
          lastPlayerIndex: null,
        ),
      );
    }

    // 不叫，检查是否全部不叫
    final newCallCount = state.callCount + 1;

    // 人机模式下，如果人类玩家（index 0）不叫，且只剩下最后一个AI没叫
    // 则最后一个AI必须叫地主
    if (isHumanVsAi && playerIndex == 0 && newCallCount == state.players.length - 1) {
      // 最后一个AI强制叫地主
      final lastAiIndex = state.players.length - 1;
      final lastAi = state.players[lastAiIndex];
      lastAi.role = PlayerRole.landlord;
      lastAi.handCards = [...lastAi.handCards, ...state.landlordCards];
      lastAi.handCards.sort();

      // 设置其他玩家为农民
      for (var i = 0; i < state.players.length; i++) {
        if (i != lastAiIndex) {
          state.players[i].role = PlayerRole.peasant;
        }
      }

      return CallLandlordResult(
        gameState: state.copyWith(
          phase: GamePhase.playing,
          landlordIndex: lastAiIndex,
          currentPlayerIndex: lastAiIndex,
          lastPlayedCards: null,
          lastPlayerIndex: null,
        ),
      );
    }

    if (newCallCount >= state.players.length) {
      // 非人机模式下，全部不叫，重新开始
      return CallLandlordResult(
        gameState: GameState.initial(),
        allPassed: true,
      );
    }

    // 下一个玩家叫地主
    final nextPlayerIndex = (playerIndex + 1) % state.players.length;
    return CallLandlordResult(
      gameState: state.copyWith(
        callingPlayerIndex: nextPlayerIndex,
        callCount: newCallCount,
      ),
    );
  }
}
