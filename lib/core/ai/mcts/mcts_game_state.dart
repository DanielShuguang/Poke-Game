/// MCTS 游戏状态抽象接口
///
/// 泛型参数 [A] 为行动类型。游戏适配器通过实现此接口接入通用 MCTS 引擎。
abstract class MctsGameState<A> {
  /// 返回当前局面下的所有合法行动。
  /// 终局时返回空列表。
  List<A> getLegalActions();

  /// 应用行动 [action]，返回新状态（不可变，不修改原状态）。
  MctsGameState<A> applyAction(A action);

  /// 当前局面是否为终局。
  bool get isTerminal;

  /// 从 [playerId] 视角评估局面，返回 0.0（必败）到 1.0（必胜）之间的分数。
  double evaluate(String playerId);

  /// 对局面进行确定性采样：保持 [playerId] 的手牌不变，
  /// 随机重新分配其他玩家的未知手牌，返回新状态。
  ///
  /// 用于 PIMC（Perfect Information Monte Carlo）算法中消除隐信息。
  MctsGameState<A> determinize(String playerId);
}

/// 可插拔 rollout 策略类型。
/// 接受合法行动列表，返回选中的行动。
typedef RolloutPolicy<A> = A Function(List<A> actions);
