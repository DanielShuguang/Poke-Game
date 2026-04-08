## 上下文

项目已有 6 款扑克游戏，均遵循相同的 Clean Architecture + Riverpod 架构模式，以及统一的 Host/Client 局域网联机适配器。掼蛋新增一个新颖复杂点：**级牌百搭**（当前轮级牌可嵌入顺子）和**贡牌/还贡**流程，这在现有游戏中均无对应，需要专项设计。

## 目标 / 非目标

**目标：**
- 实现完整的掼蛋核心玩法（4 人两队、级牌体系、完整牌型判定、升/降级结算）
- 支持单机 AI 对战（3 个 AI 对手）
- 支持局域网联机（4 人，Host/Client 适配器模式）
- 贡牌/还贡流程在联机模式下正确同步
- 接入首页卡片、局域网房间流程

**非目标：**
- 在线服务器对战（无后端）
- 玩家积分/段位系统
- 观战模式
- 掼蛋变体规则（如"挑衅"等地方规则）

## 决策

### D1：复用 Card 实体还是新建？

**决策**：新建 `lib/domain/guandan/entities/guandan_card.dart`，独立于其他游戏。

**理由**：掼蛋的 Card 需要携带"是否为级牌百搭"标记，且牌的比较逻辑与花色完全无关（无主牌），与斗地主/升级的 Card 语义不同。共用实体会引入不必要的耦合。

**放弃方案**：直接复用 `domain/shengji` 的 Card——升级的 Card 携带主牌/副牌属性，语义冲突。

---

### D2：级牌百搭的嵌入逻辑

**决策**：在 `ValidateHandUsecase` 中，顺子合法性检查允许"用级牌填补缺口"，规则：每张级牌最多充当一个缺口，且不可用于充当两端延伸牌。

具体流程：
1. 提取非级牌，排序后检测缺口位置
2. 用可用的级牌（包含大小王之外的级牌）逐个填补
3. 如果级牌数量 ≥ 缺口数，顺子合法

**放弃方案**：在 UI 层做提示不做校验——会导致联机时 Host/Client 行为不一致。

---

### D3：炸弹大小排序

优先级从高到低：
1. 天王炸（大王×2）
2. 同花顺炸（5 张及以上同花色连续）—— 张数多的更大
3. 级牌炸（4 张及以上相同级牌）—— 张数多的更大
4. 普通炸（4 张及以上相同点数）—— 张数多的更大

**理由**：与主流掼蛋规则一致；级牌炸单独区分是因为其特殊性（可抵制同点数普通炸）。

---

### D4：贡牌/还贡在联机中的同步

**决策**：贡牌阶段作为独立的 `GuandanPhase.tribute`，Host 持有完整状态，通过已有的广播机制分发。

贡牌消息格式：
```json
{ "type": "tribute", "card": "AH" }
{ "type": "returnTribute", "card": "5D" }
```

Host 验证合法性（贡出的牌必须是手牌最大牌）后广播新状态，Client 无需独立校验。

**放弃方案**：Client 侧先校验再发送——增加双端代码复杂度，且 Host 仍需最终验证。

---

### D5：联机行动消息格式（`GuandanNetworkAction`）

```dart
sealed class GuandanNetworkAction {
  const GuandanNetworkAction();
}

class PlayCards extends GuandanNetworkAction {
  final List<String> cards; // e.g. ["AH","AS","JokerBig"]
}

class Pass extends GuandanNetworkAction {}

class Tribute extends GuandanNetworkAction {
  final String card;
}

class ReturnTribute extends GuandanNetworkAction {
  final String card;
}
```

序列化为 JSON，通过 `sendGameMessage` / `broadcastGameMessage` 传输，与现有适配器保持一致。

---

### D6：AI 策略

采用**规则+优先级**策略（非 MCTS），与项目内其他游戏 AI 一致：

1. **跟牌**：优先出能压制的最小手牌；无法跟牌则过
2. **出牌**：优先出单张小牌消耗手牌；保留炸弹应对关键局面
3. **配合队友**：检测当前领先玩家是否为队友，若是则倾向 pass
4. **贡牌**：自动贡出手牌最大单张

---

### D7：UI 布局

横屏，4 人围桌：
- 底部：本地玩家手牌 + 出牌按钮
- 顶部：对家手牌背面
- 左右：两侧对手手牌背面
- 中间：已出牌堆、当前轮信息（级牌、轮次）、出牌按钮区
- 左上角：退出按钮（统一规范）

贡牌阶段覆盖弹窗处理，不新增页面。

## 风险 / 权衡

| 风险 | 缓解措施 |
|------|----------|
| 级牌百搭嵌入顺子的边界情况（如多张级牌、两端延伸）导致判定错误 | 为 `ValidateHandUsecase` 编写详尽单元测试，覆盖所有边界 |
| 贡牌阶段联机同步时序问题（两个输家同时贡牌） | Host 顺序处理贡牌消息，广播中间态，避免并发冲突 |
| 升级结算逻辑复杂（头游/二游/三游归属影响升级档数） | 封装 `RoundResultUsecase`，单独测试升降级计算 |
| 文件行数超限（单个页面逻辑较重） | 将手牌区、出牌区、状态栏拆分为独立 Widget 文件 |
