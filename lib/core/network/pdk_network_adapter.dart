import 'package:poke_game/core/network/game_network_adapter.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_game_state.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_network_action.dart';
import 'package:poke_game/presentation/pages/paodekai/providers/pdk_notifier.dart';

/// 跑得快网络适配器
///
/// Host：接收 Client 出牌/pass 行动 → 执行 → 广播新状态。
/// Client：发送行动给 Host，接收状态广播更新本地 UI。
class PdkNetworkAdapter extends GameNetworkAdapter {
  final PdkGameNotifier _notifier;

  PdkNetworkAdapter({
    required super.incomingStream,
    required super.broadcastFn,
    required PdkGameNotifier notifier,
    required super.isHost,
    required super.localPlayerId,
    super.turnTimeLimit = 35,
  }) : _notifier = notifier;

  @override
  dynamic get notifier => _notifier;

  @override
  String get actionMessageType => 'pdk_action';

  @override
  String get stateMessageType => 'pdk_state';

  @override
  dynamic get currentState => _notifier.currentState;

  @override
  Map<String, dynamic> serializeState(dynamic state, {bool includeAllCards = false}) {
    return (state as PdkGameState).toJson();
  }

  @override
  dynamic deserializeAction(Map<String, dynamic> data) {
    return PdkNetworkAction.fromJson(data);
  }

  @override
  bool shouldProcessAction(dynamic action, dynamic state) {
    final networkAction = action as PdkNetworkAction;
    final s = state as PdkGameState;
    if (s.phase != PdkGamePhase.playing) return false;
    if (s.players.isEmpty) return false;
    return s.currentPlayer.id == networkAction.playerId;
  }

  @override
  void executeAction(dynamic action) {
    final networkAction = action as PdkNetworkAction;
    switch (networkAction.action) {
      case PdkActionType.playCards:
        _notifier.playCards(networkAction.playerId, networkAction.cards);
      case PdkActionType.pass:
        _notifier.pass(networkAction.playerId);
      case PdkActionType.forcePlayCards:
        _notifier.forcePlayCards(networkAction.playerId);
      case PdkActionType.forcePass:
        _notifier.forcePass(networkAction.playerId);
    }
  }

  @override
  void applyNetworkState(Map<String, dynamic> data) {
    final newState = PdkGameState.fromJson(data);
    _notifier.syncState(newState);
  }

  @override
  bool includeAllCardsInState(dynamic state) => false;

  @override
  bool shouldTrackTimeout(dynamic state) {
    final s = state as PdkGameState;
    return s.phase == PdkGamePhase.playing && s.players.isNotEmpty;
  }

  @override
  String? currentNonAiPlayerId(dynamic state) {
    final s = state as PdkGameState;
    if (s.players.isEmpty) return null;
    return s.currentPlayer.id;
  }

  @override
  void onTimeout(String playerId) {
    final current = _notifier.currentState;
    if (current.lastPlayedHand == null) {
      _notifier.forcePlayCards(playerId);
    } else {
      _notifier.forcePass(playerId);
    }
  }

  /// Client 发送行动给 Host
  void sendAction(PdkNetworkAction action) {
    broadcastFn({'type': actionMessageType, 'data': action.toJson()});
  }

  /// Host 主动广播当前状态
  @override
  void broadcastCurrentState() {
    doBroadcastState();
  }
}
