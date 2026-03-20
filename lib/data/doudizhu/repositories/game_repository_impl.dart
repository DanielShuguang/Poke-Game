import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:poke_game/core/network/game_state_serializer.dart';
import 'package:poke_game/core/network/websocket_client.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';
import 'package:poke_game/domain/doudizhu/entities/player_interface.dart';
import 'package:poke_game/domain/doudizhu/repositories/game_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 游戏仓库实现
///
/// 支持本地存储（断线重连）和局域网对战功能
class GameRepositoryImpl implements GameRepository {
  final Logger _logger = Logger();
  final GameStateSerializer _serializer = GameStateSerializer();

  /// 本地存储 key
  static const String _gameStateKey = 'game_state_cache';

  /// SharedPreferences 实例
  final SharedPreferences _prefs;

  /// WebSocket 客户端（局域网模式使用）
  WebSocketClient? _wsClient;

  /// 远程状态流控制器
  final StreamController<GameState> _remoteStateController =
      StreamController<GameState>.broadcast();

  /// 当前玩家 ID（局域网模式）
  String? _currentPlayerId;

  /// 是否为局域网模式
  bool _isLanMode = false;

  GameRepositoryImpl({
    required SharedPreferences prefs,
    WebSocketClient? wsClient,
  })  : _prefs = prefs,
        _wsClient = wsClient;

  /// 初始化局域网模式
  void initLanMode({
    required WebSocketClient wsClient,
    required String currentPlayerId,
  }) {
    _wsClient = wsClient;
    _currentPlayerId = currentPlayerId;
    _isLanMode = true;

    // 监听服务器消息
    _wsClient!.messageStream.listen(_handleServerMessage);

    _logger.i('局域网模式已初始化, 玩家: $currentPlayerId');
  }

