import 'dart:math';

/// MCTS 树节点，封装 UCB1 选择逻辑与统计数据。
class MctsNode<A> {
  /// 到达此节点所执行的行动（根节点为 null）。
  final A? action;

  /// 父节点（根节点为 null）。
  final MctsNode<A>? parent;

  /// 子节点列表。
  final List<MctsNode<A>> children = [];

  /// 尚未被扩展的合法行动列表。
  final List<A> untriedActions;

  /// 访问次数。
  int visits = 0;

  /// 累计收益（wins 值之和）。
  double wins = 0.0;

  /// UCB1 探索常数，默认 sqrt(2)。
  final double explorationConstant;

  /// 节点在搜索树中的深度（根节点为 0）。
  final int depth;

  MctsNode({
    required this.untriedActions,
    this.action,
    this.parent,
    this.depth = 0,
    this.explorationConstant = sqrt2,
  });

  /// 计算 UCB1 分数。
  /// - 未访问（visits == 0）时返回 [double.infinity]，保证优先探索。
  /// - 否则：wins/visits + c * sqrt(ln(parentVisits) / visits)
  double ucb1(int parentVisits) {
    if (visits == 0) return double.infinity;
    return wins / visits +
        explorationConstant * sqrt(log(parentVisits) / visits);
  }

  /// 反向传播更新：visits +1，wins += value。
  void update(double value) {
    visits += 1;
    wins += value;
  }

  /// 是否为叶节点（无子节点且无未尝试行动）。
  bool get isLeaf => children.isEmpty && untriedActions.isEmpty;

  /// 是否还有未被扩展的行动。
  bool get hasUntriedActions => untriedActions.isNotEmpty;

  /// 从已有子节点中选择 UCB1 分数最高的节点。
  MctsNode<A> bestChild() {
    assert(children.isNotEmpty);
    return children.reduce(
      (best, node) => node.ucb1(visits) > best.ucb1(visits) ? node : best,
    );
  }
}
