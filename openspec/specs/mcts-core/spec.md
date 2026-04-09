## 新增需求

### 需求：MctsNode UCB1 节点

系统必须提供 `MctsNode<A>` 类，封装 MCTS 树节点的统计数据与 UCB1 选择逻辑。

#### 场景：UCB1 分数计算

- **当** 节点已访问过（visits > 0）且父节点也有访问记录时
- **那么** 返回 `wins/visits + c * sqrt(ln(parentVisits) / visits)`，其中 `c` 默认为 `sqrt(2)`

#### 场景：未访问节点的 UCB1

- **当** 节点 visits == 0 时
- **那么** 返回正无穷（`double.infinity`），保证未探索节点优先被选择

#### 场景：反向传播更新

- **当** 调用 `update(double value)` 时
- **那么** `visits` 加 1，`wins` 加 `value`，且原子完成（单线程下无竞争）

---

### 需求：MctsEngine UCT 搜索

系统必须提供 `MctsEngine<S extends MctsGameState<A>, A>` 类，实现标准 UCT（Upper Confidence Bound for Trees）搜索循环。

#### 场景：在时间预算内搜索

- **当** 调用 `search(state)` 且设置了 `timeLimit` 时
- **那么** 在 `timeLimit` 到期前持续迭代 select/expand/simulate/backpropagate，返回访问次数最多的合法行动

#### 场景：在迭代次数预算内搜索

- **当** 调用 `search(state)` 且设置了 `iterations` 时
- **那么** 恰好执行 `iterations` 次完整迭代后返回结果

#### 场景：选择阶段（Selection）

- **当** 执行选择时
- **那么** 从根节点出发，沿 UCB1 分数最高的子节点递归下行，直到到达叶节点或终局节点

#### 场景：扩展阶段（Expansion）

- **当** 叶节点存在未探索的合法行动时
- **那么** 随机选择一个未探索行动，创建新子节点并返回

#### 场景：模拟阶段（Simulation / Rollout）

- **当** 执行模拟时
- **那么** 从新节点出发，使用 `rolloutPolicy` 函数重复选行动直至终局，返回 `evaluate(currentPlayerId)` 的结果

#### 场景：回传阶段（Backpropagation）

- **当** 模拟结束后
- **那么** 沿路径从叶到根依次调用每个节点的 `update(value)`，交替视角取反（对手视角得分 = 1 - value）

#### 场景：可插拔 rollout 策略

- **当** 构造 `MctsEngine` 时传入自定义 `RolloutPolicy<A>` 时
- **那么** 模拟阶段使用该策略选行动；未传入时默认使用随机策略（`actions[Random().nextInt(actions.length)]`）

#### 场景：终局状态无合法行动

- **当** `search(state)` 被调用时，`state.isTerminal == true`
- **那么** 抛出 `StateError`（调用方不应对终局状态调用搜索）
