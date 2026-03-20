import 'dart:async';

import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';
import 'package:poke_game/domain/lan/entities/game_event.dart';

/// 玩家接口抽象层
///
/// 统一本地 AI 和远程真人的接口
abstract class PlayerInterface implements Player {
  /// 收到发牌通知
  Future<void> onCardsDealt(List<Card> cards);

  /// 收到游戏事件
  void onGameEvent(GameEvent event);

  /// 收到回合开始通知
  void onTurnStarted(GameState state);

  /// 收到游戏结束通知
  void onGameEnded(Map<String, dynamic> result);
}

/// 本地 AI 玩家实现
class LocalAIPlayer implements PlayerInterface {
  @override
  final String id;

  @override
  final String name;

  @override
  List<Card> handCards;

  @override
  PlayerRole? role;

  final Future<PlayDecision> Function(List<Card>? lastPlayedCards, int? lastPlayerIndex)? _decidePlayCallback;
  final Future<CallDecision> Function()? _decideCallCallback;

  LocalAIPlayer({
    required this.id,
    required this.name,
    this.handCards = const [],
    this.role,
    Future<PlayDecision> Function(List<Card>? lastPlayedCards, int? lastPlayerIndex)? decidePlayCallback,
    Future<CallDecision> Function()? decideCallCallback,
  })  : _decidePlayCallback = decidePlayCallback,
        _decideCallCallback = decideCallCallback;

  @override
  Future<PlayDecision> decidePlay(List<Card>? lastPlayedCards, int? lastPlayerIndex) async {
    if (_decidePlayCallback != null) {
      return _decidePlayCallback!(lastPlayedCards, lastPlayerIndex);
    }
    // 默认行为：过牌
    return const PlayDecision.pass();
  }

  @override
  Future<CallDecision> decideCall() async {
    if (_decideCallCallback != null) {
      return _decideCallCallback!();
    }
    // 默认行为：不叫
    return const CallDecision.pass();
  }

  @override
  Future<void> onCardsDealt(List<Card> cards) async {
    handCards = cards;
  }

  @override
  void onGameEvent(GameEvent event) {
    // AI 不需要处理网络事件
  }

  @override
  void onTurnStarted(GameState state) {
    // AI 开始思考
  }

  @override
  void onGameEnded(Map<String, dynamic> result) {
    // AI 收到游戏结束通知
  }
}

/// 远程玩家实现
class RemotePlayer implements PlayerInterface {
  @override
  final String id;

  @override
  final String name;

  @override
  List<Card> handCards;

  @override
  PlayerRole? role;

  /// 发送操作回调
  final void Function(String action, Map<String, dynamic> data)? sendAction;

  /// 出牌决策完成器
  Completer<PlayDecision>? _playCompleter;

  /// 叫地主决策完成器
  Completer<CallDecision>? _callCompleter;

  RemotePlayer({
    required this.id,
    required this.name,
    this.handCards = const [],
    this.role,
    this.sendAction,
  });

  @override
  Future<PlayDecision> decidePlay(List<Card>? lastPlayedCards, int? lastPlayerIndex) async {
    // 发送请求出牌的消息
    sendAction?.call('request_play', {
      'lastPlayedCards': lastPlayedCards?.map((c) => '${c.suit.index}:${c.rank}').toList(),
      'lastPlayerIndex': lastPlayerIndex,
    });

    // 等待远程玩家的响应
    _playCompleter = Completer<PlayDecision>();
    return _playCompleter!.future;
  }

  @override
  Future<CallDecision> decideCall() async {
    // 发送请求叫地主的消息
    sendAction?.call('request_call', {});

    // 等待远程玩家的响应
    _callCompleter = Completer<CallDecision>();
    return _callCompleter!.future;
  }

  /// 处理远程玩家发送的出牌响应
  void handlePlayResponse(List<Card>? cards) {
    if (_playCompleter != null && !_playCompleter!.isCompleted) {
      if (cards == null) {
        _playCompleter!.complete(const PlayDecision.pass());
      } else {
        _playCompleter!.complete(PlayDecision.play(cards));
      }
      _playCompleter = null;
    }
  }

  /// 处理远程玩家发送的叫地主响应
  void handleCallResponse(bool call) {
    if (_callCompleter != null && !_callCompleter!.isCompleted) {
      if (call) {
        _callCompleter!.complete(const CallDecision.call());
      } else {
        _callCompleter!.complete(const CallDecision.pass());
      }
      _callCompleter = null;
    }
  }

  @override
  Future<void> onCardsDealt(List<Card> cards) async {
    handCards = cards;
    // 发送发牌事件给远程玩家
    sendAction?.call('deal_cards', {
      'cards': cards.map((c) => '${c.suit.index}:${c.rank}').toList(),
    });
  }

  @override
  void onGameEvent(GameEvent event) {
    // 转发游戏事件给远程玩家
    sendAction?.call('game_event', event.toJson());
  }

  @override
  void onTurnStarted(GameState state) {
    // 通知远程玩家回合开始
    sendAction?.call('turn_started', {
      'currentPlayerIndex': state.currentPlayerIndex,
    });
  }

  @override
  void onGameEnded(Map<String, dynamic> result) {
    // 通知远程玩家游戏结束
    sendAction?.call('game_ended', result);
  }
}
