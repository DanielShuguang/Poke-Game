## 为什么

牛牛是国内极为流行的扑克博弈游戏，现有游戏合集（斗地主、德州扑克、炸金花、21点）中尚无牛牛，补全该玩法可丰富游戏多样性，满足用户对博弈类扑克游戏的需求。

## 变更内容

- **新增**：牛牛单机模式，支持 1 名真人玩家 + 2~5 名 AI 对手
- **新增**：牛牛局域网联机模式，支持 2~6 名玩家（1 名庄家 + 最多 5 名闲家）
- **新增**：牛牛游戏引擎（发牌、判牛、比牌、筹码结算）
- **新增**：牛牛庄家 AI（托管闲家行动，控制发牌节奏）
- **新增**：牛牛 UI 页面（横屏，显示牌型、倍率、筹码、结算覆盖层）
- **新增**：牛牛网络适配层（Host/Client 模式，35 秒超时）
- **修改**：首页游戏列表将牛牛从"敬请期待"更新为可用，并添加"联机对战"按钮
- **修改**：房间大厅添加 niuniu 游戏类型路由支持

## 功能 (Capabilities)

### 新增功能
- `niuniu-engine`: 牛牛游戏引擎——发牌、判牛（5张牌中任意3张之和为10的倍数）、牌型等级（无牛/牛1~牛9/牛牛/五小牛/炸弹）、比牌、筹码结算（按牌型倍率）
- `niuniu-ai`: 牛牛 AI——闲家托管逻辑（自动跟注/加注策略）和发牌动画延迟
- `niuniu-ui`: 牛牛 UI 页面——横屏牌桌、下注区、牌型倍率展示、结算覆盖层、发牌动画
- `niuniu-network`: 牛牛网络适配层——Host/Client 行动同步、手牌隐私过滤、35s 超时 Stand

### 修改功能
- `game-selection`: 将牛牛从 `planned` 改为 `available`，首页卡片添加"联机对战"按钮
- `room-management`: 添加 `niuniu` 游戏类型的房间创建（2~6人）与大厅导航支持

## 影响

- `lib/domain/niuniu/` — 新建（entities, usecases, ai）
- `lib/core/network/niuniu_network_adapter.dart` — 新建
- `lib/presentation/pages/niuniu/` — 新建（niuniu_page.dart, providers/）
- `lib/core/router/app_router.dart` — 注册 `/niuniu` 路由
- `lib/domain/lan/entities/room_info.dart` + `.g.dart` — 添加 `GameType.niuniu`
- `lib/presentation/pages/home/home_provider.dart` — 状态改为 available
- `lib/presentation/pages/home/home_page.dart` — `_supportsOnline` 加入 niuniu
- `lib/presentation/pages/room/room_lobby_page.dart` — niuniu 分支
- `lib/presentation/pages/room/game_rules_page.dart` — niuniu 规则文本
