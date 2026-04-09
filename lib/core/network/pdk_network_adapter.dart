import 'dart:async';

import 'package:poke_game/domain/paodekai/entities/pdk_game_state.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_network_action.dart';
import 'package:poke_game/domain/paodekai/notifiers/pdk_notifier.dart';

abstract class _PdkMessageType {
  static const action = 'pdk_action';
  static const stateSync = 'pdk_state';
}

/// 跑得快网络适配器
///
/// Host：接收 Client 出牌/pass 行动 → 执行 → 广播新状态。
/// Client：发送行动给 Host，接收状态广播更新本地 UI。
class PdkNetworkAdapter {
  final Stream<Map<String, dynamic>> incomingStream;
  final void Function(Map<String, dynamic>) broadcastFn;
  final PdkGameNotifier _notifier;
  final bool isHost;
  final String localPlayerId;

  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _timeoutTimer;
  String? _watchedPlayerId;

  final int turnTimeLimit;

  PdkNetworkAdapter({
    required this.incomingStream,
    required this.broadcastFn,
    required PdkGameNotifier notifier,
    required this.isHost,
    required this.localPlayerId,
    this.turnTimeLimit = 35,
  }) : _notifier = notifier;

  void start() {
    _sub = incomingStream.listen(_handleMessage);
    if (isHost) _resetTimeout();
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Client 发送行动给 Host
  void sendAction(PdkNetworkAction action) {
    broadcastFn({'type': _PdkMessageType.action, 'data': action.toJson()});
  }

  /// Host 主动广播当前状态
  void broadcastCurrentState() {
    _broadcastState();
  }

  void _handleMessage(Map<String, dynamic> msg) {
    try {
      final type = msg['type'] as String?;
      final data = msg['data'] as Map<String, dynamic>?;
      if (data == null) return;
      if (type == _PdkMessageType.action && isHost) {
        _handleActionFromClient(data);
      } else if (type == _PdkMessageType.stateSync && !isHost) {
        _handleStateSyncFromHost(data);
      }
    } catch (_) {}
  }

  // ── Host 端 ───────────────────────────────────────────────────────────────

  void _handleActionFromClient(Map<String, dynamic> data) {
    final networkAction = PdkNetworkAction.fromJson(data);

    // 验证：只处理当前行动玩家
    final state = _notifier.currentState;
    if (state.phase != PdkGamePhase.playing) return;
    if (state.players.isEmpty) return;
    final currentPlayerId = state.currentPlayer.id;
    if (networkAction.playerId != currentPlayerId) return;

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

    _broadcastState();
    _resetTimeout();
  }

  void _handleStateSyncFromHost(Map<String, dynamic> data) {
    final newState = PdkGameState.fromJson(data);
    _notifier.syncState(newState);
  }

  /// 广播完整状态
  void _broadcastState() {
    final json = _notifier.currentState.toJson();
    broadcastFn({'type': _PdkMessageType.stateSync, 'data': json});
  }

  /// 重置 35s 超时计时器（等待当前玩家出牌期间）
  void _resetTimeout() {
    _timeoutTimer?.cancel();
    final state = _notifier.currentState;
    if (state.phase != PdkGamePhase.playing) return;
    if (state.players.isEmpty) return;

    final currentPlayer = state.currentPlayer;
    _watchedPlayerId = currentPlayer.id;

    _timeoutTimer = Timer(Duration(seconds: turnTimeLimit), () {
      final watched = _watchedPlayerId;
      if (watched == null) return;
      final current = _notifier.currentState;
      if (current.phase != PdkGamePhase.playing) return;
      if (current.players.isEmpty) return;
      if (current.currentPlayer.id != watched) return;

      // 起手方（无上家牌）forcePlayCards，有上家牌时 forcePass
      if (current.lastPlayedHand == null) {
        _notifier.forcePlayCards(watched);
      } else {
        _notifier.forcePass(watched);
      }
      _broadcastState();
      _resetTimeout();
    });
  }
}
