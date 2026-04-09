import 'dart:async';

import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_network_action.dart';
import 'package:poke_game/presentation/pages/blackjack/providers/blackjack_game_notifier.dart';

abstract class _BjMessageType {
  static const action = 'blackjack_action';
  static const stateSync = 'blackjack_state';
}

/// 21点网络适配器
///
/// Host：接收 Client 行动 → 验证 → 执行 → 广播新状态。
/// Client：发送行动给 Host，接收状态广播更新本地 UI。
class BlackjackNetworkAdapter {
  final Stream<Map<String, dynamic>> incomingStream;
  final void Function(Map<String, dynamic>) broadcastFn;
  final BlackjackGameNotifier _notifier;
  final bool isHost;
  final String localPlayerId;

  StreamSubscription? _sub;
  Timer? _timeoutTimer;
  String? _watchedPlayerId;

  final int turnTimeLimit;

  BlackjackNetworkAdapter({
    required this.incomingStream,
    required this.broadcastFn,
    required BlackjackGameNotifier notifier,
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

  /// Client 发送行动
  void sendAction(BlackjackNetworkAction action) {
    broadcastFn({'type': _BjMessageType.action, 'data': action.toJson()});
  }

  void _handleMessage(Map<String, dynamic> msg) {
    try {
      final type = msg['type'] as String?;
      final data = msg['data'] as Map<String, dynamic>?;
      if (data == null) return;
      if (type == _BjMessageType.action && isHost) {
        _handleActionFromClient(data);
      } else if (type == _BjMessageType.stateSync && !isHost) {
        _handleStateSyncFromHost(data);
      }
    } catch (_) {}
  }

  // ── Host 端 ───────────────────────────────────────────────────────────────

  void _handleActionFromClient(Map<String, dynamic> data) {
    final networkAction = BlackjackNetworkAction.fromJson(data);

    // 验证是否轮到该玩家
    final currentPlayer = _notifier.currentState.currentPlayer;
    if (currentPlayer == null || currentPlayer.id != networkAction.playerId) {
      return;
    }

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

    _broadcastState();
    _resetTimeout();
  }

  void _handleStateSyncFromHost(Map<String, dynamic> data) {
    final newState = BlackjackGameState.fromJson(
      data,
      localPlayerId: localPlayerId,
    );
    _notifier.applyNetworkState(newState);
  }

  void _broadcastState({bool includeAllCards = false}) {
    final json = _notifier.currentState.toJson(includeAllCards: includeAllCards);
    broadcastFn({'type': _BjMessageType.stateSync, 'data': json});
  }

  /// 重置超时计时器（35s 内未操作则代为 Stand）
  void _resetTimeout() {
    _timeoutTimer?.cancel();
    final current = _notifier.currentState.currentPlayer;
    if (current == null) return;
    _watchedPlayerId = current.id;

    _timeoutTimer = Timer(Duration(seconds: turnTimeLimit), () {
      final watched = _watchedPlayerId;
      if (watched == null) return;
      final activePlayer = _notifier.currentState.currentPlayer;
      if (activePlayer?.id == watched) {
        _notifier.forcePlayerStand(watched);
        _broadcastState();
        _resetTimeout();
      }
    });
  }
}
