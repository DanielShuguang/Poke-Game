import 'dart:math';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_config.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';

/// 发牌用例
class DealCardsUseCase {
  final GameConfig _config;
  final Random _random;

  DealCardsUseCase({
    GameConfig config = GameConfig.defaultConfig,
    Random? random,
  })  : _config = config,
        _random = random ?? Random();

  /// 执行发牌
  GameState call(List<Player> players) {
    if (players.length != _config.playerCount) {
      throw ArgumentError('玩家数量必须为 ${_config.playerCount}');
    }

    // 创建并洗牌
    final deck = createFullDeck()..shuffle(_random);

    // 发牌
    var cardIndex = 0;
    for (var i = 0; i < _config.playerCount; i++) {
      final handCards = deck
          .sublist(
            cardIndex,
            cardIndex + _config.initialCardCount,
          )
          .toList();
      handCards.sort();
      players[i].handCards = handCards;
      cardIndex += _config.initialCardCount;
    }

    // 底牌
    final landlordCards = deck.sublist(cardIndex).toList();
    landlordCards.sort();

    return GameState(
      phase: GamePhase.calling,
      players: players,
      currentPlayerIndex: 0,
      landlordCards: landlordCards,
      callingPlayerIndex: 0,
    );
  }
}
