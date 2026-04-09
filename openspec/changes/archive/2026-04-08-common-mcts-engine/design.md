## 上下文

本项目已有 7 款扑克游戏，其中斗地主、掼蛋、升级、跑得快的 AI 均为静态规则+启发式策略，位于各游戏的 `lib/domain/<game>/ai/` 下。德州扑克已有 `monte_carlo_simulator.dart`，但为独立实现。

当前架构约束：
- 所有游戏状态为 Freezed 不可变对象或手动不可变 class
- AI 行动在 Riverpod notifier 的同步/异步方法中触发（`_scheduleAiIfNeeded`）
- 移动端单帧预算 16ms，AI 决策须在后台计算，避免阻塞 UI
- 单文件不超过 500 行，单方法不超过 100 行（项目规范）

## 目标 / 非目标

**目标：**
- 提供一套与游戏解耦的通用 MCTS 库（`lib/core/ai/mcts/`），无游戏领域依赖
- 定义标准接口 `MctsGameState<A>`，各游戏适配器实现此接口即可接入 MCTS
- 支持完全信息（`MctsEngine`）与隐信息（`PimcEngine`，PIMC 算法）两种场景
- 优先实现斗地主和掼蛋的适配器作为可选"强化难度"档位
- 单次 AI 决策延迟 ≤ 200ms（Isolate 异步执行）

**非目标：**
- 不替换现有规则型 AI，两者并存，由调用方选择
- 不在联机模式下启用 MCTS（Client 端无全局状态，Host 端超时逻辑不变）
- 不实现 Neural Network 评估函数（纯启发式 evaluate）
- 不支持升级、跑得快的适配器（本期仅斗地主 + 掼蛋）

## 决策

### 决策 1：泛型接口而非继承体系

**选择**：`abstract class MctsGameState<A>` 泛型接口，行动类型 `A` 由各游戏自定义。

**理由**：Dart 不支持 sealed interface，泛型 abstract class 是最接近类型安全契约的方式；避免核心引擎依赖任何具体牌型类型；行动类型 `A` 强制各游戏明确定义行动集合（枚举或值类）。

**放弃方案**：`Object` + 强转 → 失去类型安全；代码生成 → 过重。

---

### 决策 2：PIMC（Perfect Information Monte Carlo）用于隐信息游戏

**选择**：`PimcEngine` 对当前可见信息约束下随机化他人手牌，生成 N 个完全信息局面，对每个局面运行 `MctsEngine`，汇总投票。

**理由**：斗地主、掼蛋均有大量不可见手牌。纯 MCTS 无法处理隐信息；PIMC 是学界验证的实用方案（Bridge、Skat 等均用此方法），实现复杂度低于信息集 MCTS（ISMCTS）。

**已知局限**：PIMC 存在"策略融合"问题（合并不同样本的策略可能不一致），对纯信息博弈的质量不如 ISMCTS；但对 4-6 人牌局的决策已足够好用。

**参数**：默认 `samples = 20`，`timeLimit = Duration(milliseconds: 150)`，可由调用方覆盖。

---

### 决策 3：Isolate 异步执行

**选择**：将 `PimcEngine.search()` / `MctsEngine.search()` 封装为 `compute()` 调用（Flutter 的 `Isolate.run` 语法糖），在独立线程执行，返回 `Future<A>`。

**理由**：MCTS 循环是 CPU 密集型，在主 Isolate 执行会丢帧；`compute()` 是 Flutter 官方推荐的轻量后台任务方案，无需手动管理 `SendPort`/`ReceivePort`。

**约束**：传入 `compute()` 的参数必须可序列化（无 Widget、无 BuildContext）。各游戏的 `MctsGameState` 实现类需实现简单的序列化或仅持有纯 Dart 数据。

---

### 决策 4：rollout 策略可插拔

**选择**：`typedef RolloutPolicy<A> = A Function(List<A> actions)`，默认为随机选择，各游戏可传入启发式函数。

**理由**：随机 rollout 在高分支因子时收敛慢；可直接复用现有 `EasyPlayStrategy` 作为快速 rollout，提升收敛速度 3-5 倍，且零额外代码成本。

---

### 决策 5：文件拆分（遵循 500 行规范）

```
lib/core/ai/mcts/
├── mcts_game_state.dart    # MctsGameState<A> 接口（<50行）
├── mcts_node.dart          # MctsNode<A> + UCB1 计算（<80行）
├── mcts_engine.dart        # MctsEngine<S,A>：select/expand/simulate/backprop（<200行）
└── pimc_engine.dart        # PimcEngine<S,A>：采样循环 + 投票（<100行）

lib/domain/doudizhu/ai/
└── doudizhu_mcts_state.dart   # DoudizhuMctsState implements MctsGameState<DoudizhuAction>

lib/domain/guandan/ai/
└── guandan_mcts_state.dart    # GuandanMctsState implements MctsGameState<GuandanAction>
```

## 风险 / 权衡

| 风险 | 缓解措施 |
|------|---------|
| 移动端 CPU 弱，200ms 预算内迭代次数不足，AI 强度有限 | 暴露 `iterations` 参数，低端设备可降至 50 次；rollout 策略用规则 AI 加速收敛 |
| `determinize()` 实现不当（违反已知信息约束）导致 AI 行为诡异 | 在适配器测试中覆盖：采样结果中玩家不持有自己已知的牌 |
| PIMC 策略融合问题（低概率）导致偶发次优决策 | 可接受；作为"强化难度"档位，比规则 AI 强即满足目标 |
| Isolate 序列化开销：游戏状态对象较大（掼蛋 108 张牌） | 在适配器层仅传入最小必要字段（手牌 + 出牌历史），而非完整 GameState |
| `compute()` 在 Web 平台不支持真并发（单线程 JS） | Web 性能降级为阻塞执行，可接受（游戏主要面向移动端）|

## 开放问题

1. **evaluate 函数的归一化**：各适配器返回 0.0~1.0 的评估值，但不同游戏的"局势"评分尺度不同，是否需要统一规范？→ 建议各游戏自定义，不强制跨游戏对齐。
2. **samples 参数的最优值**：20 次采样是经验值，是否需要在真机上 benchmark？→ 放至集成测试阶段测量，初版先用 20。
3. **升级/跑得快适配器优先级**：本期排除，但接口已预留 `determinize()`，后续实现零改造核心引擎。
