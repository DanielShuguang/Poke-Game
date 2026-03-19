import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 玩家角色
enum PlayerRole {
  /// 地主
  landlord,

  /// 农民
  peasant,
}

/// 出牌决策
class PlayDecision {
  /// 是否出牌
  final bool shouldPlay;

  /// 出的牌（如果选择出牌）
  final List<Card>? cards;

  const PlayDecision.pass()
      : shouldPlay = false,
        cards = null;

  const PlayDecision.play(this.cards) : shouldPlay = true;

  /// 是否是过牌
  bool get isPass => !shouldPlay;
}

/// 叫地主决策
class CallDecision {
  /// 是否叫地主
  final bool shouldCall;

  const CallDecision.call() : shouldCall = true;

  const CallDecision.pass() : shouldCall = false;
}

/// 玩家抽象接口
abstract class Player {
  /// 玩家ID
  String get id;

  /// 玩家名称
  String get name;

  /// 手牌
  List<Card> get handCards;

  /// 设置手牌
  set handCards(List<Card> cards);

  /// 玩家角色
  PlayerRole? role;

  /// 出牌决策
  Future<PlayDecision> decidePlay(List<Card>? lastPlayedCards, int? lastPlayerIndex);

  /// 叫地主决策
  Future<CallDecision> decideCall();
}
