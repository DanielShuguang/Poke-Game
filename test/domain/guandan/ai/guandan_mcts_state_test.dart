import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/core/ai/mcts/pimc_engine.dart';
import 'package:poke_game/domain/guandan/ai/guandan_mcts_state.dart';
import 'package:poke_game/domain/guandan/entities/guandan_card.dart';
import 'package:poke_game/domain/guandan/entities/guandan_hand.dart';
import 'package:poke_game/domain/guandan/entities/guandan_hand_type.dart';

// ─── 测试用牌工厂 ─────────────────────────────────────────────────────────────

GuandanCard cH(int rank) => GuandanCard(suit: Suit.heart, rank: rank);
GuandanCard cS(int rank) => GuandanCard(suit: Suit.spade, rank: rank);

const bigJoker = GuandanCard.bigJoker();
const smallJoker = GuandanCard.smallJoker();

/// 构造一个最简单的单张 GuandanHand，用于测试 lastPlayedHand
GuandanHand singleHand(int rank) =>
    GuandanHand(cards: [cH(rank)], type: HandType.single, rank: rank);

// ─── 状态工厂 ─────────────────────────────────────────────────────────────────

GuandanMctsState _makeState({
  required List<List<GuandanCard>> playerCards,
  required int currentIdx,
  GuandanHand? lastPlayedHand,
  int? lastPlayerIndex,
  int team0Level = 2,
  int team1Level = 2,
}) {
  return GuandanMctsState.fromData(
    playerIds: ['p0', 'p1', 'p2', 'p3'],
    teamIds: [0, 1, 0, 1],
    playerCards: playerCards,
    currentPlayerIndex: currentIdx,
    team0Level: team0Level,
    team1Level: team1Level,
    lastPlayedHand: lastPlayedHand,
    lastPlayerIndex: lastPlayerIndex,
  );
}

