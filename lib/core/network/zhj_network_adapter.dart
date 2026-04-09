import 'dart:async';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_network_action.dart';
import 'package:poke_game/presentation/pages/zhajinhua/providers/zhj_game_notifier.dart';

/// 炸金花网络适配器
///
/// Host：接收客户端行动、验证后更新状态、广播新状态。
/// Client：发送行动给 Host，接收状态广播更新 UI。
///
/// 依赖注入 [incomingStream] 和 [broadcastFn] 以解耦 WebSocket 具体实现。
class ZhjNetworkAdapter {
  /// 来自网络层的消息流（已解析为 Map）
  final Stream<Map<String, dynamic>> incomingStream;

  /// 向所有连接广播消息的函数
  final void Function(Map<String, dynamic> message) broadcastFn;

  final ZhjGameNotifier _notifier;
  final bool isHost;
  final String localPlayerId;

  StreamSubscription? _messageSub;

  /// Host 超时计时器（35 秒未操作则代为弃牌）
  Timer? _timeoutTimer;

  /// 当前监听的玩家 ID（用于超时检测）
  String? _watchedPlayerId;

  final int turnTimeLimit;

  ZhjNetworkAdapter({
    required this.incomingStream,
    required this.broadcastFn,
    required ZhjGameNotifier notifier,
    required this.isHost,
    required this.localPlayerId,
    this.turnTimeLimit = 35,
  }) : _notifier = notifier;

  /// 开始监听网络消息
  void start() {
    _messageSub = incomingStream.listen(_handleMessage);
    if (isHost) {
      _resetTimeoutForCurrentPlayer();
    }
  }

  /// 停止监听
  void stop() {
    _messageSub?.cancel();
    _messageSub = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// 发送玩家行动（客户端调用）
  void sendAction(ZhjNetworkAction action) {
    broadcastFn({
      'type': ZhjMessageType.action,
      'data': action.toJson(),
    });
  }

  void _handleMessage(Map<String, dynamic> message) {
    try {
      final type = message['type'] as String;
      switch (type) {
        case ZhjMessageType.action:
          if (isHost) {
            _handleActionFromClient(message['data'] as Map<String, dynamic>);
          }
        case ZhjMessageType.stateSync:
          if (!isHost) {
            _handleStateSyncFromHost(message['data'] as Map<String, dynamic>);
          }
      }
    } catch (_) {
      // 忽略格式错误的消息
    }
  }

  /// Host：处理客户端发来的行动（任务 4.5）
  void _handleActionFromClient(Map<String, dynamic> data) {
    final action = ZhjNetworkAction.fromJson(data);

    // 验证是否轮到该玩家
    final state = _notifier.currentState;
    if (state.phase != ZhjGamePhase.betting) return;
    final currentPlayer = state.currentPlayer;
    if (currentPlayer.id != action.playerId) return;

    // 超时检测：行动时间戳超过 35 秒视为超时
    final elapsed = DateTime.now().difference(action.timestamp);
    if (elapsed.inSeconds > 35) {
      _notifier.forcePlayerFold(action.playerId);
      _broadcastState();
      return;
    }

    // 执行行动
    switch (action.actionType) {
      case ZhjActionType.peek:
        _notifier.networkPeek(action.playerId);
      case ZhjActionType.call:
        _notifier.networkCall(action.playerId);
      case ZhjActionType.raise:
        _notifier.networkRaise(action.playerId);
      case ZhjActionType.fold:
        _notifier.networkFold(action.playerId);
      case ZhjActionType.showdown:
        if (action.targetPlayerIndex != null) {
          _notifier.networkShowdown(action.playerId, action.targetPlayerIndex!);
        }
    }

    // 广播新状态
    _broadcastState();

    // 重置新一轮超时
    _resetTimeoutForCurrentPlayer();
  }

  /// Client：处理 Host 广播的状态（任务 4.6）
  void _handleStateSyncFromHost(Map<String, dynamic> data) {
    final newState = ZhjGameState.fromJson(data, localPlayerId: localPlayerId);
    _notifier.applyNetworkState(newState);
  }

  void _broadcastState() {
    broadcastFn({
      'type': ZhjMessageType.stateSync,
      'data': _notifier.currentState.toJson(includeAllCards: true),
    });
  }

  /// 任务 4.7：Host 监听当前玩家变化，35 秒未操作则代为弃牌
  void _resetTimeoutForCurrentPlayer() {
    _timeoutTimer?.cancel();
    final state = _notifier.currentState;
    if (state.phase != ZhjGamePhase.betting) return;

    final currentId = state.currentPlayer.id;
    // 本地 Host 玩家不需要超时
    if (currentId == localPlayerId) return;

    _watchedPlayerId = currentId;
    _timeoutTimer = Timer(Duration(seconds: turnTimeLimit), () {
      if (_watchedPlayerId == null) return;
      final s = _notifier.currentState;
      if (s.phase != ZhjGamePhase.betting) return;
      if (s.currentPlayer.id != _watchedPlayerId) return;
      // 超时代为弃牌
      _notifier.forcePlayerFold(_watchedPlayerId!);
      _broadcastState();
      _resetTimeoutForCurrentPlayer();
    });
  }

  void dispose() {
    stop();
  }
}
