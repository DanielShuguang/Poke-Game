import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/core/ai/mcts/pimc_engine.dart';
import 'package:poke_game/domain/doudizhu/ai/doudizhu_mcts_state.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';

// ─── 测试用牌工厂 ─────────────────────────────────────────────────────────────

Card c(int rank, [Suit suit = Suit.spade]) => Card(suit: suit, rank: rank);
Card smallJoker() => Card(suit: Suit.spade, rank: 16); // isSmallJoker
Card bigJoker() => Card(suit: Suit.spade, rank: 17);   // isBigJoker

DoudizhuMctsState _makeState({
  required List<List<Card>> playerCards,
  required List<PlayerRole?> roles,
  required int currentIdx,
  required int landlordIdx,
  List<Card>? lastPlayed,
  int? lastPlayerIdx,
}) {
  final ids = List.generate(playerCards.length, (i) => 'p$i');
  return DoudizhuMctsState.fromPlayers(
    playerIds: ids,
    playerCards: playerCards,
    playerRoles: roles,
    currentPlayerIndex: currentIdx,
    landlordIndex: landlordIdx,
    lastPlayedCards: lastPlayed,
    lastPlayerIndex: lastPlayerIdx,
  );
}

void main() {
  // ─── 4.1 getLegalActions ────────────────────────────────────────────────────

  group('DoudizhuMctsState.getLegalActions', () {
    test('终局时返回空列表', () {
      final state = _makeState(
        playerCards: [[], [c(3), c(4)], [c(5)]],
        roles: [PlayerRole.landlord, PlayerRole.peasant, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 0,
      );
      expect(state.isTerminal, isTrue);
      expect(state.getLegalActions(), isEmpty);
    });

    test('首出时包含所有合法牌型（无 pass）', () {
      final hand = [c(3), c(3, Suit.heart), c(4), c(5), c(6), c(7)];
      final state = _makeState(
        playerCards: [hand, [c(8), c(9)], [c(10), c(11)]],
        roles: [PlayerRole.landlord, PlayerRole.peasant, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 0,
      );
      final actions = state.getLegalActions();
      expect(actions, isNotEmpty);
      expect(actions.any((a) => a.isPass), isFalse);
    });

    test('跟牌时包含能压制的组合和 pass', () {
      final hand = [c(5), c(6), c(7), c(8)];
      final state = _makeState(
        playerCards: [hand, [c(3)], [c(4)]],
        roles: [PlayerRole.peasant, PlayerRole.landlord, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 1,
        lastPlayed: [c(4, Suit.heart)],
        lastPlayerIdx: 1,
      );
      final actions = state.getLegalActions();
      // 应有 pass
      expect(actions.any((a) => a.isPass), isTrue);
      // 应有比 4 大的单张
      final plays = actions.where((a) => !a.isPass).toList();
      expect(plays, isNotEmpty);
      for (final a in plays) {
        expect(a.cards, isNotEmpty);
      }
    });

    test('无法压制时只有 pass', () {
      final hand = [c(3), c(3, Suit.heart)];
      final state = _makeState(
        playerCards: [hand, [c(5)], [c(6)]],
        roles: [PlayerRole.peasant, PlayerRole.landlord, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 1,
        lastPlayed: [c(14)], // A，手牌全是 3，打不过
        lastPlayerIdx: 1,
      );
      final actions = state.getLegalActions();
      expect(actions.length, 1);
      expect(actions.first.isPass, isTrue);
    });
  });

  // ─── 4.1 applyAction 不可变性 ────────────────────────────────────────────────

  group('DoudizhuMctsState.applyAction', () {
    test('出牌后原状态不变，新状态手牌减少', () {
      final hand = [c(3), c(4), c(5)];
      final state = _makeState(
        playerCards: [hand, [c(6), c(7)], [c(8)]],
        roles: [PlayerRole.landlord, PlayerRole.peasant, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 0,
      );
      final actions = state.getLegalActions();
      final playAction = actions.firstWhere((a) => !a.isPass);
      final next = state.applyAction(playAction);
      // 原状态手牌不变
      expect(state.cardsForPlayer(0).length, equals(3));
      // 新状态手牌减少
      expect((next as DoudizhuMctsState).cardsForPlayer(0).length,
          lessThan(3));
    });

    test('pass 后轮次前进，手牌不变', () {
      final state = _makeState(
        playerCards: [[c(3)], [c(14)], [c(5)]],
        roles: [PlayerRole.peasant, PlayerRole.landlord, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 1,
        lastPlayed: [c(14, Suit.heart)],
        lastPlayerIdx: 1,
      );
      final next =
          state.applyAction(const DoudizhuAction.pass()) as DoudizhuMctsState;
      expect(next.currentPlayerIndex, isNot(equals(0)));
      expect(next.cardsForPlayer(0).length, equals(1));
    });

    test('isTerminal 当任意玩家手牌清空时为 true', () {
      final state = _makeState(
        playerCards: [[c(3)], [c(5), c(6)], [c(7)]],
        roles: [PlayerRole.landlord, PlayerRole.peasant, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 0,
      );
      final actions = state.getLegalActions();
      final play = actions.firstWhere((a) => !a.isPass && a.cards.length == 1);
      final next = state.applyAction(play) as DoudizhuMctsState;
      expect(next.isTerminal, isTrue);
    });
  });

  // ─── 4.2 determinize ─────────────────────────────────────────────────────────

  group('DoudizhuMctsState.determinize', () {
    test('当前玩家手牌不变', () {
      final myCards = [c(3), c(5), c(7), c(9), c(11)];
      final state = _makeState(
        playerCards: [myCards, [c(4), c(6), c(8)], [c(10), c(12), c(13)]],
        roles: [PlayerRole.landlord, PlayerRole.peasant, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 0,
      );
      final det = state.determinize('p0') as DoudizhuMctsState;
      expect(det.cardsForPlayer(0), equals(myCards));
    });

    test('其他玩家总张数与原来相同', () {
      final state = _makeState(
        playerCards: [
          [c(3), c(4), c(5)],
          [c(6), c(7), c(8), c(9)],
          [c(10), c(11)],
        ],
        roles: [PlayerRole.landlord, PlayerRole.peasant, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 0,
      );
      final det = state.determinize('p0') as DoudizhuMctsState;
      expect(det.cardsForPlayer(1).length, equals(4));
      expect(det.cardsForPlayer(2).length, equals(2));
    });

    test('多次 determinize 结果不全相同（随机性）', () {
      final state = _makeState(
        playerCards: [
          [c(3), c(4), c(5)],
          [c(6), c(7), c(8), c(9)],
          [c(10), c(11), c(12), c(13)],
        ],
        roles: [PlayerRole.landlord, PlayerRole.peasant, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 0,
      );
      final results = List.generate(
          10, (_) => (state.determinize('p0') as DoudizhuMctsState).cardsForPlayer(1));
      // 10次中至少有2次不同（概率极高）
      final unique = results.map((cs) => cs.map((c) => c.rank).join()).toSet();
      expect(unique.length, greaterThan(1));
    });
  });

  // ─── 4.3 集成测试：困难 AI ≤200ms ──────────────────────────────────────────

  group('DoudizhuMctsState 集成测试', () {
    test('PIMC 搜索 ≤ 200ms 返回合法行动', () async {
      final myCards = [c(3), c(5), c(7), c(9), c(11), c(13)];
      final state = _makeState(
        playerCards: [
          myCards,
          [c(4), c(6), c(8), c(10), c(12)],
          [c(14), c(15), c(3, Suit.heart), c(4, Suit.heart), c(5, Suit.heart)],
        ],
        roles: [PlayerRole.landlord, PlayerRole.peasant, PlayerRole.peasant],
        currentIdx: 0,
        landlordIdx: 0,
      );

      final engine = PimcEngine<DoudizhuMctsState, DoudizhuAction>(
        samples: 10,
        timeLimit: const Duration(milliseconds: 150),
      );

      final start = DateTime.now();
      final action = engine.search(state, 'p0');
      final elapsed = DateTime.now().difference(start);

      expect(elapsed.inMilliseconds, lessThan(200));
      final legal = state.getLegalActions();
      expect(legal.any((a) => a == action), isTrue);
    });
  });
}
