import 'dart:async';

import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/entities/shengji_network_action.dart';
import 'package:poke_game/domain/shengji/notifiers/shengji_notifier.dart';
import 'package:poke_game/domain/shengji/validators/call_validator.dart';

abstract class _ShengjiMessageType {
  static const action = 'shengji_action';
  static const stateSync = 'shengji_state';
}

/// 升级网络适配器
///
/// Host：接收 Client 行动 → 验证 → 执行 → 广播新状态。
/// Client：发送行动给 Host，接收状态广播更新本地 UI。
class ShengjiNetworkAdapter {
  final Stream<Map<String, dynamic>> incomingStream;
  final void Function(Map<String, dynamic>) broadcastFn;
  final ShengjiNotifier _notifier;
  final bool isHost;
  final String localPlayerId;

  StreamSubscription? _sub;
  Timer? _timeoutTimer;
  String? _watchedPlayerId;

  ShengjiNetworkAdapter({
    required this.incomingStream,
    required this.broadcastFn,
    required ShengjiNotifier notifier,
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
  void sendAction(ShengjiNetworkAction action) {
    broadcastFn({'type': _ShengjiMessageType.action, 'data': action.toJson()});
  }

  void _handleMessage(Map<String, dynamic> msg) {
    try {
      final type = msg['type'] as String?;
      final data = msg['data'] as Map<String, dynamic>?;
      if (data == null) return;
      if (type == _ShengjiMessageType.action && isHost) {
        _handleActionFromClient(data);
      } else if (type == _ShengjiMessageType.stateSync && !isHost) {
        _handleStateSyncFromHost(data);
      }
    } catch (_) {}
  }

  // ── Host 端 ───────────────────────────────────────────────────────────────

  void _handleActionFromClient(Map<String, dynamic> data) {
    final networkAction = ShengjiNetworkAction.fromJson(data);

    // 验证：只处理当前玩家的行动
    final currentPlayer = _notifier.currentState.currentPlayer;
    if (currentPlayer == null || currentPlayer.id != networkAction.playerId) {
      return;
    }

    switch (networkAction.action) {
      case ShengjiActionType.callTrump:
        if (networkAction.callData != null) {
          final call = _parseCall(networkAction.callData!);
          if (call != null) {
            _notifier.callTrump(networkAction.playerId, call);
          }
        }
        break;
      case ShengjiActionType.passCall:
        _notifier.passCall(networkAction.playerId);
        break;
      case ShengjiActionType.playCards:
        if (networkAction.cards != null) {
          final cards = networkAction.cards!
              .map((c) => ShengjiCard.fromJson(c))
              .toList();
          _notifier.playCards(networkAction.playerId, cards);
        }
        break;
    }

    _broadcastState();
    _resetTimeout();
  }

  void _handleStateSyncFromHost(Map<String, dynamic> data) {
    final newState = ShengjiGameState.fromJson(
      data,
      localPlayerId: localPlayerId,
    );
    _notifier.applyNetworkState(newState);
  }

  /// 广播状态：finished 阶段包含全部手牌
  void _broadcastState() {
    final phase = _notifier.currentState.phase;
    final includeAll = phase == ShengjiPhase.finished;
    final json = _notifier.currentState.toJson(
      includeAllCards: includeAll,
      localPlayerId: localPlayerId,
    );
    broadcastFn({'type': _ShengjiMessageType.stateSync, 'data': json});
  }

  /// 解析叫牌内容
  TrumpCall? _parseCall(Map<String, dynamic> data) {
    final typeName = data['type'] as String?;
    if (typeName == null) return null;

    try {
      final type = CallType.values.firstWhere((e) => e.name == typeName);
      switch (type) {
        case CallType.pair:
          return TrumpCall.pair(
            Suit.values.firstWhere((e) => e.name == data['suit']),
            data['rank'] as int,
          );
        case CallType.tractor:
          return TrumpCall.tractor(
            Suit.values.firstWhere((e) => e.name == data['suit']),
            data['rank'] as int,
          );
        case CallType.noTrump:
          return TrumpCall.noTrump(
            JokerType.values.firstWhere((e) => e.name == data['jokerType']),
          );
      }
    } catch (_) {
      return null;
    }
  }

  /// 重置 35s 超时计时器
  void _resetTimeout() {
    _timeoutTimer?.cancel();

    final phase = _notifier.currentState.phase;
    if (phase != ShengjiPhase.calling && phase != ShengjiPhase.playing) {
      return;
    }

    final currentPlayer = _notifier.currentState.currentPlayer;
    if (currentPlayer == null || currentPlayer.isAi) return;

    _watchedPlayerId = currentPlayer.id;

    _timeoutTimer = Timer(const Duration(seconds: 35), () {
      final watched = _watchedPlayerId;
      if (watched == null) return;

      final player = _notifier.currentState.players
          .where((p) => p.id == watched)
          .firstOrNull;

      if (player == null || player.isAi) return;

      // 超时自动执行最小操作
      if (phase == ShengjiPhase.calling) {
        _notifier.passCall(watched);
      } else {
        // 出牌阶段会自动出最小牌
        _notifier.aiAutoAction(watched);
      }

      _broadcastState();
      _resetTimeout();
    });
  }

  /// 强制叫牌（超时托管用）
  void forceCall(String playerId) {
    if (!isHost) return;
    _notifier.passCall(playerId);
    _broadcastState();
    _resetTimeout();
  }

  /// 强制出牌（超时托管用）
  void forcePlay(String playerId) {
    if (!isHost) return;
    _notifier.aiAutoAction(playerId);
    _broadcastState();
    _resetTimeout();
  }
}
