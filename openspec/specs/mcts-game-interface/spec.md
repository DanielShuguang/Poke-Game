## 新增需求

### 需求：MctsGameState 泛型接口契约
系统必须提供抽象类 `MctsGameState<A>`，`A` 为行动类型参数，作为所有游戏接入 MCTS 引擎的唯一契约。实现类必须满足值不可变性——每次 `applyAction` 必须返回新对象而非修改原对象。

#### 场景：获取合法行动列表
- **当** 调用 `getLegalActions()` 时
- **那么** 返回当前局面下所有合法行动的非空列表（终局时返回空列表）

#### 场景：应用行动产生新状态
- **当** 调用 `applyAction(action)` 时
- **那么** 返回应用该行动后的新 `MctsGameState<A>` 对象，原状态对象禁止被修改

#### 场景：终局检测
- **当** 调用 `isTerminal` 时
- **那么** 若游戏已结束返回 true，否则返回 false；终局状态下 `getLegalActions()` 必须返回空列表

#### 场景：局面评估
- **当** 调用 `evaluate(playerId)` 时
- **那么** 返回 0.0~1.0 范围内的浮点数，表示 `playerId` 视角下的获胜概率估计；1.0 表示确定胜利，0.0 表示确定失败

### 需求：determinize 方法供 PIMC 使用
`MctsGameState<A>` 必须提供 `determinize(String playerId)` 方法，将隐信息局面转换为完全信息局面。

#### 场景：随机化他人手牌
- **当** 调用 `determinize(playerId)` 时
- **那么** 返回新状态，其中 `playerId` 的手牌保持不变，其他玩家的手牌在已知信息约束下随机重新分配（总张数不变）

#### 场景：完全信息游戏的 determinize 实现
- **当** 游戏本身无隐信息（如跑得快）
- **那么** `determinize()` 返回 `this`（直接返回自身即可）
