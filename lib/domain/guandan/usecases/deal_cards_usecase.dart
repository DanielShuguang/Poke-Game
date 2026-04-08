import 'dart:math';
import '../entities/guandan_card.dart';
import '../entities/guandan_player.dart';

/// 洗牌并发牌（108张，4名玩家各27张）
class DealCardsUsecase {
  const DealCardsUsecase._();

  /// 洗牌后按座位顺序发给 [players]，每人27张
  static List<GuandanPlayer> deal(
    List<GuandanPlayer> players, {
    Random? random,
  }) {
    assert(players.length == 4, 'Guandan requires exactly 4 players');

    final rng = random ?? Random();
    final deck = GuandanCard.fullDeck()..shuffle(rng);

    return List.generate(players.length, (i) {
      final start = i * 27;
      final hand = deck.sublist(start, start + 27)..sort();
      return players[i].copyWith(cards: hand, clearFinishRank: true);
    });
  }
}
