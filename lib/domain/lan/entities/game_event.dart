import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_event.freezed.dart';
part 'game_event.g.dart';

/// 游戏事件类型
enum GameEventType {
  /// 发牌
  deal,
  /// 叫地主
  callLandlord,
  /// 出牌
  playCards,
  /// 过牌
  pass,
  /// 游戏开始
  gameStart,
  /// 游戏结束
  gameEnd,
  /// 玩家加入
  playerJoin,
  /// 玩家退出
  playerLeave,
  /// 心跳
  heartbeat,
  /// 房间状态同步
  roomStateSync,
  /// 聊天消息
  chatMessage,
}

/// 游戏事件模型
///
/// 用于事件溯源机制，记录所有游戏操作
@freezed
class GameEvent with _$GameEvent {
  const factory GameEvent({
    /// 事件ID（唯一标识）
    required String eventId,

    /// 事件类型
    required GameEventType type,

    /// 事件载荷（具体数据）
    required Map<String, dynamic> payload,

    /// 事件时间戳
    required DateTime timestamp,

    /// 发送者ID
    String? senderId,

    /// 目标玩家ID（可选，用于定向消息）
    String? targetPlayerId,
  }) = _GameEvent;

  factory GameEvent.fromJson(Map<String, dynamic> json) =>
      _$GameEventFromJson(json);
}

/// 游戏事件扩展方法
extension GameEventX on GameEvent {
  /// 创建发牌事件
  static GameEvent dealCards({
    required String eventId,
    required Map<String, dynamic> payload,
    String? targetPlayerId,
  }) {
    return GameEvent(
      eventId: eventId,
      type: GameEventType.deal,
      payload: payload,
      timestamp: DateTime.now(),
      targetPlayerId: targetPlayerId,
    );
  }

  /// 创建出牌事件
  static GameEvent playCards({
    required String eventId,
    required String senderId,
    required Map<String, dynamic> payload,
  }) {
    return GameEvent(
      eventId: eventId,
      type: GameEventType.playCards,
      payload: payload,
      timestamp: DateTime.now(),
      senderId: senderId,
    );
  }

  /// 创建叫地主事件
  static GameEvent callLandlord({
    required String eventId,
    required String senderId,
    required Map<String, dynamic> payload,
  }) {
    return GameEvent(
      eventId: eventId,
      type: GameEventType.callLandlord,
      payload: payload,
      timestamp: DateTime.now(),
      senderId: senderId,
    );
  }

  /// 创建心跳事件
  static GameEvent heartbeat({required String eventId}) {
    return GameEvent(
      eventId: eventId,
      type: GameEventType.heartbeat,
      payload: {},
      timestamp: DateTime.now(),
    );
  }
}
