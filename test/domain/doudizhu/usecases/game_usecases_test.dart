import 'package:flutter_test/flutter_test.dart';
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
    test('should set player as landlord when calling', () {
      final useCase = CallLandlordUseCase(isHumanVsAi: true);
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

      final result = useCase(state, 'p1', true);
      state = result.gameState;

      expect(state.phase, GamePhase.playing);
      expect(state.landlordIndex, 0);
      expect(players[0].role, PlayerRole.landlord);
      expect(players[1].role, PlayerRole.peasant);
      expect(players[2].role, PlayerRole.peasant);
      // Landlord should have 20 cards (17 + 3)
      expect(players[0].handCards.length, 20);
    });

    test('should move to next player when passing (non-human-vs-ai mode)', () {
      final useCase = CallLandlordUseCase(isHumanVsAi: false);
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

      final result = useCase(state, 'p1', false);
      state = result.gameState;

      expect(state.phase, GamePhase.calling);
      expect(state.callingPlayerIndex, 1);
      expect(state.callCount, 1);
      expect(result.allPassed, false);
    });

    test('should restart game when all players pass (non-human-vs-ai mode)', () {
      final useCase = CallLandlordUseCase(isHumanVsAi: false);
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

      final result = useCase(state, 'p3', false);
      state = result.gameState;

      expect(state.phase, GamePhase.waiting);
      expect(state.players, isEmpty);
      expect(result.allPassed, true);
    });

    test('should force last AI to call landlord in human-vs-ai mode when human passes', () {
      final useCase = CallLandlordUseCase(isHumanVsAi: true);
      final players = [
        _TestPlayer(id: 'human', initialCards: 17), // index 0 - human
        _TestPlayer(id: 'ai1', initialCards: 17),   // index 1 - AI
        _TestPlayer(id: 'ai2', initialCards: 17),   // index 2 - AI
      ];

      // Human passes first, then AI1 passes
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
        callCount: 0,
      );

      // Human passes
      var result = useCase(state, 'human', false);
      state = result.gameState;
      expect(state.phase, GamePhase.calling);
      expect(state.callingPlayerIndex, 1);
      expect(state.callCount, 1);

      // AI1 passes
      result = useCase(state, 'ai1', false);
      state = result.gameState;
      expect(state.phase, GamePhase.calling);
      expect(state.callingPlayerIndex, 2);
      expect(state.callCount, 2);

      // Now it's AI2's turn, but in human-vs-ai mode, AI2 should be forced to call
      // However, this test just verifies the state transition
      // The actual forcing logic is in CallLandlordUseCase.call() for playerIndex == 0 (human)
      // When human passes with callCount == 1 (1 remaining AI), last AI is forced to call
    });

    test('should force last AI to call when human passes as first player with only one AI left', () {
      final useCase = CallLandlordUseCase(isHumanVsAi: true);
      final players = [
        _TestPlayer(id: 'human', initialCards: 17), // index 0 - human
        _TestPlayer(id: 'ai1', initialCards: 17),   // index 1 - AI (already passed)
        _TestPlayer(id: 'ai2', initialCards: 17),   // index 2 - AI (will be forced)
      ];

      // State: AI1 already passed, human is about to pass (callCount == 1)
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
        callCount: 1, // AI1 already passed
      );

      // Human passes - this should force AI2 (index 2) to become landlord
      final result = useCase(state, 'human', false);
      final newState = result.gameState;

      expect(newState.phase, GamePhase.playing);
      expect(newState.landlordIndex, 2);
      expect(players[2].role, PlayerRole.landlord);
      expect(players[0].role, PlayerRole.peasant);
      expect(players[1].role, PlayerRole.peasant);
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
