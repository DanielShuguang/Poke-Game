import 'dart:async';

import 'package:poke_game/domain/niuniu/entities/niuniu_game_state.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_network_action.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_player.dart';
import 'package:poke_game/presentation/pages/niuniu/providers/niuniu_game_notifier.dart';

abstract class _NiuniuMessageType {
  static const action = 'niuniu_action';
  static const stateSync = 'niuniu_state';
}

/// 牛牛网络适配器
///
/// Host：接收 Client 下注行动 → 验证 → 执行 → 广播新状态。
/// Client：发送行动给 Host，接收状态广播更新本地 UI。
class NiuniuNetworkAdapter {
  final Stream<Map<String, dynamic>> incomingStream;
  final void Function(Map<String, dynamic>) broadcastFn;
  final NiuniuGameNotifier _notifier;
  final bool isHost;
  final String localPlayerId;

  StreamSubscription? _sub;
  Timer? _timeoutTimer;
  String? _watchedPlayerId;

  NiuniuNetworkAdapter({
    required this.incomingStream,
    required this.broadcastFn,
    required NiuniuGameNotifier notifier,
    required this.isHost,
    required this.localPlayerId,
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
  void sendAction(NiuniuNetworkAction action) {
    broadcastFn({'type': _NiuniuMessageType.action, 'data': action.toJson()});
  }

  void _handleMessage(Map<String, dynamic> msg) {
    try {
      final type = msg['type'] as String?;
      final data = msg['data'] as Map<String, dynamic>?;
      if (data == null) return;
      if (type == _NiuniuMessageType.action && isHost) {
        _handleActionFromClient(data);
      } else if (type == _NiuniuMessageType.stateSync && !isHost) {
        _handleStateSyncFromHost(data);
      }
    } catch (_) {}
  }

  // ── Host 端 ───────────────────────────────────────────────────────────────

  void _handleActionFromClient(Map<String, dynamic> data) {
    final networkAction = NiuniuNetworkAction.fromJson(data);

    // 验证：只处理等待下注的玩家行动
    final player = _notifier.currentState.players
        .where((p) => p.id == networkAction.playerId)
        .firstOrNull;
    if (player == null ||
        player.status != NiuniuPlayerStatus.waiting) {
      return;
    }

    switch (networkAction.action) {
      case NiuniuActionType.bet:
        _notifier.networkBet(networkAction.playerId, networkAction.amount);
    }

    _broadcastState();
    _resetTimeout();
  }

  void _handleStateSyncFromHost(Map<String, dynamic> data) {
    final newState = NiuniuGameState.fromJson(
      data,
      localPlayerId: localPlayerId,
    );
    _notifier.applyNetworkState(newState);
  }

  /// 广播状态：showdown/settlement 阶段包含全部手牌
  void _broadcastState() {
    final phase = _notifier.currentState.phase;
    final includeAll =
        phase == NiuniuPhase.showdown || phase == NiuniuPhase.settlement;
    final json =
        _notifier.currentState.toJson(includeAllCards: includeAll);
    broadcastFn({'type': _NiuniuMessageType.stateSync, 'data': json});
  }

  /// 重置 35s 超时计时器（等待闲家下注期间）
  void _resetTimeout() {
    _timeoutTimer?.cancel();
    if (_notifier.currentState.phase != NiuniuPhase.betting) return;
    final nextWaiting = _notifier.currentState.punters
        .where((p) => p.status == NiuniuPlayerStatus.waiting)
        .firstOrNull;
    if (nextWaiting == null) return;
    _watchedPlayerId = nextWaiting.id;

    _timeoutTimer = Timer(const Duration(seconds: 35), () {
      final watched = _watchedPlayerId;
      if (watched == null) return;
      final player = _notifier.currentState.players
          .where((p) => p.id == watched)
          .firstOrNull;
      if (player != null && player.status == NiuniuPlayerStatus.waiting) {
        _notifier.forceMinBet(watched);
        _broadcastState();
        _resetTimeout();
      }
    });
  }
}
