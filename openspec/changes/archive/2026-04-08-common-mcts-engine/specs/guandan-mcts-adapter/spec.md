## 新增需求

### 需求：GuandanMctsState 适配器

系统必须提供 `GuandanMctsState` 类，实现 `MctsGameState<GuandanAction>`，将掼蛋游戏状态适配到通用 MCTS 引擎，并支持团队视角评估与贡牌阶段处理。

#### 场景：枚举当前玩家的合法出牌行动

- **当** 调用 `getLegalActions()` 且当前游戏处于出牌阶段时
- **那么** 返回所有合法出牌组合（包括 pass），由 `ValidateHandUsecase` 校验合法性；终局时返回空列表

#### 场景：贡牌阶段的合法行动

- **当** 调用 `getLegalActions()` 且当前处于贡牌阶段时
- **那么** 返回当前玩家可选的贡牌行动列表（若贡牌规则豁免则返回空操作行动）

#### 场景：应用出牌行动产生新状态

- **当** 调用 `applyAction(action)` 时
- **那么** 返回新的 `GuandanMctsState`，当前玩家手牌减去打出的牌，上家出牌更新，轮次前进；不修改原状态

#### 场景：终局检测

- **当** 任意一方团队（两名玩家）均手牌清空时
- **那么** `isTerminal` 返回 `true`；此时 `getLegalActions()` 返回空列表

#### 场景：团队视角评估

- **当** 调用 `evaluate(playerId)` 时
- **那么** 以团队视角计算获胜概率：将 `playerId` 及其队友的手牌强度合并评估，考虑剩余牌数、百搭数量、级牌数量、炸弹数量

#### 场景：determinize 随机化对手手牌

- **当** 调用 `determinize(playerId)` 时
- **那么** 返回新状态，`playerId` 及其队友的手牌保持不变，两名对手的手牌从未知牌池随机重新分配（各自总张数不变，总 108 张守恒）

#### 场景：GuandanAction 值类定义

- **当** 定义掼蛋出牌行动时
- **那么** `GuandanAction` 包含 `cards: List<GuandanCard>`（出牌列表，pass 为空列表）、`isPass: bool` 标志，以及可选的 `tribute: GuandanCard?`（贡牌阶段使用）

---

### 需求：掼蛋 AI 难度档位集成

当掼蛋游戏设置为"困难"难度时，系统应使用 `PimcEngine` + `GuandanMctsState` 作为 AI 决策引擎，作为现有规则型 AI 的可选替代。

#### 场景：困难难度使用 MCTS

- **当** 掼蛋 AI 难度设置为"困难"（hard）时
- **那么** AI 决策通过 `runPimcSearch()` 异步执行，≤ 200ms 返回行动

#### 场景：非困难难度保持现有策略

- **当** 掼蛋 AI 难度为"简单"或"普通"时
- **那么** 使用现有 `GuandanPlayStrategy`，不调用 MCTS 引擎
