import 'package:poke_game/core/network/game_network_adapter.dart';
import 'package:poke_game/domain/guandan/entities/guandan_game_state.dart';
import 'package:poke_game/domain/guandan/entities/guandan_network_action.dart';
import 'package:poke_game/presentation/pages/guandan/providers/guandan_game_notifier.dart';

/// 掼蛋局域网适配器
///
/// Host：接收 Client 行动 → 验证 → 调用 notifier → 广播状态
/// Client：发送行动 → 等待状态广播
class GuandanNetworkAdapter extends GameNetworkAdapter {
  final GuandanGameNotifier _notifier;

  GuandanNetworkAdapter({
    required super.incomingStream,
    required super.broadcastFn,
    required GuandanGameNotifier notifier,
    required super.isHost,
    required super.localPlayerId,
    super.turnTimeLimit = 35,
  }) : _notifier = notifier;

  @override
  dynamic get notifier => _notifier;

  @override
  String get actionMessageType => 'guandan_action';

  @override
  String get stateMessageType => 'guandan_state';

  @override
  dynamic get currentState => _notifier.currentState;

  @override
  Map<String, dynamic> serializeState(dynamic state, {bool includeAllCards = false}) {
    final s = state as GuandanGameState;
    final shouldIncludeAll = s.phase == GuandanPhase.settling ||
        s.phase == GuandanPhase.finished;
    return s.toJson(includeAllCards: shouldIncludeAll, localPlayerId: localPlayerId);
  }

  @override
  dynamic deserializeAction(Map<String, dynamic> data) {
    return GuandanNetworkAction.fromJson(data);
  }

  @override
  bool shouldProcessAction(dynamic action, dynamic state) {
    final s = state as GuandanGameState;
    if (action is PlayCardsNetworkAction) {
      return s.phase == GuandanPhase.playing;
    } else if (action is PassNetworkAction) {
      return s.phase == GuandanPhase.playing;
    } else if (action is TributeNetworkAction) {
      return s.phase == GuandanPhase.tribute;
    } else if (action is ReturnTributeNetworkAction) {
      return s.phase == GuandanPhase.returnTribute;
    }
    return false;
  }

  @override
  void executeAction(dynamic action) {
    final s = currentState as GuandanGameState;
    switch (action) {
      case PlayCardsNetworkAction(:final cards):
        final currentId = s.currentPlayer.id;
        _notifier.playCards(currentId, cards);
      case PassNetworkAction():
        _notifier.pass(s.currentPlayer.id);
      case TributeNetworkAction(:final card, :final playerId):
        final sender = playerId ?? _firstPendingTributePlayer(s);
        if (sender != null) _notifier.tribute(sender, card);
      case ReturnTributeNetworkAction(:final card, :final playerId):
        final sender = playerId ?? _firstPendingReturnTributePlayer(s);
        if (sender != null) _notifier.returnTribute(sender, card);
    }
  }

  @override
  void applyNetworkState(Map<String, dynamic> data) {
    final newState = GuandanGameState.fromJson(data, localPlayerId: localPlayerId);
    _notifier.applyNetworkState(newState);
  }

  @override
  bool includeAllCardsInState(dynamic state) {
    final s = state as GuandanGameState;
    return s.phase == GuandanPhase.settling || s.phase == GuandanPhase.finished;
  }

  @override
  bool shouldTrackTimeout(dynamic state) {
    final s = state as GuandanGameState;
    return s.phase == GuandanPhase.playing ||
        s.phase == GuandanPhase.tribute ||
        s.phase == GuandanPhase.returnTribute;
  }

  @override
  String? currentNonAiPlayerId(dynamic state) {
    final s = state as GuandanGameState;
    if (s.phase == GuandanPhase.playing) {
      final p = s.currentPlayer;
      return p.isAi ? null : p.id;
    }
    final ts = s.tributeState;
    if (ts == null) return null;
    final pending = s.phase == GuandanPhase.tribute
        ? ts.pendingTributes.keys
        : ts.pendingReturnTributes.keys;
    for (final id in pending) {
      final p = s.getPlayerById(id);
      if (p != null && !p.isAi) return id;
    }
    return null;
  }

  @override
  void onTimeout(String playerId) {
    final s = currentState as GuandanGameState;
    if (s.phase == GuandanPhase.playing) {
      if (s.lastPlayedHand == null) {
        _notifier.forcePlayCards(playerId);
      } else {
        _notifier.forcePass(playerId);
      }
    } else if (s.phase == GuandanPhase.tribute) {
      final ts = s.tributeState;
      if (ts != null && ts.pendingTributes.containsKey(playerId)) {
        final player = s.getPlayerById(playerId);
        if (player != null) {
          final nonJokers = player.cards.where((c) => !c.isJoker).toList()
            ..sort((a, b) => b.rank!.compareTo(a.rank!));
          if (nonJokers.isNotEmpty) {
            _notifier.tribute(playerId, nonJokers.first);
          }
        }
      }
    } else if (s.phase == GuandanPhase.returnTribute) {
      final ts = s.tributeState;
      if (ts != null && ts.pendingReturnTributes.containsKey(playerId)) {
        final player = s.getPlayerById(playerId);
        if (player != null && player.cards.isNotEmpty) {
          _notifier.returnTribute(playerId, player.cards.first);
        }
      }
    }
  }

  /// Client 发送行动给 Host
  void sendAction(GuandanNetworkAction action) {
    broadcastFn({'type': actionMessageType, 'data': action.toJson()});
  }

  String? _firstPendingTributePlayer(GuandanGameState state) {
    final ts = state.tributeState;
    if (ts == null || ts.pendingTributes.isEmpty) return null;
    return ts.pendingTributes.keys.first;
  }

  String? _firstPendingReturnTributePlayer(GuandanGameState state) {
    final ts = state.tributeState;
    if (ts == null || ts.pendingReturnTributes.isEmpty) return null;
    return ts.pendingReturnTributes.keys.first;
  }
}
