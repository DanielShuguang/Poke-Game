import 'dart:async';

import 'package:poke_game/domain/guandan/entities/guandan_game_state.dart';
import 'package:poke_game/domain/guandan/entities/guandan_network_action.dart';
import 'package:poke_game/domain/guandan/guandan_game_notifier.dart';

abstract class _MsgType {
  static const action = 'guandan_action';
  static const stateSync = 'guandan_state';
}

/// 掼蛋局域网适配器
///
/// Host：接收 Client 行动 → 验证 → 调用 notifier → 广播状态
/// Client：发送行动 → 等待状态广播
class GuandanNetworkAdapter {
  final Stream<Map<String, dynamic>> incomingStream;
  final void Function(Map<String, dynamic>) broadcastFn;
  final GuandanGameNotifier _notifier;
  final bool isHost;
  final String localPlayerId;
  final int turnTimeLimit;

  StreamSubscription? _sub;
  Timer? _timeoutTimer;
  String? _watchedPlayerId;

  GuandanNetworkAdapter({
    required this.incomingStream,
    required this.broadcastFn,
    required GuandanGameNotifier notifier,
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
  void sendAction(GuandanNetworkAction action) {
    broadcastFn({'type': _MsgType.action, 'data': action.toJson()});
  }

  // ──────────────────────────────────────────────────────────────
  // 消息处理
  // ──────────────────────────────────────────────────────────────

  void _handleMessage(Map<String, dynamic> msg) {
    try {
      final type = msg['type'] as String?;
      final data = msg['data'] as Map<String, dynamic>?;
      if (data == null) return;

      if (type == _MsgType.action && isHost) {
        _handleActionFromClient(data);
      } else if (type == _MsgType.stateSync && !isHost) {
        _handleStateSyncFromHost(data);
      }
    } catch (_) {}
  }

  // ── Host 端 ─────────────────────────────────────────────────

  void _handleActionFromClient(Map<String, dynamic> data) {
    final action = GuandanNetworkAction.fromJson(data);
    final state = _notifier.currentState;

    switch (action) {
      case PlayCardsNetworkAction(:final cards):
        // 验证：只处理当前轮次玩家的行动
        if (state.phase != GuandanPhase.playing) return;
        final currentId = state.currentPlayer.id;
        // 消息本身没有 playerId，Host 根据当前轮次确定
        _notifier.playCards(currentId, cards);

      case PassNetworkAction():
        if (state.phase != GuandanPhase.playing) return;
        _notifier.pass(state.currentPlayer.id);

      case TributeNetworkAction(:final card, :final playerId):
        // 贡牌阶段：直接使用消息中的 playerId
        final sender = playerId ??
            _findSenderInTribute(state, data);
        if (sender != null) _notifier.tribute(sender, card);

      case ReturnTributeNetworkAction(:final card, :final playerId):
        final sender = playerId ??
            _findSenderInReturnTribute(state, data);
        if (sender != null) _notifier.returnTribute(sender, card);
    }

    _broadcastState();
    _resetTimeout();
  }

  // ── Client 端 ────────────────────────────────────────────────

  void _handleStateSyncFromHost(Map<String, dynamic> data) {
    final newState = GuandanGameState.fromJson(
      data,
      localPlayerId: localPlayerId,
    );
    _notifier.applyNetworkState(newState);
  }

  // ──────────────────────────────────────────────────────────────
  // 广播 & 超时
  // ──────────────────────────────────────────────────────────────

  void _broadcastState() {
    final phase = _notifier.currentState.phase;
    final includeAll = phase == GuandanPhase.settling ||
        phase == GuandanPhase.finished;
    final json = _notifier.currentState.toJson(
      includeAllCards: includeAll,
      localPlayerId: localPlayerId,
    );
    broadcastFn({'type': _MsgType.stateSync, 'data': json});
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();

    final state = _notifier.currentState;
    if (state.phase != GuandanPhase.playing &&
        state.phase != GuandanPhase.tribute &&
        state.phase != GuandanPhase.returnTribute) {
      return;
    }

    // 找到当前需要行动的非 AI 玩家
    final watchId = _currentNonAiPlayerId(state);
    if (watchId == null) return;

    _watchedPlayerId = watchId;

    _timeoutTimer = Timer(Duration(seconds: turnTimeLimit), () {
      final watched = _watchedPlayerId;
      if (watched == null) return;

      _executeTimeout(watched);
    });
  }

  void _executeTimeout(String playerId) {
    final state = _notifier.currentState;

    if (state.phase == GuandanPhase.playing) {
      if (state.lastPlayedHand == null) {
        // 首出超时 → 出最小牌
        _notifier.forcePlayCards(playerId);
      } else {
        // 跟牌超时 → pass
        _notifier.forcePass(playerId);
      }
    } else if (state.phase == GuandanPhase.tribute) {
      final ts = state.tributeState;
      if (ts != null && ts.pendingTributes.containsKey(playerId)) {
        // 选手牌最大单张进贡（AI 贡牌逻辑）
        final player = state.getPlayerById(playerId);
        if (player != null) {
          final nonJokers = player.cards
              .where((c) => !c.isJoker)
              .toList()
            ..sort((a, b) => b.rank!.compareTo(a.rank!));
          if (nonJokers.isNotEmpty) {
            _notifier.tribute(playerId, nonJokers.first);
          }
        }
      }
    } else if (state.phase == GuandanPhase.returnTribute) {
      final ts = state.tributeState;
      if (ts != null && ts.pendingReturnTributes.containsKey(playerId)) {
        final player = state.getPlayerById(playerId);
        if (player != null && player.cards.isNotEmpty) {
          _notifier.returnTribute(playerId, player.cards.first);
        }
      }
    }

    _broadcastState();
    _resetTimeout();
  }

  // ──────────────────────────────────────────────────────────────
  // 辅助
  // ──────────────────────────────────────────────────────────────

  String? _currentNonAiPlayerId(GuandanGameState state) {
    if (state.phase == GuandanPhase.playing) {
      final p = state.currentPlayer;
      return p.isAi ? null : p.id;
    }
    final ts = state.tributeState;
    if (ts == null) return null;

    final pending = state.phase == GuandanPhase.tribute
        ? ts.pendingTributes.keys
        : ts.pendingReturnTributes.keys;

    for (final id in pending) {
      final p = state.getPlayerById(id);
      if (p != null && !p.isAi) return id;
    }
    return null;
  }

  /// 贡牌阶段：从消息中找到对应的进贡者（Client 的 playerId 通过额外字段传递）
  String? _findSenderInTribute(
      GuandanGameState state, Map<String, dynamic> data) {
    final playerId = data['playerId'] as String?;
    if (playerId != null) return playerId;

    // 如果消息没有 playerId，取第一个 pending 玩家
    final ts = state.tributeState;
    if (ts == null || ts.pendingTributes.isEmpty) return null;
    return ts.pendingTributes.keys.first;
  }

  String? _findSenderInReturnTribute(
      GuandanGameState state, Map<String, dynamic> data) {
    final playerId = data['playerId'] as String?;
    if (playerId != null) return playerId;

    final ts = state.tributeState;
    if (ts == null || ts.pendingReturnTributes.isEmpty) return null;
    return ts.pendingReturnTributes.keys.first;
  }
}
