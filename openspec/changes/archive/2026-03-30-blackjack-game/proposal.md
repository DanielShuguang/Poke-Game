## 为什么

游戏合集目前包含斗地主、德州扑克、炸金花三款游戏，缺少经典的 21 点（Blackjack）玩法。21 点规则简单、节奏快，与玩家 vs 庄家的对抗模式天然契合局域网多人对战场景，是补全游戏库的高优先级品类。

## 变更内容

- **新增** 21 点单机模式：玩家对战 AI 庄家，支持 Hit / Stand / Double / Split / Surrender
- **新增** 21 点联机模式：局域网房间中一名玩家担任庄家，其余玩家同时与庄家对战，Host/Client 适配器模式同步状态
- **新增** AI 庄家策略：庄家点数 ≤ 16 必须摸牌，≥ 17 停牌（硬 17 规则）
- **修改** 游戏选择页面：将 21 点加入游戏列表，含"联机对战"快速入口
- **修改** 房间管理：支持以 `blackjack` 作为游戏类型创建/加入房间

## 功能 (Capabilities)

### 新增功能

- `blackjack-engine`: 21 点核心引擎——牌局状态机、手牌点数计算（A 算 1/11）、发牌/操作流程（Hit/Stand/Double/Split/Surrender）、胜负结算（Blackjack 1.5 倍赔率、爆牌、五小龙可选规则）
- `blackjack-ai`: AI 庄家策略——标准 Hard 17 规则摇牌逻辑；可扩展为基础策略表（Basic Strategy）辅助提示
- `blackjack-ui`: 21 点游戏页面——牌桌布局、玩家区/庄家区、操作按钮栏、筹码下注 UI、动画翻牌效果
- `blackjack-network`: 联机网络适配器——Host/Client 行动路由、35s 超时自动 Stand、手牌隐私（庄家暗牌对 Client 隐藏）

### 修改功能

- `game-selection`: 将 21 点加入游戏列表，增加联机快速入口按钮（与斗地主/德州扑克/炸金花保持一致）
- `room-management`: 支持 `blackjack` 游戏类型，房间人数配置 2–7 人（1 庄家 + 1–6 玩家）

## 影响

- **新增文件**：`lib/domain/blackjack/`（entities、usecases、validators、ai）、`lib/core/network/blackjack_network_adapter.dart`、`lib/presentation/pages/blackjack/`
- **修改文件**：`lib/presentation/pages/home/home_page.dart`、`lib/presentation/pages/room/room_lobby_page.dart`、`lib/core/router/app_router.dart`
- **依赖**：无新增第三方依赖，复用现有 `flutter_riverpod`、局域网 WebSocket 基础设施
- **兼容性**：不影响已有游戏，路由新增 `/blackjack` 路径
