import 'package:logger/logger.dart';
import 'package:poke_game/core/network/game_event_repository.dart';
import 'package:poke_game/core/network/game_operation_handler.dart';
import 'package:poke_game/core/network/websocket_manager.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/lan/entities/game_event.dart';

/// 游戏状态同步服务（房主端）
class GameStateSyncService {
  final GameEventRepository _eventRepo;
  final GameOperationBroadcaster _broadcaster;

  GameStateSyncService(WebSocketManager wsManager, this._eventRepo)
      : _broadcaster = GameOperationBroadcaster(wsManager);

  /// 同步发牌事件
  void syncDealCards(String playerId, List<Card> cards) {
    _eventRepo.addEvent(GameEventType.deal, {'cardIds': cards.map((c) => '${c.suit.index}:${c.rank}').toList()}, targetPlayerId: playerId);
    _broadcaster.broadcastDealCards({playerId: cards});
  }

  /// 同步出牌事件
  void syncPlayCards(String playerId, List<Card> cards) {
    _eventRepo.addEvent(GameEventType.playCards, {'cards': cards.map((c) => '${c.suit.index}:${c.rank}').toList()}, senderId: playerId);
    _broadcaster.broadcastPlayCards(playerId, cards);
  }

  /// 同步叫地主事件
  void syncCallLandlord(String playerId, bool call) {
    _eventRepo.addEvent(GameEventType.callLandlord, {'call': call}, senderId: playerId);
    _broadcaster.broadcastCallLandlord(playerId, call);
  }

  /// 同步游戏状态
  void syncGameState(GameState state, String targetPlayerId) {
    _broadcaster.sendGameState(state, targetPlayerId);
  }

  /// 获取事件仓库
  GameEventRepository get eventRepository => _eventRepo;
}

/// 断线处理器
class DisconnectionHandler {
  final Logger _logger = Logger();
  final Duration reconnectTimeout;

  DisconnectionHandler({this.reconnectTimeout = const Duration(seconds: 60)});

  /// 处理玩家断线
  void handleDisconnection(String playerId, GameState gameState, void Function(String) onPause, void Function(String) onTimeout) {
    _logger.w('玩家断线: $playerId');
    onPause(playerId);

    // 等待重连
    Future.delayed(reconnectTimeout, () {
      onTimeout(playerId);
    });
  }

  /// 处理玩家重连
  void handleReconnection(String playerId, GameState gameState, void Function(String) onResume) {
    _logger.i('玩家重连: $playerId');
    onResume(playerId);
  }
}
