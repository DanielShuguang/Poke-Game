import 'package:poke_game/core/network/game_network_adapter.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_network_action.dart';
import 'package:poke_game/presentation/pages/blackjack/providers/blackjack_game_notifier.dart';

/// 21点网络适配器
///
/// Host：接收 Client 行动 → 验证 → 执行 → 广播新状态。
/// Client：发送行动给 Host，接收状态广播更新本地 UI。
class BlackjackNetworkAdapter extends GameNetworkAdapter {
  final BlackjackGameNotifier _notifier;

  BlackjackNetworkAdapter({
    required super.incomingStream,
    required super.broadcastFn,
    required BlackjackGameNotifier notifier,
    required super.isHost,
    required super.localPlayerId,
    super.turnTimeLimit = 35,
  }) : _notifier = notifier;

  @override
  dynamic get notifier => _notifier;

  @override
  String get actionMessageType => 'blackjack_action';

  @override
  String get stateMessageType => 'blackjack_state';

  @override
  dynamic get currentState => _notifier.currentState;

  @override
  Map<String, dynamic> serializeState(dynamic state,
      {bool includeAllCards = false}) {
    return (state as BlackjackGameState).toJson(includeAllCards: includeAllCards);
  }

  @override
  dynamic deserializeAction(Map<String, dynamic> data) {
    return BlackjackNetworkAction.fromJson(data);
  }

  @override
  bool shouldProcessAction(dynamic action, dynamic state) {
    final networkAction = action as BlackjackNetworkAction;
    final s = state as BlackjackGameState;
    final currentPlayer = s.currentPlayer;
    if (currentPlayer == null) return false;
    return currentPlayer.id == networkAction.playerId;
  }

  @override
  void executeAction(dynamic action) {
    final networkAction = action as BlackjackNetworkAction;
    switch (networkAction.action) {
      case BlackjackActionType.hit:
        _notifier.networkHit(networkAction.playerId);
      case BlackjackActionType.stand:
        _notifier.networkStand(networkAction.playerId);
      case BlackjackActionType.doubleDown:
        _notifier.networkDoubleDown(networkAction.playerId);
      case BlackjackActionType.split:
        _notifier.networkSplit(networkAction.playerId);
      case BlackjackActionType.surrender:
        _notifier.networkSurrender(networkAction.playerId);
    }
  }

  @override
  void applyNetworkState(Map<String, dynamic> data) {
    final newState = BlackjackGameState.fromJson(data, localPlayerId: localPlayerId);
    _notifier.applyNetworkState(newState);
  }

  @override
  bool includeAllCardsInState(dynamic state) => false;

  @override
  bool shouldTrackTimeout(dynamic state) {
    final s = state as BlackjackGameState;
    return s.currentPlayer != null;
  }

  @override
  String? currentNonAiPlayerId(dynamic state) {
    final s = state as BlackjackGameState;
    return s.currentPlayer?.id;
  }

  @override
  void onTimeout(String playerId) {
    _notifier.forcePlayerStand(playerId);
  }

  /// Client 发送行动
  void sendAction(BlackjackNetworkAction action) {
    broadcastFn({'type': actionMessageType, 'data': action.toJson()});
  }
}
