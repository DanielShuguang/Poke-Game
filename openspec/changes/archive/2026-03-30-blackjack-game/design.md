## 上下文

项目已有斗地主、德州扑克、炸金花三款游戏，均采用 Clean Architecture + flutter_riverpod 状态管理，联机部分统一使用 Host/Client WebSocket 适配器模式（`HoldemNetworkAdapter`、`ZhjNetworkAdapter`）。21 点将复用相同的架构骨架，新增 `blackjack-engine`、`blackjack-ai`、`blackjack-network` 三个模块，并接入现有的局域网房间系统。

## 目标 / 非目标

**目标：**
- 实现标准 21 点单机游戏（玩家 vs AI 庄家），支持 Hit / Stand / Double / Split / Surrender
- 实现局域网联机模式（1 庄家 + 1–6 玩家），Host/Client 双端状态同步，35s 超时自动 Stand
- AI 庄家使用 Hard 17 规则（≤16 摸牌，≥17 停牌）
- 将 21 点接入现有首页游戏列表与房间大厅路由

**非目标：**
- 在线服务器对战（仅局域网）
- 筹码货币体系、账户充值
- 牌计数辅助（Card Counting）功能
- 旁注（Side Bet）：完美对子、21+3 等变体规则

## 决策

### 1. 状态机设计：轮次驱动 vs 全局状态
采用**全局状态快照**（`BlackjackGameState` freezed 不可变对象），每次操作产生新快照广播给所有端，与德州扑克、炸金花保持一致。
替代方案（事件溯源）复杂度过高，对本游戏规模无必要。

### 2. 联机庄家角色
Host 端始终扮演庄家或控制 AI 庄家行为，其他 Client 端为玩家。庄家暗牌（第二张）在结算前仅 Host 知道（`toJson(includeAllCards: true)` 仅用于 Host 内部存储，广播时隐藏庄家第二张牌）。

### 3. 分牌（Split）的联机处理
Split 产生一个额外手牌，状态中用 `List<BlackjackHand>` 表示每位玩家的手牌列表（通常 1 个，Split 后 2 个）。联机时每次操作附带 `handIndex` 字段区分当前操作的手牌。

### 4. AI 庄家
单机模式下 AI 庄家使用标准 Hard 17 规则，逻辑封装在 `BlackjackDealerAI`。联机模式下 Host 在所有玩家完成操作后自动执行 AI 庄家行为（无需 Client 参与），与炸金花 AI 处理方式相同。

### 5. 路由
新增 `/blackjack` 路由，参数与炸金花页面相同：`isOnline: bool`、`networkAdapter: BlackjackNetworkAdapter?`。`RoomLobbyPage` 的 `_navigateToGame()` 方法增加 `blackjack` 分支。

## 风险 / 权衡

- **Split 状态复杂度** → 手牌列表 + handIndex 使状态略复杂；MVP 阶段限制每玩家最多 Split 一次（最多 2 手牌）降低风险
- **庄家暗牌隐藏** → 与炸金花手牌隐私逻辑类似，需仔细处理 `fromJson` 时庄家第二张牌的过滤；提前编写单元测试覆盖
- **联机人数弹性（1–6 玩家）** → 现有房间系统已支持动态人数，无需特殊处理
- **超时 Stand vs 超时 Fold** → 21 点超时应 Stand（不失去下注），与炸金花超时 Fold 逻辑不同，需在适配器中区分

## 迁移计划

1. 新建 `lib/domain/blackjack/` 和 `lib/presentation/pages/blackjack/`，不影响其他游戏
2. 修改 `home_page.dart`（`_supportsOnline` 加入 `blackjack`）
3. 修改 `app_router.dart` 注册 `/blackjack` 路由
4. 修改 `room_lobby_page.dart` `_navigateToGame()` 加入 `blackjack` 分支
5. 全量 `flutter analyze` 验证，运行单元测试

## 未解决问题

- 是否支持"五小龙"（5 张牌不爆牌自动赢）？→ 作为可选 `GameConfig` 参数，默认关闭
- 联机模式下庄家角色是由房主固定担任，还是轮流？→ MVP 阶段固定房主为庄家
