## 新增需求

### 需求：系统必须提供牛牛网络适配层
系统必须提供 `NiuniuNetworkAdapter`，接受 `incomingStream`、`broadcastFn`、`notifier`、`isHost`、`localPlayerId` 参数，管理 Host/Client 消息路由。

#### 场景：Host 处理客户端行动
- **当** Host 收到类型为 `niuniu_action` 的消息
- **那么** 适配器必须验证 `playerId` 与当前等待下注的玩家一致，调用对应 notifier 方法，并广播新状态

#### 场景：Client 发送行动
- **当** Client 调用 `adapter.sendAction(action)`
- **那么** 适配器必须将行动序列化为 `{type: 'niuniu_action', payload: ...}` 并通过 `broadcastFn` 发送

#### 场景：Client 接收状态同步
- **当** Client 收到类型为 `niuniu_state` 的消息
- **那么** 适配器必须调用 `notifier.applyNetworkState(state)`，非本地玩家手牌在 showdown 前必须为空

### 需求：系统必须对超时下注的闲家执行自动最小下注
Host 必须为每位等待下注的闲家维护35秒超时计时器，超时后自动以最小面额（10筹码）替代下注。

#### 场景：下注超时
- **当** 距上一次状态更新已过35秒且仍有闲家未下注
- **那么** Host 必须代该闲家执行 `bet(playerId, 10)` 并广播状态，重置计时器

### 需求：系统必须在 showdown 阶段向所有玩家广播完整手牌
进入 showdown 阶段时，Host 必须广播包含全部玩家手牌的状态。

#### 场景：showdown 广播
- **当** 游戏进入 showdown 阶段
- **那么** Host 必须调用 `toJson(includeAllCards: true)` 并广播，所有 Client 必须能看到全部手牌
