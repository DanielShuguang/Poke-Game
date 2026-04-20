import 'dart:async';

/// 所有游戏网络适配器的抽象基类。
///
/// 定义通用流程：消息路由、超时计时器、广播状态。
/// 子类只需实现游戏特定的：状态序列化、行动执行、超时回调。
abstract class GameNetworkAdapter {
  /// 来自网络层的消息流（已解析为 Map）
  final Stream<Map<String, dynamic>> incomingStream;

  /// 向所有连接广播消息的函数
  final void Function(Map<String, dynamic>) broadcastFn;

  final bool isHost;
  final String localPlayerId;
  final int turnTimeLimit;

  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _timeoutTimer;
  String? _watchedPlayerId;

  /// 子类引用（由子类构造器赋值）
  dynamic get notifier;

  GameNetworkAdapter({
    required this.incomingStream,
    required this.broadcastFn,
    required this.isHost,
    required this.localPlayerId,
    this.turnTimeLimit = 35,
  });

  // ──────────────────────────────────────────────────────────────
  // 公共生命周期
  // ──────────────────────────────────────────────────────────────

  /// 开始监听网络消息
  void start() {
    _sub = incomingStream.listen(_handleMessage);
    if (isHost) _resetTimeout();
  }

  /// 停止监听
  void stop() {
    _sub?.cancel();
    _sub = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// 广播当前状态（供子类在特定时机调用）
  void broadcastCurrentState() {
    doBroadcastState();
  }

  // ──────────────────────────────────────────────────────────────
  // 消息处理模板方法
  // ──────────────────────────────────────────────────────────────

  void _handleMessage(Map<String, dynamic> msg) {
    try {
      final type = msg['type'] as String?;
      final data = msg['data'] as Map<String, dynamic>?;
      if (data == null) return;

      if (type == actionMessageType && isHost) {
        _handleActionFromClient(data);
      } else if (type == stateMessageType && !isHost) {
        _handleStateSyncFromHost(data);
      }
    } catch (_) {
      // 忽略格式错误的消息
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 抽象方法（子类实现）
  // ──────────────────────────────────────────────────────────────

  /// 本游戏中 action 消息的类型标识符（子类返回 const字符串）
  String get actionMessageType;

  /// 本游戏中 stateSync 消息的类型标识符（子类返回 const字符串）
  String get stateMessageType;

  /// 获取当前游戏状态（用于超时检测）
  dynamic get currentState;

  /// 将状态序列化为 Map（用于广播）
  Map<String, dynamic> serializeState(dynamic state, {bool includeAllCards = false});

  /// Host：处理客户端发来的行动
  void _handleActionFromClient(Map<String, dynamic> data) {
    final action = deserializeAction(data);
    final state = currentState;
    if (!shouldProcessAction(action, state)) return;
    executeAction(action);
    doBroadcastState();
    _resetTimeout();
  }

  /// Client：处理 Host 广播的状态
  void _handleStateSyncFromHost(Map<String, dynamic> data) {
    applyNetworkState(data);
  }

  /// 反序列化网络行动消息
  dynamic deserializeAction(Map<String, dynamic> data);

  /// 判断是否应处理该行动（可访问 currentState）
  bool shouldProcessAction(dynamic action, dynamic state);

  /// 执行行动（调用 notifier）
  void executeAction(dynamic action);

  /// 应用从 Host 收到的状态
  void applyNetworkState(Map<String, dynamic> data);

  /// 广播状态（模板方法）
  void doBroadcastState() {
    final state = currentState;
    final json = serializeState(state, includeAllCards: shouldIncludeAllCards(state));
    broadcastFn({'type': stateMessageType, 'data': json});
  }

  bool shouldIncludeAllCards(dynamic state) {
    if (state == null) return false;
    return includeAllCardsInState(state);
  }

  /// 子类判断是否在 showdown/settlement 阶段包含全部手牌
  bool includeAllCardsInState(dynamic state);

  // ──────────────────────────────────────────────────────────────
  // 超时计时器
  // ──────────────────────────────────────────────────────────────

  /// 重置超时计时器
  void _resetTimeout() {
    _timeoutTimer?.cancel();

    if (!shouldTrackTimeout(currentState)) return;

    final watchId = currentNonAiPlayerId(currentState);
    if (watchId == null) return;

    _watchedPlayerId = watchId;

    _timeoutTimer = Timer(Duration(seconds: turnTimeLimit), () {
      final watched = _watchedPlayerId;
      if (watched == null) return;
      if (!shouldTrackTimeout(currentState)) return;
      if (currentNonAiPlayerId(currentState) != watched) return;

      onTimeout(watched);
      doBroadcastState();
      _resetTimeout();
    });
  }

  /// 判断当前阶段是否应跟踪超时
  bool shouldTrackTimeout(dynamic state);

  /// 找到当前需要行动的非 AI 玩家 ID
  String? currentNonAiPlayerId(dynamic state);

  /// 超时触发时的回调（子类实现具体的超时托管逻辑）
  void onTimeout(String playerId);
}
