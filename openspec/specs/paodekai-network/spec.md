## 新增需求

### 需求：联机行动消息格式
系统必须定义 `PdkNetworkAction` 枚举，包含以下行动类型：`playCards`（出牌）、`pass`（不出）、`forcePlayCards`（超时强制出牌）、`forcePass`（超时强制 pass）。
消息格式必须遵循现有 `XxxNetworkAction` 模式，使用 JSON 序列化。

#### 场景：出牌消息
- **当** Client 执行出牌操作
- **那么** 发送 `{ type: "playCards", cards: [...] }` 到 Host

#### 场景：pass 消息
- **当** Client 选择不出
- **那么** 发送 `{ type: "pass" }` 到 Host

---

### 需求：PdkNetworkAdapter Host 行为
Host 端 `PdkNetworkAdapter` 必须监听 `incomingStream`，将收到的行动消息交给 `PdkNotifier` 执行，并将最新 `PdkGameState` 广播给所有客户端。
广播时必须使用 `toJson()` 序列化完整状态（跑得快无手牌隐私需求，所有玩家手牌均可见）。

#### 场景：Host 处理出牌消息
- **当** Host 收到 `playCards` 行动
- **那么** Host 调用 `notifier.playCards(...)` 更新状态，随后广播新状态

#### 场景：Host 广播完整状态
- **当** 状态发生任何变更
- **那么** Host 通过 `broadcastFn` 发送序列化的 `PdkGameState` JSON

---

### 需求：PdkNetworkAdapter Client 行为
Client 端 `PdkNetworkAdapter` 必须监听 `incomingStream` 接收 Host 广播的状态并更新本地 `PdkNotifier`，同时提供 `sendAction` 方法供 UI 调用。

#### 场景：Client 接收状态同步
- **当** Client 收到 Host 广播的状态 JSON
- **那么** Client 调用 `notifier.syncState(state)` 更新本地状态

#### 场景：Client 发送行动
- **当** 玩家操作触发出牌或 pass
- **那么** Client 通过 `sendGameMessage` 发送对应行动 JSON

---

### 需求：超时托管
Host 端必须为当前出牌玩家启动 35 秒计时器。超时后 Host 代为执行最小操作（优先 pass，若为起手方则出最小单张）。

#### 场景：超时强制 pass
- **当** 非起手玩家 35 秒内未操作
- **那么** Host 执行 `forcePass`，计时器重置

#### 场景：超时强制出牌
- **当** 起手玩家 35 秒内未操作
- **那么** Host 执行 `forcePlayCards` 出最小合法单张

## 修改需求

## 移除需求
