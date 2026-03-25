import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/zhajinhua/ai/zhj_ai_strategy.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_card.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';
import 'package:poke_game/domain/zhajinhua/usecases/betting_usecase.dart';

ZhjGameState _state(List<ZhjPlayer> players) => ZhjGameState(
      phase: ZhjGamePhase.betting,
      players: players,
      pot: 30,
      currentBet: 10,
      currentPlayerIndex: 0,
    );

ZhjPlayer _aiWithCards(
  List<ZhjCard> cards, {
  double aggression = 0.5,
  bool hasPeeked = true,
}) =>
    ZhjPlayer(
      id: 'ai1',
      name: 'AI1',
      isAi: true,
      chips: 990,
      cards: cards,
      aggression: aggression,
      hasPeeked: hasPeeked,
    );

void main() {
  group('ZhjAiStrategy - 蒙牌决策', () {
    test('激进度1.0时更倾向蒙牌（shouldPeekFirst=false更多）', () {
      // shouldPeekFirst=true 表示 AI 决定看牌，false 表示蒙牌
      int blindCount = 0; // 蒙牌次数（shouldPeekFirst=false）
      for (int i = 0; i < 100; i++) {
        final strategy = ZhjAiStrategy(random: Random(i));
        final player = ZhjPlayer(id: 'ai', name: 'AI', isAi: true, chips: 990, aggression: 1.0);
        final decision = strategy.decideAction(_state([player]), player);
        if (!decision.shouldPeekFirst) blindCount++;
      }
      // 激进度1.0：蒙牌概率 = 0.8，所以 shouldPeekFirst=false 约80次
      expect(blindCount, greaterThan(60));
    });

    test('激进度0.0时更倾向看牌（shouldPeekFirst=true更多）', () {
      int peekCount = 0; // 看牌次数（shouldPeekFirst=true）
      for (int i = 0; i < 100; i++) {
        final strategy = ZhjAiStrategy(random: Random(i));
        final player = ZhjPlayer(id: 'ai', name: 'AI', isAi: true, chips: 990, aggression: 0.0);
        final decision = strategy.decideAction(_state([player]), player);
        if (decision.shouldPeekFirst) peekCount++;
      }
      // 激进度0.0：蒙牌概率=0.2，看牌概率=0.8，shouldPeekFirst=true 约80次
      expect(peekCount, greaterThan(60));
    });

    test('已看牌时不再触发shouldPeekFirst', () {
      final strategy = ZhjAiStrategy();
      final player = ZhjPlayer(
        id: 'ai', name: 'AI', isAi: true, chips: 990, hasPeeked: true,
        cards: [ZhjCard(rank: 14, suit: Suit.spade), ZhjCard(rank: 14, suit: Suit.heart), ZhjCard(rank: 14, suit: Suit.diamond)],
      );
      final decision = strategy.decideAction(_state([player]), player);
      expect(decision.shouldPeekFirst, false);
    });
  });

  group('ZhjAiStrategy - 下注决策', () {
    test('豹子：倾向加注（多次采样至少60%加注）', () {
      int raiseCount = 0;
      for (int i = 0; i < 100; i++) {
        final strategy = ZhjAiStrategy(random: Random(i));
        final player = _aiWithCards([
          ZhjCard(rank: 14, suit: Suit.spade),
          ZhjCard(rank: 14, suit: Suit.heart),
          ZhjCard(rank: 14, suit: Suit.diamond),
        ], aggression: 0.8);
        final decision = strategy.decideAction(_state([player]), player);
        if (decision.action == BettingAction.raise) raiseCount++;
      }
      expect(raiseCount, greaterThan(60));
    });

    test('散牌低激进度：多数情况弃牌', () {
      int foldCount = 0;
      for (int i = 0; i < 100; i++) {
        final strategy = ZhjAiStrategy(random: Random(i));
        final player = _aiWithCards([
          ZhjCard(rank: 3, suit: Suit.spade),
          ZhjCard(rank: 7, suit: Suit.heart),
          ZhjCard(rank: 10, suit: Suit.diamond),
        ], aggression: 0.0);
        final decision = strategy.decideAction(_state([player]), player);
        if (decision.action == BettingAction.fold) foldCount++;
      }
      expect(foldCount, greaterThan(50));
    });

    test('筹码不足时弱牌弃牌', () {
      final strategy = ZhjAiStrategy(random: Random(42));
      final player = ZhjPlayer(
        id: 'ai', name: 'AI', isAi: true, chips: 5, hasPeeked: true, aggression: 0.0,
        cards: [ZhjCard(rank: 3, suit: Suit.spade), ZhjCard(rank: 7, suit: Suit.heart), ZhjCard(rank: 10, suit: Suit.diamond)],
      );
      final state = ZhjGameState(phase: ZhjGamePhase.betting, players: [player], pot: 30, currentBet: 10, currentPlayerIndex: 0);
      final decision = strategy.decideAction(state, player);
      expect(decision.action, BettingAction.fold);
    });
  });
}
