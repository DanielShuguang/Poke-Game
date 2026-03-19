import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/ai/ai_player.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';
import 'package:poke_game/domain/doudizhu/usecases/call_landlord_usecase.dart';
import 'package:poke_game/domain/doudizhu/usecases/deal_cards_usecase.dart';

void main() {
  group('DealCardsUseCase', () {
    late DealCardsUseCase useCase;

    setUp(() {
      useCase = DealCardsUseCase();
    });

    test('should deal cards to all players', () {
      final players = [
        _TestPlayer(id: 'p1'),
        _TestPlayer(id: 'p2'),
        _TestPlayer(id: 'p3'),
      ];

      final state = useCase(players);

      expect(state.phase, GamePhase.calling);
      expect(state.players.length, 3);
      expect(state.landlordCards.length, 3);

      for (final player in players) {
        expect(player.handCards.length, 17);
      }
    });

    test('should throw if player count is wrong', () {
      final players = [
        _TestPlayer(id: 'p1'),
        _TestPlayer(id: 'p2'),
      ];

      expect(() => useCase(players), throwsArgumentError);
    });
  });

  group('CallLandlordUseCase', () {
    late CallLandlordUseCase useCase;

    setUp(() {
      useCase = CallLandlordUseCase();
    });

    test('should set player as landlord when calling', () {
      final players = [
        _TestPlayer(id: 'p1', initialCards: 17),
        _TestPlayer(id: 'p2', initialCards: 17),
        _TestPlayer(id: 'p3', initialCards: 17),
      ];

      var state = GameState(
        phase: GamePhase.calling,
        players: players,
        currentPlayerIndex: 0,
        landlordCards: [
          const Card(suit: Suit.heart, rank: 3),
          const Card(suit: Suit.spade, rank: 3),
          const Card(suit: Suit.club, rank: 3),
        ],
        callingPlayerIndex: 0,
      );

      state = useCase(state, 'p1', true);

      expect(state.phase, GamePhase.playing);
      expect(state.landlordIndex, 0);
      expect(players[0].role, PlayerRole.landlord);
      expect(players[1].role, PlayerRole.peasant);
      expect(players[2].role, PlayerRole.peasant);
      // Landlord should have 20 cards (17 + 3)
      expect(players[0].handCards.length, 20);
    });

    test('should move to next player when passing', () {
      final players = [
        _TestPlayer(id: 'p1'),
        _TestPlayer(id: 'p2'),
        _TestPlayer(id: 'p3'),
      ];

      var state = GameState(
        phase: GamePhase.calling,
        players: players,
        currentPlayerIndex: 0,
        landlordCards: [
          const Card(suit: Suit.heart, rank: 3),
          const Card(suit: Suit.spade, rank: 3),
          const Card(suit: Suit.club, rank: 3),
        ],
        callingPlayerIndex: 0,
      );

      state = useCase(state, 'p1', false);

      expect(state.phase, GamePhase.calling);
      expect(state.callingPlayerIndex, 1);
      expect(state.callCount, 1);
    });

    test('should restart game when all players pass', () {
      final players = [
        _TestPlayer(id: 'p1'),
        _TestPlayer(id: 'p2'),
        _TestPlayer(id: 'p3'),
      ];

      var state = GameState(
        phase: GamePhase.calling,
        players: players,
        currentPlayerIndex: 0,
        landlordCards: [
          const Card(suit: Suit.heart, rank: 3),
          const Card(suit: Suit.spade, rank: 3),
          const Card(suit: Suit.club, rank: 3),
        ],
        callingPlayerIndex: 2,
        callCount: 2,
      );

      state = useCase(state, 'p3', false);

      expect(state.phase, GamePhase.waiting);
      expect(state.players, isEmpty);
    });
  });
}

class _TestPlayer implements Player {
  @override
  final String id;

  @override
  String get name => 'Test';

  @override
  List<Card> handCards;

  @override
  PlayerRole? role;

  _TestPlayer({required this.id, int initialCards = 0})
      : handCards = List.generate(
          initialCards,
          (i) => Card(suit: Suit.values[i % 4], rank: 3 + (i ~/ 4) % 13),
        );

  @override
  Future<PlayDecision> decidePlay(
    List<Card>? lastPlayedCards,
    int? lastPlayerIndex,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<CallDecision> decideCall() {
    throw UnimplementedError();
  }
}
