import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 游戏事件基类
abstract class GameEvent {
  /// 时间戳
  final DateTime timestamp;

  /// 玩家ID
  final String playerId;

  const GameEvent({
    required this.timestamp,
    required this.playerId,
  });
}

/// 发牌事件
class DealCardsEvent extends GameEvent {
  /// 玩家手牌
  final List<Card> handCards;

  const DealCardsEvent({
    required super.timestamp,
    required super.playerId,
    required this.handCards,
  });
}

/// 叫地主事件
class CallLandlordEvent extends GameEvent {
  /// 是否叫地主
  final bool call;

  const CallLandlordEvent({
    required super.timestamp,
    required super.playerId,
    required this.call,
  });
}

/// 出牌事件
class PlayCardsEvent extends GameEvent {
  /// 出的牌
  final List<Card> cards;

  /// 是否是过牌
  final bool isPass;

  const PlayCardsEvent({
    required super.timestamp,
    required super.playerId,
    required this.cards,
    this.isPass = false,
  });

  /// 创建过牌事件
  const PlayCardsEvent.pass({
    required super.timestamp,
    required super.playerId,
  })  : cards = const [],
        isPass = true;
}

/// 游戏结束事件
class GameOverEvent extends GameEvent {
  /// 获胜者ID列表
  final List<String> winnerIds;

  const GameOverEvent({
    required super.timestamp,
    required super.playerId,
    required this.winnerIds,
  });
}
