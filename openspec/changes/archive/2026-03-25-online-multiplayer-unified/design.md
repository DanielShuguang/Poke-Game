## 上下文

项目已有完整的局域网房间基础设施（WebSocket、UDP 广播、NSD、HTTP 房间服务器），斗地主联机已跑通完整流程。德州扑克有 `HoldemNetworkAdapter` 但 `_handleStateSyncFromHost` 为空实现（注释标注"超出本期范围"）。炸金花无任何网络层。

创建房间页 `isAvailable = type == GameType.doudizhu` 是唯一阻断其他游戏类型联机的硬编码。`room_info.dart` 中 `GameType.texasHoldem` / `GameType.zhajinhua` 的 `fixedPlayerCount`、`minPlayerCount`、`maxPlayerCount` 已正确实现，无需修改。

## 目标 / 非目标

**目标：**
- 移除创建房间页的游戏类型限制，支持三种游戏类型选择
- `CreateRoomFormData` 新增 `maxPlayers: int` 字段，人数可调游戏显示 Slider
- 完成 `HoldemNetworkAdapter._handleStateSyncFromHost`：实现 `HoldemGameState.fromJson` 并调用 notifier 更新
- 新建 `ZhjNetworkAdapter`，复用与 `HoldemNetworkAdapter` 相同的 Host/Client 消息模式
- 主页游戏卡片新增"联机对战"按钮，导航至 `/room-scan`（并传递 `gameType` 参数过滤）

**非目标：**
- 互联网联机（仅局域网）
- 游戏内聊天扩展
- 断线重连
- 德州扑克/炸金花联机的 AI 托管（联机模式全部为真人玩家）

## 决策

### 1. 联机入口：新增"联机对战"按钮 vs 重构主页卡片导航

**选择**：在现有游戏卡片中新增"联机对战"文字按钮（`TextButton`），点击传参 `gameType` 跳转 `/room-scan?gameType=texasHoldem`。

**理由**：最小改动。卡片点击仍进入单机模式，联机作为次要操作入口清晰隔离，无需重构 `home_provider.dart` 的 `GameInfo` 数据结构。

**替代方案**：改造主页卡片为双按钮布局（"单机"+"联机"）——改动较大，且 21 点等未完成游戏无联机，处理逻辑更复杂。

### 2. 状态序列化：手写 `toJson/fromJson` vs code_gen

**选择**：手写 `HoldemGameState.toJson/fromJson` 和 `ZhjGameState.toJson/fromJson`。

**理由**：炸金花实体未使用 freezed（前期决策），德州扑克部分实体已用 freezed。引入 json_serializable 需要 build_runner，增加构建复杂度。联机状态字段数量有限，手写可控。

**替代方案**：jsonSerializable + build_runner——理论更健壮，但本次范围内不值得引入新的 code gen 依赖。

### 3. ZhjNetworkAdapter：复制 HoldemNetworkAdapter 结构

**选择**：新建 `ZhjNetworkAdapter`，与 `HoldemNetworkAdapter` 保持相同接口（`incomingStream`、`broadcastFn`、`isHost`、`localPlayerId`），消息类型前缀用 `zhj_`。

**理由**：两个游戏的行动集合不同（炸金花有 peek/showdown，德州扑克有 check/allIn），统一抽象会引入过多条件分支。接口一致即可，实现各自独立。

### 4. 创建房间人数配置：Slider

**选择**：可变人数游戏（德州扑克、炸金花）显示 `Slider`，范围来自 `GameType.minPlayerCount`/`maxPlayerCount`；斗地主显示纯文本"固定 3 人"。

**理由**：`Slider` 对触屏体验好，且 `GameType` 扩展方法已提供 min/max，无需额外硬编码。

### 5. 联机游戏状态分支：通过 `isOnline` 参数控制

**选择**：`ZhajinhuaPage` 和 `HoldemGamePage` 通过构造函数参数 `isOnline: bool` 和 `networkAdapter` 区分模式，不新建独立页面。

**理由**：联机与单机 UI 大部分相同，只有操作按钮的"是否允许交互"逻辑不同（非自己回合禁用）。已有的 notifier 方法可直接复用；网络适配器的 `sendAction` 只在 client 模式下需要注入。

## 风险 / 权衡

- **状态反序列化完整性** → `fromJson` 字段缺失会导致客户端状态错误。缓解：每个字段提供默认值，Host 广播完整状态而非增量 diff。
- **玩家 ID 映射** → 联机时房间玩家 `PlayerIdentity.id` 需要与游戏 notifier 内的 `player.id` 对应。缓解：创建游戏 notifier 时使用房间分配的 `playerId`，确保 Host 验证行动时 ID 匹配。
- **炸金花联机的手牌保密性** → Host 拥有全局状态，广播时需屏蔽其他玩家手牌（`cards: null` 或不包含）。缓解：序列化时对非本玩家手牌做过滤，或客户端忽略自己以外玩家的手牌数据。
- **人数 Slider 默认值** → 切换游戏类型时 `maxPlayers` 可能超出新游戏范围。缓解：切换 `gameType` 时重置 `maxPlayers = gameType.maxPlayerCount`。

## 迁移计划

1. 修改 `create_room_page.dart`（移除限制 + 新增 Slider）
2. 修改 `home_page` / 游戏卡片（新增联机按钮）
3. 实现 `HoldemGameState.toJson/fromJson`，补全 `HoldemNetworkAdapter._handleStateSyncFromHost`
4. 新建 `ZhjNetworkAdapter` + `ZhjGameState.toJson/fromJson` + `ZhjNetworkAction`
5. `ZhajinhuaPage` 新增 `isOnline` / `networkAdapter` 参数，联机模式下注入适配器
6. `HoldemGamePage` 同上
7. 房间大厅（`room_lobby_page`）开始游戏时，根据 `gameType` 路由到对应游戏页面，传入联机参数

无破坏性变更，单机流程不受影响。
