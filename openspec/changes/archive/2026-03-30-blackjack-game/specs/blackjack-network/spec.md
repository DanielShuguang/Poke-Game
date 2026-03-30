## 新增需求

### 需求：Host 必须广播完整游戏状态（隐藏庄家暗牌）
Host 每次状态变更后必须向所有 Client 广播 `BlackjackGameState`，庄家第二张牌在玩家行动阶段必须以 null 替代。

#### 场景：Host 广播含暗牌状态
- **当** 游戏处于玩家行动阶段，Host 调用 `_broadcastState()`
- **那么** 广播的 JSON 中庄家手牌列表第二个元素必须为 null（隐藏暗牌）

#### 场景：庄家行动阶段广播真实暗牌
- **当** 进入庄家行动阶段，Host 调用 `_broadcastState(includeAllCards: true)`
- **那么** 广播的 JSON 中庄家手牌必须包含真实暗牌数据

### 需求：Client 必须通过适配器发送行动
Client 玩家的所有行动（Hit / Stand / Double / Split / Surrender）必须通过 `BlackjackNetworkAdapter.sendAction()` 发送给 Host，不得直接修改本地状态。

#### 场景：Client 发送 Hit
- **当** Client 玩家点击 Hit
- **那么** 适配器必须发送 `{type: 'blackjack_action', action: 'hit', playerId: '...', handIndex: 0}` 给 Host

#### 场景：Client 收到状态同步
- **当** Host 广播新状态
- **那么** Client 适配器必须调用 `_notifier.applyNetworkState(newState)` 更新本地 UI

### 需求：Host 必须验证行动合法性后执行
Host 收到 Client 行动时，必须校验当前轮次、玩家 ID 和操作合法性，拒绝非法行动并记录日志。

#### 场景：非当前玩家发送行动
- **当** 轮到 player1 行动，但 player2 发送了 Hit
- **那么** Host 必须忽略该消息，不修改游戏状态

#### 场景：非法 Double（手牌超过两张）
- **当** 玩家已有 3 张牌却发送 Double 行动
- **那么** Host 必须拒绝执行，广播当前状态提示客户端刷新

### 需求：Host 必须对当前玩家执行 35 秒超时自动 Stand
Host 在每次轮到新玩家时必须启动 35 秒计时器，超时后代替该玩家执行 Stand（不是 Fold）。

#### 场景：玩家超时
- **当** 玩家 35 秒内未操作
- **那么** Host 必须代为执行 Stand，广播更新状态，计时器重置为下一位玩家

#### 场景：玩家及时操作取消计时
- **当** 玩家在 35 秒内发送任意合法行动
- **那么** Host 必须取消当前计时器，待行动处理完成后为下一位玩家重新计时
