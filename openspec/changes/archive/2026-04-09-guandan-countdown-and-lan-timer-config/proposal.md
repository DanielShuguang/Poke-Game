## 为什么

掼蛋游戏当前缺少出牌倒计时功能，玩家可以在单机模式下无限等待，体验不佳。此外，局域网联机模式下所有游戏的超时时长硬编码为 35 秒，房主无法在创建房间时自定义此配置。跑得快和升级已有倒计时 UI，但掼蛋尚未实现；同时，所有游戏的倒计时时长均不可配置。

## 变更内容

1. **掼蛋游戏添加出牌倒计时 UI**：参考跑得快/升级已有实现，在掼蛋页面添加倒计时显示，单机模式超时自动托管（出最小牌/不出）
2. **创建房间时支持配置倒计时时长**：在创建房间页面新增倒计时时长选项（如 15/25/35/60 秒），存入 `gameConfig`
3. **所有游戏联机模式读取并应用倒计时配置**：NetworkAdapter 和游戏页面从 `gameConfig` 中读取超时时长，替代硬编码的 35 秒

## 功能 (Capabilities)

### 新增功能
- `guandan-countdown`: 掼蛋游戏出牌倒计时 UI 及单机模式超时自动托管
- `lan-timer-config`: 局域网创建房间时配置倒计时时长，所有游戏的 NetworkAdapter 和页面 UI 统一读取该配置

### 修改功能
<!-- 无规范级行为变更 -->

## 影响

- **掼蛋页面**：`lib/presentation/pages/guandan/guandan_game_page.dart` — 新增倒计时状态和 UI
- **创建房间页面**：`lib/presentation/pages/room/create_room_page.dart` — 新增倒计时时长选项
- **Room 实体**：`gameConfig` 字段需包含 `turnTimeLimit` 配置项
- **所有 NetworkAdapter**（7 个）：从 gameConfig 读取超时时长替代硬编码 35 秒
- **已有倒计时页面**（跑得快/升级）：从硬编码 35 秒改为读取配置值
- **掼蛋 NetworkAdapter**：`guandan_network_adapter.dart` — 读取配置的超时时长
