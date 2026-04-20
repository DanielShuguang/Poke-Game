import 'package:poke_game/core/network/game_network_adapter.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_network_action.dart';
import 'package:poke_game/presentation/pages/zhajinhua/providers/zhj_game_notifier.dart';

/// 炸金花网络适配器
///
/// Host：接收客户端行动、验证后更新状态、广播新状态。
/// Client：发送行动给 Host，接收状态广播更新 UI。
class ZhjNetworkAdapter extends GameNetworkAdapter {
  final ZhjGameNotifier _notifier;

  ZhjNetworkAdapter({
    required super.incomingStream,
    required super.broadcastFn,
    required ZhjGameNotifier notifier,
    required super.isHost,
    required super.localPlayerId,
    super.turnTimeLimit = 35,
  }) : _notifier = notifier;

  @override
  dynamic get notifier => _notifier;

  @override
  String get actionMessageType => 'zhj_action';

  @override
  String get stateMessageType => 'zhj_state_sync';

  @override
  dynamic get currentState => _notifier.currentState;

  @override
  Map<String, dynamic> serializeState(dynamic state, {bool includeAllCards = false}) {
    return (state as ZhjGameState).toJson(includeAllCards: true);
  }

  @override
  dynamic deserializeAction(Map<String, dynamic> data) {
    return ZhjNetworkAction.fromJson(data);
  }

  @override
  bool shouldProcessAction(dynamic action, dynamic state) {
    final networkAction = action as ZhjNetworkAction;
    final s = state as ZhjGameState;
    if (s.phase != ZhjGamePhase.betting) return false;
    final currentPlayer = s.currentPlayer;
    return currentPlayer.id == networkAction.playerId;
  }

  @override
  void executeAction(dynamic action) {
    final networkAction = action as ZhjNetworkAction;
    switch (networkAction.actionType) {
      case ZhjActionType.peek:
        _notifier.networkPeek(networkAction.playerId);
      case ZhjActionType.call:
        _notifier.networkCall(networkAction.playerId);
      case ZhjActionType.raise:
        _notifier.networkRaise(networkAction.playerId);
      case ZhjActionType.fold:
        _notifier.networkFold(networkAction.playerId);
      case ZhjActionType.showdown:
        if (networkAction.targetPlayerIndex != null) {
          _notifier.networkShowdown(networkAction.playerId, networkAction.targetPlayerIndex!);
        }
    }
  }

  @override
  void applyNetworkState(Map<String, dynamic> data) {
    final newState = ZhjGameState.fromJson(data, localPlayerId: localPlayerId);
    _notifier.applyNetworkState(newState);
  }

  @override
  bool includeAllCardsInState(dynamic state) => true;

  @override
  bool shouldTrackTimeout(dynamic state) {
    final s = state as ZhjGameState;
    return s.phase == ZhjGamePhase.betting;
  }

  @override
  String? currentNonAiPlayerId(dynamic state) {
    final s = state as ZhjGameState;
    return s.currentPlayer.id;
  }

  @override
  void onTimeout(String playerId) {
    _notifier.forcePlayerFold(playerId);
  }

  /// 发送玩家行动（客户端调用）
  void sendAction(ZhjNetworkAction action) {
    broadcastFn({
      'type': actionMessageType,
      'data': action.toJson(),
    });
  }

  void dispose() {
    stop();
  }
}
