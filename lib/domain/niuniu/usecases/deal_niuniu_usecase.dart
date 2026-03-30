import 'dart:math';

import 'package:poke_game/domain/niuniu/entities/niuniu_card.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_game_config.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_game_state.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_hand.dart';

/// 牛牛发牌 UseCase
///
/// 从牌堆为每位玩家（含庄家）发 5 张牌，阶段切换为 showdown。
class DealNiuniuUseCase {
  const DealNiuniuUseCase();

  /// 构建并洗牌（deckCount 副标准牌）
  static List<NiuniuCard> buildShuffledDeck(NiuniuGameConfig config) {
    final deck = <NiuniuCard>[];
    for (int i = 0; i < config.deckCount; i++) {
      deck.addAll(NiuniuCard.standardDeck());
    }
    deck.shuffle(Random());
    return deck;
  }

  NiuniuGameState call(NiuniuGameState state) {
    final deck = List.of(state.deck);
    final players = List.of(state.players);

    // 每位玩家发 5 张牌
    final dealtPlayers = players.map((player) {
      if (deck.length < 5) {
        return player; // 牌不够时跳过（不应发生）
      }
      final cards = deck.sublist(0, 5);
      deck.removeRange(0, 5);
      return player.copyWith(hand: NiuniuHand(cards: cards));
    }).toList();

    return state.copyWith(
      deck: deck,
      players: dealtPlayers,
      phase: NiuniuPhase.showdown,
    );
  }
}
