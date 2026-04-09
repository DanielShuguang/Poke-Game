import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/core/ai/mcts/mcts_game_state.dart';
import 'package:poke_game/core/ai/mcts/pimc_engine.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 可观测的 Nim 游戏（用于统计 determinize 调用次数）
// ──────────────────────────────────────────────────────────────────────────────

class ObservableNimState extends MctsGameState<int> {
  final int stones;
  final int currentPlayer;
  final void Function()? onDeterminize;

  ObservableNimState(this.stones, this.currentPlayer, {this.onDeterminize});

  @override
  List<int> getLegalActions() {
    if (isTerminal) return [];
    return [for (int i = 1; i <= 3 && i <= stones; i++) i];
  }

  @override
  MctsGameState<int> applyAction(int action) =>
      ObservableNimState(stones - action, 1 - currentPlayer);

  @override
  bool get isTerminal => stones <= 0;

  @override
  double evaluate(String playerId) {
    final lastPlayer = 1 - currentPlayer;
    final lastPlayerId = lastPlayer == 0 ? 'p0' : 'p1';
    return playerId == lastPlayerId ? 0.0 : 1.0;
  }

  @override
  MctsGameState<int> determinize(String playerId) {
    onDeterminize?.call();
    return ObservableNimState(stones, currentPlayer);
  }
}

void main() {
  group('PimcEngine', () {
    test('determinize 被调用 samples 次', () {
      int callCount = 0;
      final state = ObservableNimState(7, 0, onDeterminize: () => callCount++);

      final engine = PimcEngine<ObservableNimState, int>(
        samples: 10,
        timeLimit: const Duration(milliseconds: 50),
      );
      engine.search(state, 'p0');

      expect(callCount, equals(10));
    });

    test('返回的行动是合法行动', () {
      final state = ObservableNimState(7, 0);
      final engine = PimcEngine<ObservableNimState, int>(
        samples: 5,
        timeLimit: const Duration(milliseconds: 50),
      );
      final action = engine.search(state, 'p0');
      expect([1, 2, 3], contains(action));
    });

    test('总耗时不超过 200ms', () {
      final state = ObservableNimState(9, 0);
      final engine = PimcEngine<ObservableNimState, int>(
        samples: 20,
        timeLimit: const Duration(milliseconds: 150),
      );
      final start = DateTime.now();
      engine.search(state, 'p0');
      final elapsed = DateTime.now().difference(start);
      expect(elapsed.inMilliseconds, lessThan(200));
    });

    test('默认 samples=20', () {
      final engine = PimcEngine<ObservableNimState, int>();
      expect(engine.samples, equals(20));
    });

    test('默认 timeLimit=150ms', () {
      final engine = PimcEngine<ObservableNimState, int>();
      expect(engine.timeLimit, equals(const Duration(milliseconds: 150)));
    });

    test('平局时随机选取（多次执行有一致结果）', () {
      // 简单验证：调用多次都返回合法行动
      final state = ObservableNimState(3, 0);
      final engine = PimcEngine<ObservableNimState, int>(
        samples: 4,
        timeLimit: const Duration(milliseconds: 30),
      );
      for (int i = 0; i < 5; i++) {
        final action = engine.search(state, 'p0');
        expect([1, 2, 3], contains(action));
      }
    });
  });
}
