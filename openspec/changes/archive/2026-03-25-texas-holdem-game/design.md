## 上下文

项目已有完整的斗地主实现（Clean Architecture 分层：domain / data / presentation），以及局域网房间管理、UDP 广播、玩家管理和网络同步基础设施。德州扑克将作为第二款游戏接入，遵循相同的架构分层，并复用现有网络层能力。

当前约束：
- 纯 Dart / Flutter，无原生插件依赖
- 状态管理使用 flutter_riverpod（与斗地主一致）
- 目标平台：Android / iOS / Web / Windows / macOS / Linux
- 本期范围：**现金局（Cash Game）**，不含锦标赛模式

## 目标 / 非目标

**目标：**
- 实现完整的德州扑克现金局游戏流程（Preflop → Flop → Turn → River → Showdown）
- 支持 3-6 人桌，人机模式下 AI 填充空位
- 支持局域网多人对战，复用现有房间系统
- 实现 7 选 5 牌型评估引擎（正确判断胜负与平分底池）
- 实现边池（Side Pot）计算，支持 All-in 场景
- AI 决策基于简化蒙特卡洛胜率估算

**非目标：**
- 锦标赛模式（盲注递增、淘汰机制）
- Omaha / 短牌等变种
- 在线匹配（仅局域网）
- 积分排行榜（本期不含）
- 真人荷官动画等高级 UI 效果

## 决策

### 1. 目录结构：复用斗地主分层模式

```
lib/
├── domain/texas_holdem/
│   ├── entities/          # Card（复用）, HoldemPlayer, HoldemGameState, Pot
│   ├── usecases/          # DealCardsUsecase, BettingRoundUsecase, ShowdownUsecase
│   ├── validators/        # HandEvaluator（7选5牌型评估）
│   └── ai/strategies/     # HoldemAiStrategy（蒙特卡洛）
├── data/texas_holdem/
│   └── repositories/      # HoldemGameRepositoryImpl
└── presentation/pages/texas_holdem/
    ├── holdem_game_page.dart
    └── widgets/
```

**理由**：与斗地主保持一致，降低维护成本，新成员可快速上手。Card 实体（花色/点数）可直接复用，不重复定义。

### 2. 牌型评估：纯 Dart 实现，枚举 C(7,5) = 21 种组合

从 7 张牌（2张底牌 + 最多5张公牌）中枚举所有 21 种 5 张组合，对每种组合评分，取最高分。

评分方案：将牌型编码为整数（高位为牌型等级，低位为点数序列），可直接用整数比较大小。

**替代方案**：引入第三方库（如 `poker_eval`）→ 增加依赖，Web 平台兼容性不确定，且逻辑不透明，**放弃**。

### 3. 边池计算：按 All-in 筹码分层

每位 All-in 玩家建立独立边池上限：
```
主池（Main Pot）= min(所有玩家下注额) × 参与人数
边池（Side Pot）= 超出部分按层级依次计算
```
非 All-in 玩家始终参与当前最高层级的池。

**理由**：All-in 场景若不正确处理边池，会导致筹码总量计算错误，是德州扑克实现的核心复杂点。

### 4. AI 策略：简化蒙特卡洛 + 规则修正

分两阶段：
1. **胜率估算**：用当前底牌 + 已知公牌，随机模拟剩余公牌和对手手牌 N 次（N=200~500），统计获胜概率（equity）
2. **决策规则**：
   - equity > 0.65 → 倾向 Raise
   - equity > 0.40 → Call（参考底池赔率）
   - equity < 0.20 → Fold
   - 随机扰动（±15%）避免行为过于机械

**替代方案**：完整 GTO 策略 → 实现复杂度极高，超出本期范围，**放弃**。

### 5. 多人同步：复用 RoomStateSyncService

多人模式下，房主（Host）持有权威游戏状态，广播给所有客户端。客户端仅发送动作（Fold/Call/Raise + 金额），Host 验证后更新状态再广播。

与斗地主多人方案完全一致，无需新建网络层。

### 6. 状态管理：StateNotifierProvider（与斗地主一致）

`HoldemGameNotifier extends StateNotifier<HoldemGameState>`，所有游戏动作通过 Notifier 方法触发，UI 用 `ConsumerWidget` 监听。

## 风险 / 权衡

| 风险 | 缓解措施 |
|------|---------|
| 蒙特卡洛模拟在低端设备上卡顿（每次决策 200-500 次模拟） | 在 `Isolate` 中运行模拟，避免阻塞 UI 线程 |
| 边池计算逻辑复杂，容易出现筹码漏洞 | 为 `PotCalculator` 编写单元测试，覆盖多人 All-in 场景 |
| 7选5枚举在极端场景下性能问题 | 21种组合量极小，无需优化；若未来支持 Omaha（4张底牌）再考虑 |
| 局域网多人延迟导致操作不同步 | 沿用现有超时自动弃牌机制（已在斗地主多人中验证） |
| Card 实体复用时花色/点数表示可能与德州扑克规则冲突 | 确认斗地主 Card 使用通用 Suit + Rank 枚举，如有冲突则派生子类 |

## 开放问题

- [ ] AI 模拟次数阈值（200 vs 500）需要在实际设备上测压后确定
- [ ] 是否支持自定义初始筹码和盲注金额（现金局配置）？
- [ ] 平局（Split Pot）时筹码整除问题如何处理（奇数筹码归庄家位或小盲）？
