import 'dart:math';

import 'mcts_game_state.dart';
import 'mcts_node.dart';

/// UCT（Upper Confidence bound for Trees）MCTS 搜索引擎。
///
/// 支持两种终止条件（时间或迭代次数），可插拔 rollout 策略。
class MctsEngine<S extends MctsGameState<A>, A> {
  /// 每次 search 的玩家 ID（视角）。
  final String currentPlayerId;

  /// 搜索时间预算（与 [iterations] 二选一）。
  final Duration? timeLimit;

  /// 搜索迭代次数（与 [timeLimit] 二选一）。
  final int? iterations;

  /// 自定义 rollout 策略，默认随机。
  final RolloutPolicy<A>? rolloutPolicy;

  final Random _random;

  MctsEngine({
    required this.currentPlayerId,
    this.timeLimit,
    this.iterations,
    this.rolloutPolicy,
    Random? random,
  }) : assert(
          timeLimit != null || iterations != null,
          'Must specify either timeLimit or iterations',
        ),
       _random = random ?? Random();

  /// 从 [state] 出发执行搜索，返回最佳行动。
  ///
  /// 若 [state] 已终局，则抛出 [StateError]。
  A search(S state) {
    if (state.isTerminal) {
      throw StateError('Cannot search from a terminal state');
    }

    final root = MctsNode<A>(untriedActions: state.getLegalActions());
    final deadline = timeLimit != null
        ? DateTime.now().add(timeLimit!)
        : null;
    int iter = 0;
    final maxIter = iterations ?? 1 << 30;

    while (iter < maxIter && (deadline == null || DateTime.now().isBefore(deadline))) {
      _runIteration(root, state);
      iter++;
    }

    // 返回访问次数最多的行动
    final best = root.children.reduce(
      (a, b) => a.visits > b.visits ? a : b,
    );
    return best.action as A;
  }

  void _runIteration(MctsNode<A> root, S rootState) {
    // 1. Selection + 2. Expansion
    var (node, state) = _selectAndExpand(root, rootState);

    // 3. Simulation
    final value = _simulate(state);

    // 4. Backpropagation
    // 奇数深度 = player0（我方）节点，存 player0 胜率 v；
    // 偶数深度 = player1（对手）节点，存 player1 胜率 1-v。
    final initValue = node.depth.isOdd ? value : 1.0 - value;
    _backpropagate(node, initValue);
  }

  /// 选择阶段：沿 UCB1 最高子节点递归，直到发现未扩展节点或终局。
  /// 同时展开一个未尝试行动（若有）。
  (MctsNode<A>, MctsGameState<A>) _selectAndExpand(
      MctsNode<A> root, S rootState) {
    var node = root;
    MctsGameState<A> state = rootState;

    // Selection：下降到有未尝试行动的节点或终局
    while (node.untriedActions.isEmpty && node.children.isNotEmpty && !state.isTerminal) {
      node = node.bestChild();
      state = state.applyAction(node.action as A);
    }

    // Expansion：随机选取一个未尝试行动并扩展
    if (node.untriedActions.isNotEmpty && !state.isTerminal) {
      final idx = _random.nextInt(node.untriedActions.length);
      final action = node.untriedActions.removeAt(idx);
      final newState = state.applyAction(action);
      final child = MctsNode<A>(
        action: action,
        parent: node,
        depth: node.depth + 1,
        untriedActions: newState.getLegalActions(),
      );
      node.children.add(child);
      return (child, newState);
    }

    return (node, state);
  }

  /// 模拟阶段：使用 rollout 策略随机走棋至终局，返回评估值。
  double _simulate(MctsGameState<A> state) {
    var s = state;
    while (!s.isTerminal) {
      final actions = s.getLegalActions();
      if (actions.isEmpty) break;
      final action = rolloutPolicy != null
          ? rolloutPolicy!(actions)
          : actions[_random.nextInt(actions.length)];
      s = s.applyAction(action);
    }
    return s.evaluate(currentPlayerId);
  }

  /// 回传阶段：从叶节点到根，交替取反更新每个节点。
  void _backpropagate(MctsNode<A> node, double value) {
    var current = node;
    var v = value;
    while (true) {
      current.update(v);
      if (current.parent == null) break;
      current = current.parent!;
      v = 1.0 - v; // 对手视角取反
    }
  }
}
