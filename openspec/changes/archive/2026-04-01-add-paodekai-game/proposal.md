## 为什么

跑得快是中国最流行的扑克游戏之一，规则简单易上手（3 人平等竞技，先出完手牌获胜），与现有合集（斗地主/德州扑克/炸金花/21点/斗牛）形成差异互补，进一步丰富游戏品类，提升用户留存和活跃度。

## 变更内容

- 新增跑得快游戏（单机 AI 对战 + 局域网联机）
- 新增领域层：实体、用例、AI 策略、网络行动消息
- 新增表现层：横屏游戏页面及子组件
- 新增网络适配器：`PdkNetworkAdapter`（Host/Client 模式）
- 修改 7 处接入文件：GameType 枚举、路由、首页卡片、联机支持列表、大厅导航、规则页

## 功能 (Capabilities)

### 新增功能

- `paodekai-core`: 跑得快核心领域——牌型定义（单张/对子/三张/顺子/连对/飞机/飞机带翅膀/炸弹/王炸）、大小比较、胜负判定、游戏状态机
- `paodekai-ai`: 单机 AI 策略——出牌决策（优先消耗单牌对子，留炸弹压阵）、跟牌/不出判断
- `paodekai-network`: 局域网联机——`PdkNetworkAction` 消息格式、`PdkNetworkAdapter` Host/Client 适配器、超时托管（35s）
- `paodekai-ui`: 游戏页面——横屏布局、三方玩家座位、手牌展示、出牌区、操作按钮（出牌/过牌）、结算弹窗

### 修改功能

无（接入 7 处文件均为新增枚举值/分支，不改变已有行为）

## 影响

**领域层（新增）**
- `lib/domain/paodekai/` — entities / usecases / validators / ai / notifiers

**网络层（新增）**
- `lib/core/network/pdk_network_adapter.dart`

**表现层（新增）**
- `lib/presentation/pages/paodekai/` — 游戏主页面 + widgets

**接入文件（修改，共 7 处）**
1. `lib/domain/lan/entities/room_info.dart` — 新增 `GameType.paodekai`
2. `lib/domain/lan/entities/room_info.g.dart` / `room.g.dart` — 序列化映射
3. `lib/core/router/app_router.dart` — 注册 `/paodekai` 路由
4. `lib/presentation/pages/home/home_provider.dart` — 游戏卡片数据
5. `lib/presentation/pages/home/home_page.dart` — `_supportsOnline` 新增 `'paodekai'`
6. `lib/presentation/pages/room/room_lobby_page.dart` — `_navigateToGame` switch 分支
7. `lib/presentation/pages/room/game_rules_page.dart` — `_getRulesContent` switch 分支
