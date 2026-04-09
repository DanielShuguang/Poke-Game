import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/core/ai/mcts/mcts_engine.dart';
import 'package:poke_game/core/ai/mcts/mcts_game_state.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 简单 Nim 游戏实现（用于测试）
//
// 规则：有 N 颗石子，双方轮流取 1~3 颗，取走最后一颗者输。
// currentPlayer: 0 或 1
// ──────────────────────────────────────────────────────────────────────────────

class NimState extends MctsGameState<int> {
  final int stones;
  final int currentPlayer; // 0 or 1

  NimState(this.stones, this.currentPlayer);

  static const String player0 = 'player0';
  static const String player1 = 'player1';

  @override
  List<int> getLegalActions() {
    if (isTerminal) return [];
    return [for (int i = 1; i <= 3 && i <= stones; i++) i];
  }

  @override
  MctsGameState<int> applyAction(int action) {
    return NimState(stones - action, 1 - currentPlayer);
  }

  @override
  bool get isTerminal => stones <= 0;

  @override
  double evaluate(String playerId) {
    // 取走最后一颗者输：isTerminal 时当前玩家刚取完（轮到对手了）
    // currentPlayer 是下一个要动的玩家，上一个动的玩家取了最后一颗 → 上一个动的玩家输
    // lastPlayer = 1 - currentPlayer
    final lastPlayer = 1 - currentPlayer;
    final lastPlayerId = lastPlayer == 0 ? player0 : player1;

    if (playerId == lastPlayerId) {
      return 0.0; // 取走最后一颗者输
    }
    return 1.0; // 对手取走最后一颗，我赢
  }

  @override
  MctsGameState<int> determinize(String playerId) => this; // Nim 无隐信息
}

void main() {
  group('MctsEngine Nim game', () {
    test('终局状态抛出 StateError', () {
      final state = NimState(0, 0);
      final engine = MctsEngine<NimState, int>(
        currentPlayerId: NimState.player0,
        iterations: 100,
      );
      expect(() => engine.search(state), throwsStateError);
    });

    test('iterations 模式正好执行指定次数后返回行动', () {
      final state = NimState(5, 0);
      final engine = MctsEngine<NimState, int>(
        currentPlayerId: NimState.player0,
        iterations: 200,
      );
      final action = engine.search(state);
      expect(NimState(5, 0).getLegalActions(), contains(action));
    });

    test('timeLimit 模式在时间预算内返回合法行动', () {
      final state = NimState(7, 0);
      final engine = MctsEngine<NimState, int>(
        currentPlayerId: NimState.player0,
        timeLimit: const Duration(milliseconds: 50),
      );
      final action = engine.search(state);
      expect([1, 2, 3], contains(action));
    });

    // stones=4: 取 3 颗剩 1 给对手 → 对手必须取走最后一颗 → 对手输
    test('stones=4 时最优行动为取 3', () {
      final state = NimState(4, 0);
      final engine = MctsEngine<NimState, int>(
        currentPlayerId: NimState.player0,
        iterations: 2000,
      );
      final action = engine.search(state);
      expect(action, equals(3));
    });

    // stones=3: 取 3 颗直接赢（对手拿最后 0 颗）—— 但 stones=3 时对手无牌可取
    // 实际上 stones=3，我取 3 → stones=0 对手面对终局，下一个 currentPlayer=1
    // evaluate(player0) = 1.0（对手取最后一颗 → 不对，是我取的最后一颗）
    // 取走最后一颗者输 → stones=3 取 3 会输；取 2 剩 1 对手取 1 对手输 → 我赢
    test('stones=3 时最优行动为取 2（让对手取最后一颗）', () {
      final state = NimState(3, 0);
      final engine = MctsEngine<NimState, int>(
        currentPlayerId: NimState.player0,
        iterations: 2000,
      );
      final action = engine.search(state);
      expect(action, equals(2));
    });
  });
}
