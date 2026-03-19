import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';
import 'package:poke_game/domain/doudizhu/ai/strategies/play_strategy.dart';
import 'package:poke_game/domain/doudizhu/ai/strategies/call_strategy.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';
import 'package:poke_game/domain/doudizhu/entities/game_config.dart';

/// AI 玩家实现
class AiPlayer implements Player {
  @override
  final String id;

  @override
  final String name;

  @override
  List<Card> handCards;

  @override
  PlayerRole? role;

  final PlayStrategy _playStrategy;
  final CallStrategy _callStrategy;
  final int _thinkDelayMs;

  AiPlayer({
    required this.id,
    required this.name,
    PlayStrategy? playStrategy,
    CallStrategy? callStrategy,
    int? thinkDelayMs,
  })  : _playStrategy = playStrategy ?? const SimplePlayStrategy(),
        _callStrategy = callStrategy ?? const SimpleCallStrategy(),
        _thinkDelayMs = thinkDelayMs ?? GameConfig.defaultConfig.aiThinkDelayMs,
        handCards = const [],
        role = null;

  @override
  Future<PlayDecision> decidePlay(
    List<Card>? lastPlayedCards,
    int? lastPlayerIndex,
  ) async {
    // 模拟思考延迟
    await Future.delayed(Duration(milliseconds: _thinkDelayMs));

    return _playStrategy.decide(
      handCards: handCards,
      lastPlayedCards: lastPlayedCards,
      lastPlayerIndex: lastPlayerIndex,
      validator: const CardValidator(),
    );
  }

  @override
  Future<CallDecision> decideCall() async {
    // 模拟思考延迟
    await Future.delayed(Duration(milliseconds: _thinkDelayMs));

    return _callStrategy.decide(handCards: handCards);
  }
}
