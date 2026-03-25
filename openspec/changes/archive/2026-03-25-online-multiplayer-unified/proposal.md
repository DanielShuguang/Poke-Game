## 为什么

目前联机（局域网）模式仅支持斗地主，而德州扑克和炸金花均已完成单机 AI 对战实现，但缺少联机对战入口。创建房间页面硬编码 `isAvailable = type == GameType.doudizhu`，导致其他游戏类型无法选择。同时，德州扑克和炸金花的人数为可变（2-9 人），现有房间配置 UI 尚未支持动态人数设置。

## 变更内容

- **开放创建房间时的游戏类型选择**：德州扑克、炸金花从"不可用"变为"可用"，移除硬编码限制
- **动态人数配置**：斗地主固定 3 人（禁用配置），德州扑克 2-9 人可调，炸金花 2-5 人可调
- **德州扑克联机对战**：实现联机游戏状态同步，复用 `holdem_network_adapter.dart` 基础设施，完成房主-玩家完整对战流程
- **炸金花联机对战**：新增 `zhj_network_adapter`，实现联机状态同步（下注、看牌、弃牌、比牌）
- **统一联机入口**：游戏选择主页的德州扑克卡片和炸金花卡片新增"联机对战"按钮，统一导航至房间大厅流程

## 功能 (Capabilities)

### 新增功能
- `zhajinhua-network`: 炸金花联机网络适配层——ZhjNetworkAdapter、联机状态同步协议、联机 UI 扩展

### 修改功能
- `game-selection`: 新增联机入口按钮，德州扑克/炸金花卡片支持进入联机大厅
- `room-management`: 创建房间支持德州扑克和炸金花游戏类型；动态人数配置（斗地主固定 3 人，德州扑克 2-9 人，炸金花 2-5 人）

## 影响

- `lib/presentation/pages/room/create_room_page.dart` — 移除游戏类型硬编码限制，新增动态人数 Slider/Stepper
- `lib/presentation/pages/home/` — 游戏卡片新增"联机对战"入口
- `lib/core/network/holdem_network_adapter.dart` — 完善德州扑克联机状态同步
- `lib/core/network/` — 新增 `zhj_network_adapter.dart`
- `lib/presentation/pages/texas_holdem/` — 联机模式 UI 分支
- `lib/presentation/pages/zhajinhua/` — 联机模式 UI 分支
- `lib/domain/lan/entities/room_info.dart` — GameType 枚举中 texasHoldem/zhajinhua 从"预留"变为正式支持