void main() {
  // ─── 6.1 getLegalActions ────────────────────────────────────────────────────

  group('GuandanMctsState.getLegalActions', () {
    test('终局时返回空列表', () {
      // 队伍0 (p0, p2) 均已清空手牌 → isTerminal
      final state = _makeState(
        playerCards: [[], [cH(5)], [], [cH(7)]],
        currentIdx: 0,
      );
      expect(state.isTerminal, isTrue);
      expect(state.getLegalActions(), isEmpty);
    });

    test('首出时包含合法牌型且无 pass', () {
      final state = _makeState(
        playerCards: [
          [cH(3), cS(3), cH(4), cH(5)],
          [cH(6)],
          [cH(7)],
          [cH(8)],
        ],
        currentIdx: 0,
      );
      final actions = state.getLegalActions();
      expect(actions, isNotEmpty);
      expect(actions.any((a) => a.isPass), isFalse);
    });

    test('已完成的玩家返回单个 pass', () {
      final state = _makeState(
        playerCards: [[], [cH(6)], [cH(7)], [cH(8)]],
        currentIdx: 0,
      );
      final actions = state.getLegalActions();
      expect(actions.length, 1);
      expect(actions.first.isPass, isTrue);
    });

    test('跟牌时包含能压制的组合和 pass', () {
      // lastPlayedHand 是 5 单张，当前玩家有 6/7/8/9
      final state = _makeState(
        playerCards: [
          [cH(6), cH(7), cH(8), cH(9)],
          [cH(3)],
          [cH(4)],
          [cH(5)],
        ],
        currentIdx: 0,
        lastPlayedHand: singleHand(5),
        lastPlayerIndex: 1,
      );
      final actions = state.getLegalActions();
      expect(actions.any((a) => a.isPass), isTrue);
      expect(actions.any((a) => !a.isPass), isTrue);
    });

    test('无法压制时只有 pass', () {
      // lastPlayedHand 是 A(14) 单张，手牌全是 3
      final state = _makeState(
        playerCards: [
          [cH(3), cS(3)],
          [cH(6)],
          [cH(7)],
          [cH(8)],
        ],
        currentIdx: 0,
        lastPlayedHand: singleHand(14),
        lastPlayerIndex: 1,
      );
      final actions = state.getLegalActions();
      expect(actions.length, 1);
      expect(actions.first.isPass, isTrue);
    });
  });

  // ─── 6.1 applyAction 不可变性 ────────────────────────────────────────────────

  group('GuandanMctsState.applyAction', () {
    test('出牌后原状态不变，新状态手牌减少', () {
      final state = _makeState(
        playerCards: [
          [cH(3), cH(4), cH(5)],
          [cH(6)],
          [cH(7)],
          [cH(8)],
        ],
        currentIdx: 0,
      );
      final actions = state.getLegalActions();
      final playAction = actions.firstWhere((a) => !a.isPass);
      final next = state.applyAction(playAction) as GuandanMctsState;
      expect(state.cardsForPlayer(0).length, equals(3));
      expect(next.cardsForPlayer(0).length, lessThan(3));
    });

    test('pass 后轮次前进，手牌不变', () {
      final state = _makeState(
        playerCards: [
          [cH(3)],
          [cH(14)],
          [cH(5)],
          [cH(6)],
        ],
        currentIdx: 0,
        lastPlayedHand: singleHand(14),
        lastPlayerIndex: 1,
      );
      final next =
          state.applyAction(const GuandanMctsAction.pass()) as GuandanMctsState;
      expect(next.currentPlayerIndex, isNot(equals(0)));
      expect(next.cardsForPlayer(0).length, equals(1));
    });

    test('isTerminal：队伍所有玩家手牌清空时为 true', () {
      // p2 已清空(teamId=0)，p0 出完最后一张 → 队伍0全员完成
      final state = _makeState(
        playerCards: [
          [cH(9)],
          [cH(6)],
          [],
          [cH(8)],
        ],
        currentIdx: 0,
      );
      final actions = state.getLegalActions();
      final singlePlay =
          actions.firstWhere((a) => !a.isPass && a.cards.length == 1);
      final next = state.applyAction(singlePlay) as GuandanMctsState;
      expect(next.isTerminal, isTrue);
    });
  });

  // ─── 6.2 determinize ─────────────────────────────────────────────────────────

  group('GuandanMctsState.determinize', () {
    test('当前玩家手牌不变', () {
      final myCards = [cH(3), cH(5), cH(7), cH(9), cH(11)];
      final state = _makeState(
        playerCards: [
          myCards,
          [cH(4), cH(6), cH(8)],
          [cS(3), cS(5), cS(7)],
          [cH(10), cH(12), cH(13)],
        ],
        currentIdx: 0,
      );
      final det = state.determinize('p0') as GuandanMctsState;
      expect(det.cardsForPlayer(0), equals(myCards));
    });

    test('队友手牌不变', () {
      final teammateCards = [cS(3), cS(5), cS(7)];
      final state = _makeState(
        playerCards: [
          [cH(3), cH(5), cH(7), cH(9), cH(11)],
          [cH(4), cH(6), cH(8)],
          teammateCards, // p2, teamId=0，是 p0 的队友
          [cH(10), cH(12), cH(13)],
        ],
        currentIdx: 0,
      );
      final det = state.determinize('p0') as GuandanMctsState;
      expect(det.cardsForPlayer(2), equals(teammateCards));
    });

    test('对手各玩家张数与原来相同', () {
      final state = _makeState(
        playerCards: [
          [cH(3), cH(4), cH(5)],
          [cH(6), cH(7), cH(8), cH(9)], // p1 4张
          [cS(3), cS(4), cS(5)],
          [cH(10), cH(11)], // p3 2张
        ],
        currentIdx: 0,
      );
      final det = state.determinize('p0') as GuandanMctsState;
      expect(det.cardsForPlayer(1).length, equals(4));
      expect(det.cardsForPlayer(3).length, equals(2));
    });

    test('多次 determinize 对手结果不全相同（随机性）', () {
      final state = _makeState(
        playerCards: [
          [cH(3), cH(4)],
          [cH(5), cH(6), cH(7), cH(8)],
          [cS(3), cS(4)],
          [cH(9), cH(10), cH(11), cH(12)],
        ],
        currentIdx: 0,
      );
      final results = List.generate(
        10,
        (_) => (state.determinize('p0') as GuandanMctsState)
            .cardsForPlayer(1)
            .map((c) => '${c.suit}${c.rank}')
            .join(),
      );
      expect(results.toSet().length, greaterThan(1));
    });
  });

  // ─── 6.3 集成测试：困难 AI ≤200ms ───────────────────────────────────────────

  group('GuandanMctsState 集成测试', () {
    test('PIMC 搜索 ≤ 200ms 返回合法行动', () {
      final state = _makeState(
        playerCards: [
          [cH(3), cH(5), cH(7), cH(9), cH(11), cH(13)],
          [cS(4), cS(6), cS(8), cS(10), cS(12)],
          [cH(4), cH(6), cH(8), cH(10), cH(12)],
          [cS(3), cS(5), cS(7), cS(9), cS(11)],
        ],
        currentIdx: 0,
      );

      final engine = PimcEngine<GuandanMctsState, GuandanMctsAction>(
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
