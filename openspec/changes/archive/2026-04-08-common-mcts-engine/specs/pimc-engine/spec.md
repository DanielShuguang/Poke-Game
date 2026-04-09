## 新增需求

### 需求：PimcEngine 隐信息局面搜索

系统必须提供 `PimcEngine<S extends MctsGameState<A>, A>` 类，通过 PIMC（Perfect Information Monte Carlo）算法处理含隐信息的牌局决策。

#### 场景：生成 N 个确定性样本并聚合投票

- **当** 调用 `search(state, currentPlayerId)` 时
- **那么** 调用 `state.determinize(currentPlayerId)` 共 `samples` 次，对每个样本运行 `MctsEngine.search()`，将每个样本返回的最优行动累加投票，最终返回得票最多的行动

#### 场景：timeLimit 均摊到每个样本

- **当** 设置了 `timeLimit` 时
- **那么** 每个样本的 `MctsEngine` 时间预算为 `timeLimit / samples`，避免总耗时超出预算

#### 场景：samples 参数默认值

- **当** 构造 `PimcEngine` 时未指定 `samples` 时
- **那么** 默认使用 `samples = 20`

#### 场景：timeLimit 参数默认值

- **当** 构造 `PimcEngine` 时未指定 `timeLimit` 时
- **那么** 默认使用 `timeLimit = Duration(milliseconds: 150)`

#### 场景：投票平局处理

- **当** 多个行动得票相同时
- **那么** 从并列最高票行动中随机选取一个返回

#### 场景：rolloutPolicy 透传

- **当** 构造 `PimcEngine` 时传入 `rolloutPolicy` 时
- **那么** 内部每个 `MctsEngine` 实例均使用同一个 `rolloutPolicy`

---

### 需求：Isolate 异步封装

系统必须提供顶层函数 `runPimcSearch<S, A>` 与 `runMctsSearch<S, A>`，通过 `compute()` 在独立 Isolate 中执行搜索，避免阻塞 UI 主线程。

#### 场景：后台异步执行

- **当** 调用 `runPimcSearch(params)` 时
- **那么** 在新 Isolate 中执行 `PimcEngine.search()`，返回 `Future<A>`，主线程不阻塞

#### 场景：参数可序列化约束

- **当** 传入 `compute()` 的参数包含不可序列化对象（Widget、BuildContext 等）时
- **那么** 编译期类型检查（`SendPort` 兼容）或运行时抛出序列化错误（调用方负责只传入纯 Dart 数据）
