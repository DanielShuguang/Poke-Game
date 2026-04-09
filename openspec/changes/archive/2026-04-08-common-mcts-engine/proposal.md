## 为什么

现有各游戏 AI 均采用静态规则+启发式策略，决策质量有限且无法自适应对手行为。MCTS（蒙特卡洛树搜索）可通过模拟对局预测最优行动，显著提升 AI 强度；而多款游戏（斗地主、掼蛋、升级、跑得快）均可受益，若为每款游戏分别实现 MCTS 会大量重复核心算法代码。

## 变更内容

- **新增**：`lib/core/ai/mcts/` 目录，包含游戏无关的通用 MCTS 引擎
- **新增**：`MctsGameState<A>` 泛型接口，各游戏通过实现该接口接入 MCTS
- **新增**：`MctsEngine<S, A>` — 标准 UCT 搜索，支持可插拔 rollout 策略
- **新增**：`PimcEngine<S, A>` — 基于局面采样的 PIMC 引擎，用于隐信息牌局
- **新增**：斗地主、掼蛋两款游戏的 MCTS 适配器（优先级最高的两款）
- 现有规则型 AI 策略保持不变，新适配器作为可选强化难度档位引入

## 功能 (Capabilities)

### 新增功能

- `mcts-core`: 通用 MCTS 核心模块——UCT 节点、选择/扩展/模拟/回传循环、可插拔 rollout 策略接口
- `pimc-engine`: PIMC 引擎——对隐信息局面进行 N 次随机化采样，汇总投票选出最优行动
- `mcts-game-interface`: 泛型接口 `MctsGameState<A>`——定义 getLegalActions / applyAction / isTerminal / evaluate / determinize 契约，供各游戏实现
- `doudizhu-mcts-adapter`: 斗地主 MCTS 适配器——实现 `MctsGameState`，枚举出牌/不出行动，评估手牌强度与胜率
- `guandan-mcts-adapter`: 掼蛋 MCTS 适配器——实现 `MctsGameState`，支持团队视角评估与贡牌阶段跳过

### 修改功能

（无需求层面变更）

## 影响

- **新增文件**：`lib/core/ai/mcts/mcts_game_state.dart`、`mcts_node.dart`、`mcts_engine.dart`、`pimc_engine.dart`
- **新增文件**：`lib/domain/doudizhu/ai/doudizhu_mcts_state.dart`、`lib/domain/guandan/ai/guandan_mcts_state.dart`
- **不修改**：现有规则型 AI 文件（`play_strategy.dart` 等），新引擎与旧策略并存
- **不修改**：联机适配器、游戏 notifier、UI 层
- **依赖**：无新增 pub 依赖（纯 Dart 实现）
- **性能约束**：单次决策目标 ≤ 200ms（移动端），通过 `timeLimit` 参数控制
