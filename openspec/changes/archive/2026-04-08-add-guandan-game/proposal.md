## 为什么

游戏合集目前已上线 6 款游戏，但缺少在江浙沪地区极为流行的掼蛋。掼蛋是升级的衍生变体，与项目现有技术架构高度契合，可复用局域网联机基础设施快速交付。

## 变更内容

- **新增** 掼蛋单机 AI 对战模式（4 人，两队，支持计算机控制 3 名对手）
- **新增** 掼蛋局域网联机模式（Host/Client 架构，4 人联机）
- **新增** 游戏进入口：首页卡片 + 局域网房间流程接入
- **修改** `GameType` 枚举新增 `guandan` 值（影响序列化映射）
- **修改** 路由、房间大厅、规则页面新增掼蛋分支

## 功能 (Capabilities)

### 新增功能

- `guandan-rules`: 掼蛋核心牌型定义与胜负判定——包括级牌百搭、同花顺炸弹、升级流程、贡牌/还贡规则
- `guandan-ai`: 单机 AI 策略——出牌决策、配合队友、炸弹时机判断
- `guandan-network`: 局域网联机适配器——行动消息格式、手牌隐藏、35 秒超时托管、贡牌阶段同步

### 修改功能

无（联机基础设施行为不变，仅新增游戏枚举分支）

## 影响

**领域层**
- 新增 `lib/domain/guandan/` 目录：实体（Card、Hand、GuandanGameState）、用例（ValidateHandUsecase、HintUsecase）、AI（GuandanAiStrategy）

**基础设施层**
- 新增 `lib/core/network/guandan_network_adapter.dart`
- 修改 `lib/domain/lan/entities/room_info.dart`（GameType 枚举）
- 修改 `lib/domain/lan/entities/room_info.g.dart` / `room.g.dart`（序列化映射）

**表示层**
- 新增 `lib/presentation/pages/guandan/`（游戏主页面、出牌区、手牌区）
- 修改 `core/router/app_router.dart`、`home_provider.dart`、`home_page.dart`、`room_lobby_page.dart`、`game_rules_page.dart`

**依赖**
- 无新增第三方依赖
