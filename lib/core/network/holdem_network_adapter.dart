import 'dart:async';
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_network_action.dart';
import 'package:poke_game/domain/texas_holdem/usecases/betting_usecases.dart';
import 'package:poke_game/presentation/pages/texas_holdem/holdem_notifier.dart';

/// 德州扑克网络适配器
///
/// Host：接收客户端行动、验证后更新状态、广播新状态。
/// Client：发送行动给 Host，接收状态广播更新 UI。
///
/// 依赖注入 [incomingStream] 和 [broadcastFn] 以解耦 WebSocket 具体实现。
class HoldemNetworkAdapter {
  /// 来自网络层的消息流（已解析为 Map）
  final Stream<Map<String, dynamic>> incomingStream;

  /// 向所有连接广播消息的函数
  final void Function(Map<String, dynamic> message) broadcastFn;

  final HoldemGameNotifier _notifier;
  final bool isHost;
  final String localPlayerId;

  StreamSubscription? _messageSub;

  final int turnTimeLimit;

  HoldemNetworkAdapter({
    required this.incomingStream,
    required this.broadcastFn,
    required HoldemGameNotifier notifier,
    required this.isHost,
    required this.localPlayerId,
    this.turnTimeLimit = 35,
  }) : _notifier = notifier;

  /// 开始监听网络消息
  void start() {
    _messageSub = incomingStream.listen(_handleMessage);
  }

  /// 停止监听
  void stop() {
    _messageSub?.cancel();
    _messageSub = null;
  }

  /// 发送玩家行动（客户端调用）
  void sendAction(BettingAction action) {
    final networkAction =
        HoldemNetworkAction.fromBettingAction(localPlayerId, action);
    broadcastFn({
      'type': HoldemMessageType.action,
      'data': networkAction.toJson(),
    });
  }

  void _handleMessage(Map<String, dynamic> message) {
    try {
      final type = message['type'] as String;
      switch (type) {
        case HoldemMessageType.action:
          if (isHost) {
            _handleActionFromClient(message['data'] as Map<String, dynamic>);
          }
        case HoldemMessageType.stateSync:
          if (!isHost) {
            _handleStateSyncFromHost(message['data'] as Map<String, dynamic>);
          }
      }
    } catch (_) {
      // 忽略格式错误的消息
    }
  }

  /// Host：处理客户端发来的行动
  void _handleActionFromClient(Map<String, dynamic> data) {
    final networkAction = HoldemNetworkAction.fromJson(data);

    // 验证是否轮到该玩家
    final current = _notifier.currentState.currentPlayer;
    if (current == null || current.id != networkAction.playerId) return;

    // 超时检测：行动时间戳超过35秒视为超时
    final elapsed = DateTime.now().difference(networkAction.timestamp);
    if (elapsed.inSeconds > 35) {
      _notifier.fold();
      _broadcastState(_notifier.currentState);
      return;
    }

    // 执行行动
    final action = networkAction.toBettingAction();
    switch (action) {
      case FoldAction():
        _notifier.fold();
      case CheckAction():
        _notifier.check();
      case CallAction():
        _notifier.call();
      case RaiseAction(:final totalBet):
        _notifier.raise(totalBet);
      case AllInAction():
        _notifier.allIn();
    }

    // 广播新状态
    _broadcastState(_notifier.currentState);
  }

  /// Client：处理 Host 广播的状态
  void _handleStateSyncFromHost(Map<String, dynamic> data) {
    final newState = HoldemGameState.fromJson(data, localPlayerId: localPlayerId);
    _notifier.applyNetworkState(newState);
  }

  void _broadcastState(HoldemGameState state) {
    broadcastFn({
      'type': HoldemMessageType.stateSync,
      'data': _serializeState(state),
    });
  }

  Map<String, dynamic> _serializeState(HoldemGameState state) {
    return {
      'phase': state.phase.name,
      'currentPlayerIndex': state.currentPlayerIndex,
      'totalPot': state.totalPot,
      'currentBet': state.currentBet,
      'players': state.players
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'chips': p.chips,
                'currentBet': p.currentBet,
                'isFolded': p.isFolded,
                'isAllIn': p.isAllIn,
              })
          .toList(),
    };
  }

  void dispose() {
    stop();
  }
}
