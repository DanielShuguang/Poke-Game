import '../entities/pdk_card.dart';
import '../entities/pdk_game_state.dart';
import '../entities/pdk_player.dart';

class DealCardsUseCase {
  const DealCardsUseCase();

  PdkGameState call(List<PdkPlayer> players) {
    assert(players.length == 3);
    final deck = PdkCard.fullDeck(); // already shuffled
    final hands = [
      deck.sublist(0, 18),
      deck.sublist(18, 36),
      deck.sublist(36, 54),
    ];

    // 找持有 ♠3 的玩家
    int firstIndex = 0;
    for (int i = 0; i < 3; i++) {
      if (hands[i].any((c) => c.isSpadeThree)) {
        firstIndex = i;
        break;
      }
    }

    final dealtPlayers = List.generate(
      3,
      (i) => players[i].copyWith(hand: hands[i]..sort((a, b) => a.compareTo(b))),
    );

    return PdkGameState(
      players: dealtPlayers,
      currentPlayerIndex: firstIndex,
      phase: PdkGamePhase.playing,
      isFirstPlay: true,
    );
  }
}
