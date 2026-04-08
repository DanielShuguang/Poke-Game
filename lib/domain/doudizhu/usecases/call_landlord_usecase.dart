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

    // 人机模式：若人类玩家（index 0）不叫且只剩一名AI未表态，强制该AI叫地主
    if (isHumanVsAi &&
        playerIndex == 0 &&
        newCallCount == state.players.length - 1) {
      final forcedAiIndex = state.players.length - 1;
      final forcedAi = state.players[forcedAiIndex];
      forcedAi.role = PlayerRole.landlord;
      forcedAi.handCards = [...forcedAi.handCards, ...state.landlordCards];
      forcedAi.handCards.sort();
      for (var i = 0; i < state.players.length; i++) {
        if (i != forcedAiIndex) {
          state.players[i].role = PlayerRole.peasant;
        }
      }
      return CallLandlordResult(
        gameState: state.copyWith(
          phase: GamePhase.playing,
          landlordIndex: forcedAiIndex,
          currentPlayerIndex: forcedAiIndex,
          lastPlayedCards: null,
          lastPlayerIndex: null,
        ),
      );
    }

    if (newCallCount >= state.players.length) {
      if (isHumanVsAi) {
        // 人机模式：不允许全部不叫，强制最后一名AI（index 末位）叫地主
        final forcedAiIndex = state.players.length - 1;
        final forcedAi = state.players[forcedAiIndex];
        forcedAi.role = PlayerRole.landlord;
        forcedAi.handCards = [...forcedAi.handCards, ...state.landlordCards];
        forcedAi.handCards.sort();

        for (var i = 0; i < state.players.length; i++) {
          if (i != forcedAiIndex) {
            state.players[i].role = PlayerRole.peasant;
          }
        }

        return CallLandlordResult(
          gameState: state.copyWith(
            phase: GamePhase.playing,
            landlordIndex: forcedAiIndex,
            currentPlayerIndex: forcedAiIndex,
            lastPlayedCards: null,
            lastPlayerIndex: null,
          ),
        );
      }

      // 非人机模式：全部不叫，重新开始
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
