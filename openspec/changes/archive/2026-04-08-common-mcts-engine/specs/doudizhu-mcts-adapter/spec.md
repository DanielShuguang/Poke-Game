## 新增需求

### 需求：DoudizhuMctsState 适配器

系统必须提供 `DoudizhuMctsState` 类，实现 `MctsGameState<DoudizhuAction>`，将斗地主游戏状态适配到通用 MCTS 引擎。

#### 场景：枚举当前玩家的合法出牌行动

- **当** 调用 `getLegalActions()` 且当前玩家为地主或农民时
- **那么** 返回所有合法出牌组合，包含"不出（pass）"行动（若当前玩家可选择不出）；终局时返回空列表

#### 场景：应用出牌行动产生新状态

- **当** 调用 `applyAction(action)` 时
- **那么** 返回新的 `DoudizhuMctsState`，其中当前玩家手牌减去打出的牌，上家出牌记录更新，轮次前进，原状态不可变

#### 场景：终局检测

- **当** 任意玩家手牌清空时
- **那么** `isTerminal` 返回 `true`；此时 `getLegalActions()` 返回空列表

#### 场景：局面评估——手牌强度

- **当** 调用 `evaluate(playerId)` 时
- **那么** 基于启发式规则评估 `playerId` 的获胜概率（0.0~1.0），考虑以下因素：剩余手牌数（越少越高）、手牌强度（炸弹、王炸加权）、队伍协同（农民视角：若队友手牌少则加分）

#### 场景：determinize 随机化其他玩家手牌

- **当** 调用 `determinize(playerId)` 时
- **那么** 返回新状态，`playerId` 的手牌不变，其他玩家手牌从剩余未知牌池中随机重新分配（各玩家总张数保持不变）

#### 场景：DoudizhuAction 值类定义

- **当** 定义出牌行动时
- **那么** `DoudizhuAction` 包含 `cards: List<DoudizhuCard>`（出牌列表，pass 为空列表）和 `isPass: bool` 标志

---

### 需求：斗地主 AI 难度档位集成

当斗地主游戏设置为"困难"难度时，系统应使用 `PimcEngine` + `DoudizhuMctsState` 作为 AI 决策引擎，作为现有规则型 AI 的可选替代。

#### 场景：困难难度使用 MCTS

- **当** 斗地主 AI 难度设置为"困难"（hard）时
- **那么** AI 决策通过 `runPimcSearch()` 异步执行，≤ 200ms 返回行动

#### 场景：非困难难度保持现有策略

- **当** 斗地主 AI 难度为"简单"或"普通"时
- **那么** 使用现有 `PlayStrategy`（`EasyPlayStrategy`/`NormalPlayStrategy`），不调用 MCTS 引擎
