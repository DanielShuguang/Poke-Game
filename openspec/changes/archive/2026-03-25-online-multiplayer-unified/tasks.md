## 1. 创建房间：移除游戏类型限制 + 动态人数

- [x] 1.1 修改 `create_room_page.dart`：将 `isAvailable = type == GameType.doudizhu` 改为 `isAvailable = true`，移除"该游戏暂未开放"提示文本
- [x] 1.2 为 `CreateRoomFormData` 新增 `maxPlayers: int` 字段，默认值为所选游戏类型的 `maxPlayerCount`
- [x] 1.3 修改 `_buildPlayerCountInfo`：斗地主显示"固定 3 人"文本，德州扑克/炸金花显示 `Slider`（范围来自 `GameType.minPlayerCount/maxPlayerCount`）
- [x] 1.4 切换游戏类型时重置 `maxPlayers` 为新类型的 `maxPlayerCount`
- [x] 1.5 创建房间时将 `maxPlayers` 传入 `Room`/`RoomInfo` 的 `maxPlayerCount` 字段

## 2. 主页：游戏卡片新增联机入口

- [x] 2.1 修改主页游戏卡片 Widget，为德州扑克和炸金花卡片新增"联机对战" `TextButton`
- [x] 2.2 "联机对战"按钮点击时携带 `gameType` query 参数导航至 `/room-scan`（例：`/room-scan?gameType=texasHoldem`）
- [x] 2.3 修改 `RoomScanPage`：读取 `gameType` 参数，过滤房间列表仅显示对应游戏类型的房间（参数为空时显示全部）

## 3. 德州扑克：完成联机状态同步

- [x] 3.1 为 `HoldemGameState` 实现 `toJson()` 方法，序列化 phase、players、pot、currentBet、currentPlayerIndex、communityCards
- [x] 3.2 为 `HoldemGameState` 实现 `fromJson()` 静态方法，对应字段提供默认值防止缺失
- [x] 3.3 补全 `HoldemNetworkAdapter._handleStateSyncFromHost`：调用 `HoldemGameState.fromJson` 并通过 notifier 更新状态
- [x] 3.4 为 `HoldemGamePage` 新增 `isOnline: bool` 和 `networkAdapter: HoldemNetworkAdapter?` 构造参数
- [x] 3.5 联机模式下非本地玩家回合时禁用操作按钮；Client 点击操作时调用 `networkAdapter.sendAction` 而非直接调用 notifier

## 4. 炸金花：新增联机网络适配层

- [x] 4.1 新建 `lib/domain/zhajinhua/entities/zhj_network_action.dart`，定义 `ZhjNetworkAction`（playerId、actionType: peek/call/raise/fold/showdown、targetPlayerIndex?）及消息类型常量
- [x] 4.2 为 `ZhjGameState` 实现 `toJson()` 方法，序列化 pot、currentBet、players（含 chips/isFolded/hasPeeked，手牌仅 Host 广播时含全量）
- [x] 4.3 为 `ZhjGameState` 实现 `fromJson()` 静态方法，客户端接收时非本地玩家手牌置为空列表
- [x] 4.4 新建 `lib/core/network/zhj_network_adapter.dart`，实现 `ZhjNetworkAdapter`（与 `HoldemNetworkAdapter` 相同接口：`incomingStream`、`broadcastFn`、`isHost`、`localPlayerId`）
- [x] 4.5 实现 `ZhjNetworkAdapter._handleActionFromClient`：验证当前回合玩家，执行行动，广播新状态
- [x] 4.6 实现 `ZhjNetworkAdapter._handleStateSyncFromHost`：反序列化状态并更新 notifier
- [x] 4.7 实现行动超时：Host 监听当前玩家 ID 变化，35 秒未收到行动则代为弃牌并广播

## 5. 炸金花：联机 UI 分支

- [x] 5.1 为 `ZhajinhuaPage` 新增 `isOnline: bool` 和 `networkAdapter: ZhjNetworkAdapter?` 构造参数
- [x] 5.2 联机模式下非本地玩家回合时，`ZhjBettingPanel` 禁用所有按钮并显示"等待其他玩家操作"
- [x] 5.3 联机模式下 Client 玩家点击操作按钮时，调用 `networkAdapter.sendAction`；Host 玩家直接执行本地行动并触发广播

## 6. 房间大厅：开始游戏路由扩展

- [x] 6.1 修改 `RoomLobbyPage` 的开始游戏逻辑：根据 `room.gameType` 路由至对应游戏页面（`texasHoldem` → `HoldemGamePage(isOnline: true)`，`zhajinhua` → `ZhajinhuaPage(isOnline: true)`）
- [x] 6.2 创建游戏 notifier 时使用房间分配的 `PlayerIdentity.id` 作为本地玩家 ID，确保与网络适配器 ID 匹配
- [x] 6.3 Host 在开始游戏时初始化并启动对应的 NetworkAdapter，传入 WebSocket `incomingStream` 和 `broadcastFn`

## 7. 验证

- [x] 7.1 `flutter analyze` 无新增错误
- [ ] 7.2 在模拟器上验证：创建德州扑克房间 → 人数 Slider 可调 → 房间创建成功
- [ ] 7.3 在模拟器上验证：创建炸金花房间 → 人数 Slider 可调（2-5 人）→ 房间创建成功
- [ ] 7.4 在模拟器上验证：主页炸金花/德州扑克卡片显示"联机对战"按钮，点击进入房间扫描页
- [ ] 7.5 双设备验证：炸金花联机完整对局（发牌→下注→看牌→弃牌/比牌→结算）
