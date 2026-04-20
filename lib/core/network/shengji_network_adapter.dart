import 'package:poke_game/core/network/game_network_adapter.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/entities/shengji_network_action.dart';
import 'package:poke_game/domain/shengji/validators/call_validator.dart';
import 'package:poke_game/presentation/pages/shengji/providers/shengji_notifier.dart';

/// 升级网络适配器
///
/// Host：接收 Client 行动 → 验证 → 执行 → 广播新状态。
/// Client：发送行动给 Host，接收状态广播更新本地 UI。
class ShengjiNetworkAdapter extends GameNetworkAdapter {
  final ShengjiNotifier _notifier;

  ShengjiNetworkAdapter({
    required super.incomingStream,
    required super.broadcastFn,
    required ShengjiNotifier notifier,
    required super.isHost,
    required super.localPlayerId,
    super.turnTimeLimit = 35,
  }) : _notifier = notifier;

  @override
  dynamic get notifier => _notifier;

  @override
  String get actionMessageType => 'shengji_action';

  @override
  String get stateMessageType => 'shengji_state';

  @override
  dynamic get currentState => _notifier.currentState;

  @override
  Map<String, dynamic> serializeState(dynamic state, {bool includeAllCards = false}) {
    final s = state as ShengjiGameState;
    final shouldIncludeAll = s.phase == ShengjiPhase.finished;
    return s.toJson(includeAllCards: shouldIncludeAll, localPlayerId: localPlayerId);
  }

  @override
  dynamic deserializeAction(Map<String, dynamic> data) {
    return ShengjiNetworkAction.fromJson(data);
  }

  @override
  bool shouldProcessAction(dynamic action, dynamic state) {
    final networkAction = action as ShengjiNetworkAction;
    final s = state as ShengjiGameState;
    final currentPlayer = s.currentPlayer;
    if (currentPlayer == null) return false;
    return currentPlayer.id == networkAction.playerId;
  }

  @override
  void executeAction(dynamic action) {
    final networkAction = action as ShengjiNetworkAction;
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
  }

  @override
  void applyNetworkState(Map<String, dynamic> data) {
    final newState = ShengjiGameState.fromJson(data, localPlayerId: localPlayerId);
    _notifier.applyNetworkState(newState);
  }

  @override
  bool includeAllCardsInState(dynamic state) {
    final s = state as ShengjiGameState;
    return s.phase == ShengjiPhase.finished;
  }

  @override
  bool shouldTrackTimeout(dynamic state) {
    final s = state as ShengjiGameState;
    return s.phase == ShengjiPhase.calling || s.phase == ShengjiPhase.playing;
  }

  @override
  String? currentNonAiPlayerId(dynamic state) {
    final s = state as ShengjiGameState;
    final currentPlayer = s.currentPlayer;
    if (currentPlayer == null || currentPlayer.isAi) return null;
    return currentPlayer.id;
  }

  @override
  void onTimeout(String playerId) {
    final s = currentState as ShengjiGameState;
    if (s.phase == ShengjiPhase.calling) {
      _notifier.passCall(playerId);
    } else {
      _notifier.aiAutoAction(playerId);
    }
  }

  /// Client 发送行动
  void sendAction(ShengjiNetworkAction action) {
    broadcastFn({'type': actionMessageType, 'data': action.toJson()});
  }

  /// 强制叫牌（超时托管用）
  void forceCall(String playerId) {
    if (!isHost) return;
    _notifier.passCall(playerId);
    doBroadcastState();
    // Note: does NOT call _resetTimeout since this is a manual override
  }

  /// 强制出牌（超时托管用）
  void forcePlay(String playerId) {
    if (!isHost) return;
    _notifier.aiAutoAction(playerId);
    doBroadcastState();
    // Note: does NOT call _resetTimeout since this is a manual override
  }

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
}
