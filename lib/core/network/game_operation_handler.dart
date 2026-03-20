import 'package:logger/logger.dart';
import 'package:poke_game/core/network/game_state_serializer.dart';
import 'package:poke_game/core/network/websocket_manager.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';

/// 游戏操作验证器
///
/// 验证玩家操作的合法性
class GameOperationValidator {
  final Logger _logger = Logger();

  /// 验证出牌操作
  ValidationResult validatePlayCards({
    required GameState gameState,
    required String playerId,
    required List<Card> cards,
  }) {
    // 检查游戏阶段
    if (gameState.phase != GamePhase.playing) {
      return ValidationResult.failure('游戏未处于出牌阶段');
    }

    // 检查是否轮到该玩家
    final currentPlayer = gameState.currentPlayer;
    if (currentPlayer == null || currentPlayer.id != playerId) {
      return ValidationResult.failure('未轮到该玩家出牌');
    }

    // 检查玩家是否拥有这些牌
    final playerHand = currentPlayer.handCards;
    for (final card in cards) {
      if (!playerHand.contains(card)) {
        return ValidationResult.failure('玩家不拥有这些牌');
      }
    }

    // 验证牌型
    final cardType = const CardValidator().validate(cards);
    if (cardType == null) {
      return ValidationResult.failure('无效的牌型');
    }

    // 检查是否能压过上家
    if (gameState.lastPlayedCards != null && gameState.lastPlayerIndex != null) {
      // 如果上家是自己，可以出任意牌
      if (gameState.lastPlayerIndex == gameState.currentPlayerIndex) {
        return ValidationResult.success();
      }

      // 检查是否能压过
      if (!const CardValidator().canBeat(cards, gameState.lastPlayedCards!)) {
        return ValidationResult.failure('出的牌不能压过上家');
      }
    }

    return ValidationResult.success();
  }

  /// 验证叫地主操作
  ValidationResult validateCallLandlord({
    required GameState gameState,
    required String playerId,
  }) {
    // 检查游戏阶段
    if (gameState.phase != GamePhase.calling) {
      return ValidationResult.failure('游戏未处于叫地主阶段');
    }

    // 检查是否轮到该玩家
    if (gameState.callingPlayerIndex == null) {
      return ValidationResult.failure('无当前叫地主玩家');
    }

    final callingPlayer = gameState.players[gameState.callingPlayerIndex!];
    if (callingPlayer.id != playerId) {
      return ValidationResult.failure('未轮到该玩家叫地主');
    }

    return ValidationResult.success();
  }

  /// 验证过牌操作
  ValidationResult validatePass({
    required GameState gameState,
    required String playerId,
  }) {
    // 检查游戏阶段
    if (gameState.phase != GamePhase.playing) {
      return ValidationResult.failure('游戏未处于出牌阶段');
    }

    // 检查是否轮到该玩家
    final currentPlayer = gameState.currentPlayer;
    if (currentPlayer == null || currentPlayer.id != playerId) {
      return ValidationResult.failure('未轮到该玩家');
    }

    // 检查是否必须出牌（新一轮开始）
    if (gameState.lastPlayedCards == null) {
      return ValidationResult.failure('新一轮必须出牌');
    }

    // 检查是否是自己出的牌
    if (gameState.lastPlayerIndex == gameState.currentPlayerIndex) {
      return ValidationResult.failure('自己出的牌必须接');
    }

    return ValidationResult.success();
  }
}

/// 验证结果
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult.success() : isValid = true, errorMessage = null;
  ValidationResult.failure(this.errorMessage) : isValid = false;
}

/// 游戏操作广播器
///
/// 负责广播游戏操作到所有玩家
class GameOperationBroadcaster {
  final Logger _logger = Logger();
  final WebSocketManager _webSocketManager;
  final GameStateSerializer _serializer = GameStateSerializer();

  GameOperationBroadcaster(this._webSocketManager);

  /// 广播发牌事件（定向发送给每个玩家自己的牌）
  void broadcastDealCards(Map<String, List<Card>> playerCards) {
    playerCards.forEach((playerId, cards) {
      final data = DealData(playerId: playerId, cards: cards);

      _webSocketManager.sendToPlayer(playerId, {
        'type': 'deal_cards',
        'data': data.toJson(),
      });

      _logger.d('发牌已发送给玩家: $playerId, ${cards.length} 张牌');
    });
  }

  /// 广播出牌事件
  void broadcastPlayCards(String playerId, List<Card> cards) {
    final data = PlayCardsData(playerId: playerId, cards: cards);

    _webSocketManager.broadcast({
      'type': 'play_cards',
      'data': data.toJson(),
    });

    _logger.i('出牌已广播: $playerId 出了 ${cards.length} 张牌');
  }

  /// 广播过牌事件
  void broadcastPass(String playerId) {
    _webSocketManager.broadcast({
      'type': 'pass',
      'playerId': playerId,
    });

    _logger.i('过牌已广播: $playerId');
  }

  /// 广播叫地主事件
  void broadcastCallLandlord(String playerId, bool call) {
    final data = CallLandlordData(playerId: playerId, call: call);

    _webSocketManager.broadcast({
      'type': 'call_landlord',
      'data': data.toJson(),
    });

    _logger.i('叫地主已广播: $playerId -> $call');
  }

  /// 广播地主确定事件
  void broadcastLandlordDetermined(String landlordId, List<Card> landlordCards) {
    _webSocketManager.broadcast({
      'type': 'landlord_determined',
      'landlordId': landlordId,
      'landlordCards': _serializer.serializeCards(landlordCards),
    });

    _logger.i('地主已确定: $landlordId');
  }

  /// 广播游戏开始事件
  void broadcastGameStart() {
    _webSocketManager.broadcast({
      'type': 'game_start',
    });

    _logger.i('游戏开始已广播');
  }

  /// 广播游戏结束事件
  void broadcastGameEnd(Map<String, dynamic> result) {
    _webSocketManager.broadcast({
      'type': 'game_end',
      'result': result,
    });

    _logger.i('游戏结束已广播');
  }

  /// 广播当前回合变更
  void broadcastTurnChange(int currentPlayerIndex) {
    _webSocketManager.broadcast({
      'type': 'turn_change',
      'currentPlayerIndex': currentPlayerIndex,
    });

    _logger.d('回合变更已广播: 玩家 $currentPlayerIndex');
  }

  /// 发送完整游戏状态给指定玩家
  void sendGameState(GameState state, String playerId) {
    final stateJson = _serializer.serializeGameStateForPlayer(state, playerId);

    _webSocketManager.sendToPlayer(playerId, {
      'type': 'game_state_sync',
      'state': stateJson,
    });

    _logger.d('游戏状态已发送给玩家: $playerId');
  }
}
