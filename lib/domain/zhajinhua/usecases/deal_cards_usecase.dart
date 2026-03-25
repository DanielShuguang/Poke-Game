import 'dart:math';
import 'package:poke_game/domain/zhajinhua/entities/zhj_card.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_config.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';

/// 发牌用例：洗牌52张，每人发3张，并收取底注
class DealCardsUsecase {
  final Random _random;

  DealCardsUsecase({Random? random}) : _random = random ?? Random();

  ZhjGameState execute(ZhjGameState state, ZhjGameConfig config) {
    final deck = ZhjCard.standardDeck();

    // 洗牌
    for (int i = deck.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = deck[i];
      deck[i] = deck[j];
      deck[j] = tmp;
    }

    // 发牌并收底注
    final players = <ZhjPlayer>[];
    int cardIndex = 0;
    int pot = 0;

    for (final player in state.players) {
      final hand = deck.sublist(cardIndex, cardIndex + 3);
      cardIndex += 3;
      final betAmount = config.baseBet.clamp(0, player.chips);
      pot += betAmount;
      players.add(player.copyWith(
        cards: hand,
        hasPeeked: false,
        isFolded: false,
        betAmount: betAmount,
        chips: player.chips - betAmount,
      ));
    }

    return state.copyWith(
      phase: ZhjGamePhase.betting,
      players: players,
      pot: pot,
      currentBet: config.baseBet,
      currentPlayerIndex: 0,
      clearWinner: true,
      clearMessage: true,
    );
  }
}
