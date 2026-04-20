import 'package:poke_game/core/network/game_network_adapter.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_game_state.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_network_action.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_player.dart';
import 'package:poke_game/presentation/pages/niuniu/providers/niuniu_game_notifier.dart';

/// 斗牛网络适配器
///
/// Host：接收 Client 下注行动 → 验证 → 执行 → 广播新状态。
/// Client：发送行动给 Host，接收状态广播更新本地 UI。
class NiuniuNetworkAdapter extends GameNetworkAdapter {
  final NiuniuGameNotifier _notifier;

  NiuniuNetworkAdapter({
    required super.incomingStream,
    required super.broadcastFn,
    required NiuniuGameNotifier notifier,
    required super.isHost,
    required super.localPlayerId,
    super.turnTimeLimit = 35,
  }) : _notifier = notifier;

  @override
  dynamic get notifier => _notifier;

  @override
  String get actionMessageType => 'niuniu_action';

  @override
  String get stateMessageType => 'niuniu_state';

  @override
  dynamic get currentState => _notifier.currentState;

  @override
  Map<String, dynamic> serializeState(dynamic state,
      {bool includeAllCards = false}) {
    final s = state as NiuniuGameState;
    return s.toJson(includeAllCards: includeAllCards);
  }

  @override
  dynamic deserializeAction(Map<String, dynamic> data) {
    return NiuniuNetworkAction.fromJson(data);
  }

  @override
  bool shouldProcessAction(dynamic action, dynamic state) {
    final networkAction = action as NiuniuNetworkAction;
    final s = state as NiuniuGameState;
    final player = s.players.where((p) => p.id == networkAction.playerId).firstOrNull;
    if (player == null) return false;
    return player.status == NiuniuPlayerStatus.waiting;
  }

  @override
  void executeAction(dynamic action) {
    final networkAction = action as NiuniuNetworkAction;
    if (networkAction.action == NiuniuActionType.bet) {
      _notifier.networkBet(networkAction.playerId, networkAction.amount);
    }
  }

  @override
  void applyNetworkState(Map<String, dynamic> data) {
    final newState = NiuniuGameState.fromJson(data, localPlayerId: localPlayerId);
    _notifier.applyNetworkState(newState);
  }

  @override
  bool includeAllCardsInState(dynamic state) {
    final s = state as NiuniuGameState;
    return s.phase == NiuniuPhase.showdown || s.phase == NiuniuPhase.settlement;
  }

  @override
  bool shouldTrackTimeout(dynamic state) {
    final s = state as NiuniuGameState;
    return s.phase == NiuniuPhase.betting;
  }

  @override
  String? currentNonAiPlayerId(dynamic state) {
    final s = state as NiuniuGameState;
    final nextWaiting = s.punters
        .where((p) => p.status == NiuniuPlayerStatus.waiting)
        .firstOrNull;
    return nextWaiting?.id;
  }

  @override
  void onTimeout(String playerId) {
    final player = _notifier.currentState.players
        .where((p) => p.id == playerId)
        .firstOrNull;
    if (player != null && player.status == NiuniuPlayerStatus.waiting) {
      _notifier.forceMinBet(playerId);
    }
  }

  /// Client 发送行动
  void sendAction(NiuniuNetworkAction action) {
    broadcastFn({'type': actionMessageType, 'data': action.toJson()});
  }

  /// Host 主动广播当前状态
  @override
  void broadcastCurrentState() {
    doBroadcastState();
  }
}
