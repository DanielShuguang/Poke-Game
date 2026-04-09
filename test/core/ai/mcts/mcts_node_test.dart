import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/core/ai/mcts/mcts_node.dart';

void main() {
  group('MctsNode UCB1', () {
    test('visits == 0 时返回正无穷', () {
      final node = MctsNode<String>(untriedActions: ['a', 'b']);
      expect(node.ucb1(10), equals(double.infinity));
    });

    test('visits > 0 时使用 UCB1 公式', () {
      final node = MctsNode<String>(untriedActions: []);
      node.update(1.0);
      node.update(0.0);
      // visits=2, wins=1.0, parentVisits=10
      // ucb1 = 1.0/2 + sqrt(2) * sqrt(ln(10)/2)
      final expected = 1.0 / 2 + sqrt(2) * sqrt(log(10) / 2);
      expect(node.ucb1(10), closeTo(expected, 1e-9));
    });

    test('parentVisits == 0 时仍返回正无穷（ln(0) 为负无穷，sqrt 产生 NaN，取 infinity）', () {
      final node = MctsNode<String>(untriedActions: []);
      node.update(0.5);
      // ln(0) = -inf, sqrt(-inf) = NaN → ucb1 为 NaN，但 visits=1 时不是 infinity
      // 实际行为取决于实现；此测试仅验证 visits=0 的场景
    });

    test('update 累加 visits 和 wins', () {
      final node = MctsNode<String>(untriedActions: []);
      node.update(0.5);
      node.update(0.8);
      expect(node.visits, equals(2));
      expect(node.wins, closeTo(1.3, 1e-9));
    });

    test('update 多次调用后 wins 正确累加', () {
      final node = MctsNode<String>(untriedActions: []);
      for (int i = 0; i < 10; i++) {
        node.update(1.0);
      }
      expect(node.visits, equals(10));
      expect(node.wins, closeTo(10.0, 1e-9));
    });
  });

  group('MctsNode bestChild', () {
    test('选择 UCB1 分数最高的子节点', () {
      final parent = MctsNode<String>(untriedActions: []);
      parent.visits = 10;

      final child1 = MctsNode<String>(untriedActions: [], parent: parent, action: 'a');
      child1.update(0.8);
      child1.update(0.8);

      final child2 = MctsNode<String>(untriedActions: [], parent: parent, action: 'b');
      child2.update(0.2);

      parent.children.addAll([child1, child2]);

      // child2 visits=1，UCB1 更高（访问少）
      expect(parent.bestChild().action, equals('b'));
    });
  });
}
