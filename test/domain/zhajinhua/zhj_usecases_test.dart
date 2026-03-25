import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_card.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_config.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';
import 'package:poke_game/domain/zhajinhua/usecases/betting_usecase.dart';
import 'package:poke_game/domain/zhajinhua/usecases/deal_cards_usecase.dart';
import 'package:poke_game/domain/zhajinhua/usecases/peek_card_usecase.dart';
import 'package:poke_game/domain/zhajinhua/usecases/showdown_usecase.dart';

ZhjGameState _makeState({int currentPlayerIndex = 0}) {
  final players = [
    ZhjPlayer(id: 'p1', name: '玩家', isAi: false, chips: 1000),
    ZhjPlayer(id: 'ai1', name: 'AI1', isAi: true, chips: 1000),
    ZhjPlayer(id: 'ai2', name: 'AI2', isAi: true, chips: 1000),
  ];
  return ZhjGameState(
    phase: ZhjGamePhase.betting,
    players: players,
    pot: 30,
    currentBet: 10,
    currentPlayerIndex: currentPlayerIndex,
  );
}

void main() {
  group('DealCardsUsecase', () {
    test('发牌后每人3张牌', () {
      final state = ZhjGameState.initial().copyWith(
        players: [
          ZhjPlayer(id: 'p1', name: '玩家', isAi: false, chips: 1000),
          ZhjPlayer(id: 'ai1', name: 'AI1', isAi: true, chips: 1000),
          ZhjPlayer(id: 'ai2', name: 'AI2', isAi: true, chips: 1000),
        ],
      );
      final result = DealCardsUsecase().execute(state, ZhjGameConfig.defaultConfig);
      for (final p in result.players) {
        expect(p.cards.length, 3);
      }
    });

    test('底注从筹码扣除并计入底池', () {
      final state = ZhjGameState.initial().copyWith(
        players: [
          ZhjPlayer(id: 'p1', name: '玩家', isAi: false, chips: 1000),
          ZhjPlayer(id: 'ai1', name: 'AI1', isAi: true, chips: 1000),
          ZhjPlayer(id: 'ai2', name: 'AI2', isAi: true, chips: 1000),
        ],
      );
      final result = DealCardsUsecase().execute(state, ZhjGameConfig.defaultConfig);
      expect(result.pot, 30); // 3人 × 底注10
      for (final p in result.players) {
        expect(p.chips, 990);
      }
    });

    test('每人牌不重复', () {
      final state = ZhjGameState.initial().copyWith(
        players: [
          ZhjPlayer(id: 'p1', name: '玩家', isAi: false, chips: 1000),
          ZhjPlayer(id: 'ai1', name: 'AI1', isAi: true, chips: 1000),
        ],
      );
      final result = DealCardsUsecase().execute(state, ZhjGameConfig.defaultConfig);
      final allCards = result.players.expand((p) => p.cards).toList();
      expect(allCards.toSet().length, allCards.length);
    });
  });

  group('BettingUsecase', () {
    test('蒙牌跟注扣除底注×1', () {
      final state = _makeState();
      final result = BettingUsecase().execute(state, BettingAction.call);
      expect(result.players[0].chips, 990); // 1000 - 10
      expect(result.pot, 40); // 30 + 10
    });

    test('看牌后跟注扣除底注×2', () {
      final state = _makeState();
      final stateAfterPeek = PeekCardUsecase().execute(state);
      final result = BettingUsecase().execute(stateAfterPeek, BettingAction.call);
      expect(result.players[0].chips, 980); // 1000 - 20
    });

    test('加注后底注翻倍', () {
      final state = _makeState();
      final result = BettingUsecase().execute(state, BettingAction.raise);
      expect(result.currentBet, 20);
    });

    test('弃牌后玩家isFolded=true', () {
      final state = _makeState();
      final result = BettingUsecase().execute(state, BettingAction.fold);
      expect(result.players[0].isFolded, true);
    });
  });

  group('PeekCardUsecase', () {
    test('看牌后hasPeeked=true', () {
      final state = _makeState();
      final result = PeekCardUsecase().execute(state);
      expect(result.players[0].hasPeeked, true);
    });

    test('重复看牌无副作用', () {
      final state = _makeState();
      final after1 = PeekCardUsecase().execute(state);
      final after2 = PeekCardUsecase().execute(after1);
      expect(after2.players[0].hasPeeked, true);
    });
  });

  group('ShowdownUsecase', () {
    test('牌大的玩家胜，牌小的淘汰', () {
      final players = [
        ZhjPlayer(
          id: 'p1',
          name: '玩家',
          isAi: false,
          chips: 990,
          cards: [
            ZhjCard(rank: 14, suit: Suit.spade),
            ZhjCard(rank: 14, suit: Suit.heart),
            ZhjCard(rank: 14, suit: Suit.diamond),
          ],
        ),
        ZhjPlayer(
          id: 'ai1',
          name: 'AI1',
          isAi: true,
          chips: 990,
          cards: [
            ZhjCard(rank: 3, suit: Suit.spade),
            ZhjCard(rank: 4, suit: Suit.heart),
            ZhjCard(rank: 5, suit: Suit.diamond),
          ],
        ),
      ];
      final state = ZhjGameState(
        phase: ZhjGamePhase.betting,
        players: players,
        pot: 20,
        currentBet: 10,
        currentPlayerIndex: 0,
      );
      final result = ShowdownUsecase().execute(state, 0, 1);
      expect(result.players[0].isFolded, false); // p1 胜
      expect(result.players[1].isFolded, true);  // ai1 淘汰
    });

    test('平局时发起者淘汰', () {
      final sameCards = [
        ZhjCard(rank: 7, suit: Suit.spade),
        ZhjCard(rank: 7, suit: Suit.heart),
        ZhjCard(rank: 3, suit: Suit.diamond),
      ];
      final players = [
        ZhjPlayer(id: 'p1', name: '玩家', isAi: false, chips: 990, cards: List.of(sameCards)),
        ZhjPlayer(id: 'ai1', name: 'AI1', isAi: true, chips: 990, cards: List.of(sameCards)),
      ];
      final state = ZhjGameState(
        phase: ZhjGamePhase.betting,
        players: players,
        pot: 20,
        currentBet: 10,
        currentPlayerIndex: 0,
      );
      final result = ShowdownUsecase().execute(state, 0, 1);
      expect(result.players[0].isFolded, true); // 发起者淘汰
    });
  });
}