  /// 处理服务器消息
  void _handleServerMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'game_state_sync':
        _handleGameStateSync(message);
        break;
      case 'deal_cards':
        _handleDealCards(message);
        break;
      case 'play_cards':
        _handlePlayCards(message);
        break;
      case 'pass':
        _handlePass(message);
        break;
      case 'call_landlord':
        _handleCallLandlord(message);
        break;
      case 'turn_change':
        _handleTurnChange(message);
        break;
      case 'game_end':
        _handleGameEnd(message);
        break;
    }
  }

  /// 处理游戏状态同步
  void _handleGameStateSync(Map<String, dynamic> message) {
    try {
      // 这里需要完整的反序列化逻辑
      // 由于 GameState 较复杂，暂时只更新关键状态
      _logger.d('收到游戏状态同步');
    } catch (e) {
      _logger.e('处理游戏状态同步失败: $e');
    }
  }

  /// 处理发牌
  void _handleDealCards(Map<String, dynamic> message) {
    try {
      final data = message['data'] as Map<String, dynamic>;
      final dealData = DealData.fromJson(data);
      _logger.i('收到发牌: ${dealData.cards.length} 张');
    } catch (e) {
      _logger.e('处理发牌失败: $e');
    }
  }

  /// 处理出牌
  void _handlePlayCards(Map<String, dynamic> message) {
    try {
      final data = message['data'] as Map<String, dynamic>;
      final playData = PlayCardsData.fromJson(data);
      _logger.i('玩家 ${playData.playerId} 出牌: ${playData.cards.length} 张');
    } catch (e) {
      _logger.e('处理出牌失败: $e');
    }
  }

  /// 处理过牌
  void _handlePass(Map<String, dynamic> message) {
    final playerId = message['playerId'] as String;
    _logger.i('玩家 $playerId 过牌');
  }

  /// 处理叫地主
  void _handleCallLandlord(Map<String, dynamic> message) {
    try {
      final data = message['data'] as Map<String, dynamic>;
      final callData = CallLandlordData.fromJson(data);
      _logger.i('玩家 ${callData.playerId} 叫地主: ${callData.call}');
    } catch (e) {
      _logger.e('处理叫地主失败: $e');
    }
  }

  /// 处理回合变更
  void _handleTurnChange(Map<String, dynamic> message) {
    final playerIndex = message['currentPlayerIndex'] as int;
    _logger.d('回合变更: 玩家 $playerIndex');
  }

  /// 处理游戏结束
  void _handleGameEnd(Map<String, dynamic> message) {
    final result = message['result'] as Map<String, dynamic>;
    _logger.i('游戏结束: $result');
  }

  // ==================== 本地存储实现 ====================

  @override
  Future<void> saveGameState(GameState state) async {
    try {
      final stateJson = _serializer.serializeGameStatePublic(state);
      final jsonString = jsonEncode(stateJson);
      await _prefs.setString(_gameStateKey, jsonString);
      _logger.i('游戏状态已保存到本地');
    } catch (e) {
      _logger.e('保存游戏状态失败: $e');
      rethrow;
    }
  }

  @override
  Future<GameState?> loadGameState() async {
    try {
      final jsonString = _prefs.getString(_gameStateKey);
      if (jsonString == null) {
        _logger.d('本地没有保存的游戏状态');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final state = _deserializeGameState(json);
      _logger.i('从本地加载游戏状态');
      return state;
    } catch (e) {
      _logger.e('加载游戏状态失败: $e');
      return null;
    }
  }

  /// 反序列化游戏状态
  GameState? _deserializeGameState(Map<String, dynamic> json) {
    try {
      final phase = GamePhase.values[json['phase'] as int];
      final currentPlayerIndex = json['currentPlayerIndex'] as int;
      final landlordIndex = json['landlordIndex'] as int?;
      final callingPlayerIndex = json['callingPlayerIndex'] as int?;
      final lastPlayerIndex = json['lastPlayerIndex'] as int?;
      final callCount = json['callCount'] as int? ?? 0;

      // 反序列化玩家列表
      final playersJson = json['players'] as List<dynamic>?;
      final players = playersJson
              ?.map((p) => _deserializePlayer(p as Map<String, dynamic>))
              .whereType<LocalAIPlayer>()
              .toList() ??
          [];

      // 反序列化底牌
      final landlordCardsJson = json['landlordCards'] as List<dynamic>?;
      final landlordCards = landlordCardsJson != null
          ? _serializer.deserializeCards(landlordCardsJson)
          : <Card>[];

      // 反序列化上一手牌
      final lastPlayedCardsJson = json['lastPlayedCards'] as List<dynamic>?;
      final lastPlayedCards = lastPlayedCardsJson != null
          ? _serializer.deserializeCards(lastPlayedCardsJson)
          : null;

      return GameState(
        phase: phase,
        players: players,
        currentPlayerIndex: currentPlayerIndex,
        landlordCards: landlordCards,
        lastPlayedCards: lastPlayedCards,
        lastPlayerIndex: lastPlayerIndex,
        landlordIndex: landlordIndex,
        callingPlayerIndex: callingPlayerIndex,
        callCount: callCount,
      );
    } catch (e) {
      _logger.e('反序列化游戏状态失败: $e');
      return null;
    }
  }

  /// 反序列化玩家（使用 LocalAIPlayer 作为占位符）
  LocalAIPlayer? _deserializePlayer(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String;
      final name = json['name'] as String;
      final roleIndex = json['role'] as int?;
      final handCardsJson = json['handCards'] as List<dynamic>?;

      final handCards = handCardsJson != null
          ? _serializer.deserializeCards(handCardsJson)
          : <Card>[];

      return LocalAIPlayer(
        id: id,
        name: name,
        handCards: handCards,
        role: roleIndex != null ? PlayerRole.values[roleIndex] : null,
      );
    } catch (e) {
      _logger.e('反序列化玩家失败: $e');
      return null;
    }
  }

  @override
  Future<void> clearGameState() async {
    try {
      await _prefs.remove(_gameStateKey);
      _logger.i('本地游戏状态已清除');
    } catch (e) {
      _logger.e('清除游戏状态失败: $e');
      rethrow;
    }
  }

  // ==================== 局域网对战实现 ====================

  @override
  Future<void> syncGameState(GameState state) async {
    if (!_isLanMode || _wsClient == null) {
      _logger.w('非局域网模式，无法同步游戏状态');
      return;
    }

    try {
      _wsClient!.send({
        'type': 'game_state_sync',
        'state': _serializer.serializeGameStateForPlayer(
          state,
          _currentPlayerId!,
        ),
      });
      _logger.d('游戏状态已同步到服务器');
    } catch (e) {
      _logger.e('同步游戏状态失败: $e');
      rethrow;
    }
  }

  @override
  Stream<GameState> watchRemoteState() {
    if (!_isLanMode) {
      _logger.w('非局域网模式，远程状态流不可用');
      return const Stream.empty();
    }
    return _remoteStateController.stream;
  }

  @override
  Future<void> sendPlayAction(String playerId, List<Card> cards) async {
    if (!_isLanMode || _wsClient == null) {
      throw StateError('非局域网模式，无法发送出牌动作');
    }

    try {
      _wsClient!.send({
        'type': 'play_cards',
        'data': PlayCardsData(playerId: playerId, cards: cards).toJson(),
      });
      _logger.i('出牌动作已发送: $playerId 出 ${cards.length} 张牌');
    } catch (e) {
      _logger.e('发送出牌动作失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendPassAction(String playerId) async {
    if (!_isLanMode || _wsClient == null) {
      throw StateError('非局域网模式，无法发送过牌动作');
    }

    try {
      _wsClient!.send({
        'type': 'pass',
        'playerId': playerId,
      });
      _logger.i('过牌动作已发送: $playerId');
    } catch (e) {
      _logger.e('发送过牌动作失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendCallAction(String playerId, bool call) async {
    if (!_isLanMode || _wsClient == null) {
      throw StateError('非局域网模式，无法发送叫地主动作');
    }

    try {
      _wsClient!.send({
        'type': 'call_landlord',
        'data': CallLandlordData(playerId: playerId, call: call).toJson(),
      });
      _logger.i('叫地主动作已发送: $playerId -> $call');
    } catch (e) {
      _logger.e('发送叫地主动作失败: $e');
      rethrow;
    }
  }

  /// 释放资源
  void dispose() {
    _remoteStateController.close();
    _wsClient = null;
  }
}
