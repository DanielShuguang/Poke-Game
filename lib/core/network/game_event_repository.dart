import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:poke_game/domain/lan/entities/game_event.dart';
import 'package:uuid/uuid.dart';

/// 事件溯源仓库
///
/// 用于存储和查询游戏事件
class GameEventRepository {
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  /// 最大事件缓存数
  final int maxEvents;

  /// 事件存储队列
  final Queue<GameEvent> _events = Queue<GameEvent>();

  /// 事件ID索引
  final Map<String, GameEvent> _eventIndex = {};

  /// 事件流控制器
  final StreamController<GameEvent> _eventController =
      StreamController<GameEvent>.broadcast();

  /// 事件流
  Stream<GameEvent> get eventStream => _eventController.stream;

  GameEventRepository({this.maxEvents = 100});

  /// 添加事件
  GameEvent addEvent(GameEventType type, Map<String, dynamic> payload, {String? senderId, String? targetPlayerId}) {
    final event = GameEvent(
      eventId: _uuid.v4(),
      type: type,
      payload: payload,
      timestamp: DateTime.now(),
      senderId: senderId,
      targetPlayerId: targetPlayerId,
    );

    _addEventToStorage(event);
    _eventController.add(event);

    _logger.d('事件已添加: ${event.eventId}, 类型: ${event.type}');
    return event;
  }

  /// 添加已构建的事件
  void addExistingEvent(GameEvent event) {
    _addEventToStorage(event);
    _eventController.add(event);
  }

  /// 存储事件
  void _addEventToStorage(GameEvent event) {
    _events.add(event);
    _eventIndex[event.eventId] = event;

    // 限制缓存大小
    if (_events.length > maxEvents) {
      final removed = _events.removeFirst();
      _eventIndex.remove(removed.eventId);
    }
  }

  /// 获取事件
  GameEvent? getEvent(String eventId) {
    return _eventIndex[eventId];
  }

  /// 获取所有事件
  List<GameEvent> getAllEvents() {
    return _events.toList();
  }

  /// 获取指定事件之后的事件
  List<GameEvent> getEventsAfter(String eventId) {
    final events = <GameEvent>[];
    bool found = false;

    for (final event in _events) {
      if (found) {
        events.add(event);
      } else if (event.eventId == eventId) {
        found = true;
      }
    }

    return events;
  }

  /// 获取指定类型的事件
  List<GameEvent> getEventsByType(GameEventType type) {
    return _events.where((e) => e.type == type).toList();
  }

  /// 获取指定玩家的事件
  List<GameEvent> getEventsByPlayer(String playerId) {
    return _events.where((e) => e.senderId == playerId).toList();
  }

  /// 获取最新事件
  GameEvent? getLatestEvent() {
    if (_events.isEmpty) return null;
    return _events.last;
  }

  /// 获取最新事件ID
  String? getLatestEventId() {
    return getLatestEvent()?.eventId;
  }

  /// 获取事件数量
  int get eventCount => _events.length;

  /// 清空所有事件
  void clear() {
    _events.clear();
    _eventIndex.clear();
    _logger.i('所有事件已清空');
  }

  /// 释放资源
  void dispose() {
    _eventController.close();
  }
}

/// 房间事件管理器
///
/// 管理单个房间的事件溯源
class RoomEventManager {
  final Logger _logger = Logger();

  /// 房间ID
  final String roomId;

  /// 事件仓库
  final GameEventRepository eventRepository;

  /// 玩家最后事件ID
  final Map<String, String> _playerLastEventIds = {};

  RoomEventManager({
    required this.roomId,
    int maxEvents = 100,
  }) : eventRepository = GameEventRepository(maxEvents: maxEvents);

  /// 记录发牌事件
  GameEvent recordDealCards(String playerId, List<String> cardIds) {
    return eventRepository.addEvent(
      GameEventType.deal,
      {'cardIds': cardIds},
      targetPlayerId: playerId,
    );
  }

  /// 记录叫地主事件
  GameEvent recordCallLandlord(String playerId, bool call) {
    return eventRepository.addEvent(
      GameEventType.callLandlord,
      {'call': call},
      senderId: playerId,
    );
  }

  /// 记录出牌事件
  GameEvent recordPlayCards(String playerId, List<String> cardIds) {
    return eventRepository.addEvent(
      GameEventType.playCards,
      {'cardIds': cardIds},
      senderId: playerId,
    );
  }

  /// 记录过牌事件
  GameEvent recordPass(String playerId) {
    return eventRepository.addEvent(
      GameEventType.pass,
      {},
      senderId: playerId,
    );
  }

  /// 记录游戏开始事件
  GameEvent recordGameStart() {
    return eventRepository.addEvent(
      GameEventType.gameStart,
      {'roomId': roomId},
    );
  }

  /// 记录游戏结束事件
  GameEvent recordGameEnd(Map<String, dynamic> result) {
    return eventRepository.addEvent(
      GameEventType.gameEnd,
      result,
    );
  }

  /// 记录玩家加入事件
  GameEvent recordPlayerJoin(String playerId, String playerName) {
    return eventRepository.addEvent(
      GameEventType.playerJoin,
      {'playerId': playerId, 'playerName': playerName},
    );
  }

  /// 记录玩家离开事件
  GameEvent recordPlayerLeave(String playerId, String playerName) {
    return eventRepository.addEvent(
      GameEventType.playerLeave,
      {'playerId': playerId, 'playerName': playerName},
    );
  }

  /// 更新玩家最后事件ID
  void updatePlayerLastEventId(String playerId, String eventId) {
    _playerLastEventIds[playerId] = eventId;
  }

  /// 获取玩家需要同步的事件
  List<GameEvent> getPlayerSyncEvents(String playerId) {
    final lastEventId = _playerLastEventIds[playerId];
    if (lastEventId == null) {
      return eventRepository.getAllEvents();
    }
    return eventRepository.getEventsAfter(lastEventId);
  }

  /// 释放资源
  void dispose() {
    eventRepository.dispose();
    _playerLastEventIds.clear();
  }
}
