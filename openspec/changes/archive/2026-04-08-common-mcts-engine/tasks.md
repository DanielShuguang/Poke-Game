## 1. MCTS 核心引擎

- [x] 1.1 创建 `lib/core/ai/mcts/mcts_game_state.dart`：定义 `MctsGameState<A>` 抽象类，包含 `getLegalActions`、`applyAction`、`isTerminal`、`evaluate`、`determinize` 方法
- [x] 1.2 创建 `lib/core/ai/mcts/mcts_node.dart`：实现 `MctsNode<A>` 类，包含 UCB1 分数计算（`double.infinity` 处理未访问节点）和 `update(double)` 方法
- [x] 1.3 创建 `lib/core/ai/mcts/mcts_engine.dart`：实现 `MctsEngine<S, A>` 类，包含 select/expand/simulate/backpropagate 四阶段循环，支持 `timeLimit` 和 `iterations` 两种终止条件，支持可插拔 `RolloutPolicy<A>`
- [x] 1.4 创建 `lib/core/ai/mcts/pimc_engine.dart`：实现 `PimcEngine<S, A>` 类，默认 `samples=20`、`timeLimit=150ms`，均摊时间预算，汇总投票，平局随机选取
- [x] 1.5 在 `pimc_engine.dart` 中添加 `runPimcSearch` 和 `runMctsSearch` 顶层函数，通过 `compute()` 封装异步 Isolate 执行

## 2. MCTS 核心引擎单元测试

- [x] 2.1 创建 `test/core/ai/mcts/mcts_node_test.dart`：测试 UCB1 计算（visits=0 返回正无穷、visits>0 公式正确）和 update 累加
- [x] 2.2 创建 `test/core/ai/mcts/mcts_engine_test.dart`：使用简单确定性测试游戏（如 Nim）验证引擎能找到最优行动
- [x] 2.3 创建 `test/core/ai/mcts/pimc_engine_test.dart`：验证 samples 次 determinize 被调用，返回行动为合法行动，时间 ≤ 200ms

## 3. 斗地主 MCTS 适配器

- [x] 3.1 创建 `lib/domain/doudizhu/ai/doudizhu_mcts_state.dart`：定义 `DoudizhuAction` 值类（`cards`、`isPass`）和 `DoudizhuMctsState` 实现类
- [x] 3.2 实现 `DoudizhuMctsState.getLegalActions()`：枚举所有合法出牌组合 + pass，复用现有 `DoudizhuValidator`
- [x] 3.3 实现 `DoudizhuMctsState.applyAction()`：不可变状态转换，手牌减牌，轮次推进
- [x] 3.4 实现 `DoudizhuMctsState.evaluate()`：基于手牌数量、炸弹、王炸、团队视角的启发式评分（0.0~1.0）
- [x] 3.5 实现 `DoudizhuMctsState.determinize()`：从剩余未知牌池随机重分配对手手牌，张数守恒
- [x] 3.6 在斗地主 AI 调度处（`_scheduleAiIfNeeded`）添加困难难度分支，调用 `runPimcSearch()`，结果通过 notifier 方法执行

## 4. 斗地主 MCTS 适配器单元测试

- [x] 4.1 创建 `test/domain/doudizhu/ai/doudizhu_mcts_state_test.dart`：测试 `getLegalActions`（含 pass）、`applyAction`（不可变性）、`isTerminal`（手牌清空时为 true）
- [x] 4.2 测试 `determinize`：采样结果中当前玩家手牌不变，其他玩家手牌总张数与原来相同
- [x] 4.3 集成测试：困难难度下 AI 能在 200ms 内返回合法行动

## 5. 掼蛋 MCTS 适配器

- [x] 5.1 创建 `lib/domain/guandan/ai/guandan_mcts_state.dart`：定义 `GuandanAction` 值类（`cards`、`isPass`、`tribute`）和 `GuandanMctsState` 实现类
- [x] 5.2 实现 `GuandanMctsState.getLegalActions()`：出牌阶段枚举合法组合 + pass，贡牌阶段返回可贡牌列表，复用 `ValidateHandUsecase`
- [x] 5.3 实现 `GuandanMctsState.applyAction()`：不可变状态转换，处理出牌和贡牌两种阶段
- [x] 5.4 实现 `GuandanMctsState.evaluate()`：团队视角评估，考虑双方剩余牌数、百搭数、级牌数、炸弹数
- [x] 5.5 实现 `GuandanMctsState.determinize()`：保持当前玩家及队友手牌不变，随机重分配两名对手手牌，108 张总数守恒
- [x] 5.6 在掼蛋 AI 调度处添加困难难度分支，调用 `runPimcSearch()`，结果通过 notifier 方法执行

## 6. 掼蛋 MCTS 适配器单元测试

- [x] 6.1 创建 `test/domain/guandan/ai/guandan_mcts_state_test.dart`：测试 `getLegalActions`（出牌 + 贡牌两阶段）、`applyAction`（不可变性）、`isTerminal`（团队手牌清空时为 true）
- [x] 6.2 测试 `determinize`：当前玩家及队友手牌不变，对手手牌重分配后总张数为 108
- [x] 6.3 集成测试：困难难度下 AI 能在 200ms 内返回合法行动
