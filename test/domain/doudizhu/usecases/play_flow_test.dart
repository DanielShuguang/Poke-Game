import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';
import 'package:poke_game/domain/doudizhu/usecases/play_cards_usecase.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';

void main() {
  late PlayCardsUseCase playCardsUseCase;
  late CardValidator validator;

  setUp(() {
    playCardsUseCase = PlayCardsUseCase();
    validator = const CardValidator();
  });

  group('Play flow simulation', () {
    test('two AIs pass and player should get new round', () async {
      // 创建三个玩家
      final player1 = _TestPlayer(
        id: 'p1',
        name: 'Player 1 (Human)',
        initialCards: [
          const Card(suit: Suit.heart, rank: 3),
          const Card(suit: Suit.spade, rank: 4),
          const Card(suit: Suit.club, rank: 5),
        ],
      );

      final player2 = _TestPlayer(
        id: 'p2',
        name: 'AI 1',
        initialCards: [
          const Card(suit: Suit.heart, rank: 10),
          const Card(suit: Suit.spade, rank: 11),
        ],
      );

      final player3 = _TestPlayer(
        id: 'p3',
        name: 'AI 2',
        initialCards: [
          const Card(suit: Suit.heart, rank: 13),
          const Card(suit: Suit.spade, rank: 14),
        ],
      );

      // 初始状态：玩家1出了一对3
      var gameState = GameState(
        phase: GamePhase.playing,
        players: [player1, player2, player3],
        currentPlayerIndex: 1, // 下一个玩家是 AI 1
        landlordCards: [],
        lastPlayedCards: [
          const Card(suit: Suit.heart, rank: 3),
          const Card(suit: Suit.spade, rank: 3),
        ],
        lastPlayerIndex: 0,
        landlordIndex: 0,
      );

      // AI 1 过牌
      gameState = playCardsUseCase.pass(gameState, 'p2');
      expect(gameState.currentPlayerIndex, 2); // 应该轮到 AI 2
      expect(gameState.lastPlayedCards?.length, 2); // 桌面上的牌应该还是一对3

      // AI 2 过牌
      gameState = playCardsUseCase.pass(gameState, 'p3');
      expect(gameState.currentPlayerIndex, 0); // 应该轮到玩家1
      expect(gameState.lastPlayedCards, isNull); // 桌面应该清空（新一轮）
      expect(gameState.lastPlayerIndex, isNull);
    });

    test('first AI passes, second AI plays bigger single', () async {
      // 创建三个玩家
      // rank: 3-15, 3-10为数字, 11=J, 12=Q, 13=K, 14=A, 15=2
      final player1 = _TestPlayer(
        id: 'p1',
        name: 'Player 1 (Human)',
        initialCards: [],
      );

      // AI 1 没有比 K 大的单张
      final player2 = _TestPlayer(
        id: 'p2',
        name: 'AI 1',
        initialCards: [
          const Card(suit: Suit.heart, rank: 10), // 10
          const Card(suit: Suit.spade, rank: 11), // J
        ],
      );

      // AI 2 有 A，比 K 大
      final player3 = _TestPlayer(
        id: 'p3',
        name: 'AI 2',
        initialCards: [
          const Card(suit: Suit.heart, rank: 14), // A
        ],
      );

      // 初始状态：玩家1出了一张 K
      var gameState = GameState(
        phase: GamePhase.playing,
        players: [player1, player2, player3],
        currentPlayerIndex: 1,
        landlordCards: [],
        lastPlayedCards: [const Card(suit: Suit.heart, rank: 13)], // K
        lastPlayerIndex: 0,
        landlordIndex: 0,
      );

      // AI 1 过牌（没有比 K 大的单张）
      gameState = playCardsUseCase.pass(gameState, 'p2');
      expect(gameState.currentPlayerIndex, 2);
      expect(gameState.lastPlayedCards?.first.rank, 13); // K 还在桌上

      // AI 2 出 A（比 K 大）
      gameState = playCardsUseCase(gameState, 'p3', [const Card(suit: Suit.heart, rank: 14)]);
      expect(gameState.lastPlayedCards?.first.rank, 14); // A
      expect(gameState.currentPlayerIndex, 0); // 轮到玩家1
    });

    test('straight followed by pass should keep straight on table', () async {
      // 玩家1出了顺子 3-7
      final straight = [
        const Card(suit: Suit.heart, rank: 3),
        const Card(suit: Suit.spade, rank: 4),
        const Card(suit: Suit.club, rank: 5),
        const Card(suit: Suit.diamond, rank: 6),
        const Card(suit: Suit.heart, rank: 7),
      ];

      final player1 = _TestPlayer(
        id: 'p1',
        name: 'Player 1',
        initialCards: [],
      );

      // AI 1 没有更大的顺子，也没有炸弹
      final player2 = _TestPlayer(
        id: 'p2',
        name: 'AI 1',
        initialCards: [
          const Card(suit: Suit.heart, rank: 10),
          const Card(suit: Suit.spade, rank: 11),
        ],
      );

      // AI 2 有炸弹
      final player3 = _TestPlayer(
        id: 'p3',
        name: 'AI 2',
        initialCards: [
          const Card(suit: Suit.heart, rank: 8),
          const Card(suit: Suit.spade, rank: 8),
          const Card(suit: Suit.club, rank: 8),
          const Card(suit: Suit.diamond, rank: 8),
        ],
      );

      var gameState = GameState(
        phase: GamePhase.playing,
        players: [player1, player2, player3],
        currentPlayerIndex: 1,
        landlordCards: [],
        lastPlayedCards: straight,
        lastPlayerIndex: 0,
        landlordIndex: 0,
      );

      // AI 1 过牌
      gameState = playCardsUseCase.pass(gameState, 'p2');
      expect(gameState.lastPlayedCards?.length, 5); // 顺子应该还在桌上

      // AI 2 出炸弹
      final bomb = [
        const Card(suit: Suit.heart, rank: 8),
        const Card(suit: Suit.spade, rank: 8),
        const Card(suit: Suit.club, rank: 8),
        const Card(suit: Suit.diamond, rank: 8),
      ];
      gameState = playCardsUseCase(gameState, 'p3', bomb);
      expect(gameState.lastPlayedCards?.length, 4);
      expect(validator.validate(gameState.lastPlayedCards!), CardCombination.bomb);
    });
  });

  group('GameState copyWith', () {
    test('should preserve lastPlayedCards when not specified', () {
      final state = GameState(
        phase: GamePhase.playing,
        players: [],
        currentPlayerIndex: 0,
        landlordCards: [],
        lastPlayedCards: [const Card(suit: Suit.heart, rank: 3)],
        lastPlayerIndex: 0,
      );

      final newState = state.copyWith(currentPlayerIndex: 1);
      expect(newState.lastPlayedCards?.length, 1);
      expect(newState.lastPlayerIndex, 0);
    });

    test('should clear lastPlayedCards when flag is set', () {
      final state = GameState(
        phase: GamePhase.playing,
        players: [],
        currentPlayerIndex: 0,
        landlordCards: [],
        lastPlayedCards: [const Card(suit: Suit.heart, rank: 3)],
        lastPlayerIndex: 0,
      );

      final newState = state.copyWith(
        currentPlayerIndex: 1,
        clearLastPlayedCards: true,
        clearLastPlayerIndex: true,
      );
      expect(newState.lastPlayedCards, isNull);
      expect(newState.lastPlayerIndex, isNull);
    });
  });
}

class _TestPlayer implements Player {
  @override
  final String id;

  @override
  final String name;

  @override
  List<Card> handCards;

  @override
  PlayerRole? role;

  _TestPlayer({
    required this.id,
    String? name,
    List<Card>? initialCards,
  })  : name = name ?? 'Test',
        handCards = initialCards ?? [];

  @override
  Future<PlayDecision> decidePlay(List<Card>? lastPlayedCards, int? lastPlayerIndex) {
    throw UnimplementedError();
  }

  @override
  Future<CallDecision> decideCall() {
    throw UnimplementedError();
  }
}
