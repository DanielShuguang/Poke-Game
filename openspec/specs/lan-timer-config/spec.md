## ADDED Requirements

### 需求：创建房间时配置回合时限
创建房间页面必须提供「回合时限」配置项，选项为 15 秒、25 秒、35 秒（默认）、60 秒。选定值必须以 `turnTimeLimit` 键存入 `Room.gameConfig`。

#### 场景：默认选中 35 秒
- **当** 用户进入创建房间页面
- **那么** 回合时限默认选中 35 秒

#### 场景：用户选择 15 秒
- **当** 用户将回合时限改为 15 秒并创建房间
- **那么** 创建的 Room 对象 `gameConfig['turnTimeLimit']` 值为 15

#### 场景：无倒计时配置时使用默认值
- **当** `gameConfig` 中不含 `turnTimeLimit` 键（旧版兼容）
- **那么** 所有读取方必须使用默认值 35 秒

### 需求：NetworkAdapter 读取可配置超时时长
所有游戏的 NetworkAdapter 构造函数必须新增 `int turnTimeLimit = 35` 参数。Host 端超时 Timer 必须使用此参数值替代硬编码 35 秒。

#### 场景：使用默认时限
- **当** NetworkAdapter 未传入 turnTimeLimit
- **那么** 超时 Timer 设为 35 秒

#### 场景：使用自定义时限
- **当** NetworkAdapter 传入 turnTimeLimit: 15
- **那么** 超时 Timer 设为 15 秒

#### 场景：覆盖所有 NetworkAdapter
- **当** 此需求实现完成
- **那么** 以下 7 个适配器必须全部支持 turnTimeLimit 参数：HoldemNetworkAdapter、ZhjNetworkAdapter、BlackjackNetworkAdapter、NiuniuNetworkAdapter、ShengjiNetworkAdapter、PdkNetworkAdapter、GuandanNetworkAdapter

### 需求：navigateToGame 传递时限配置
`game_navigation_helper.dart` 中的 `navigateToGame` 函数必须从 `room.gameConfig['turnTimeLimit']` 读取时限值，并传递给 NetworkAdapter 的 `turnTimeLimit` 参数和游戏页面的 `turnTimeLimit` 参数。

#### 场景：读取 gameConfig 中的时限
- **当** room.gameConfig 包含 `turnTimeLimit: 25`
- **那么** NetworkAdapter 和游戏页面均收到 turnTimeLimit = 25

#### 场景：gameConfig 中无时限配置
- **当** room.gameConfig 不包含 `turnTimeLimit` 键
- **那么** 使用默认值 35

### 需求：已有倒计时页面读取可配置时限
跑得快（PaodekaiPage）和升级（ShengjiPage）的 `_startCountdown()` 方法必须使用页面的 `turnTimeLimit` 参数替代硬编码 35 秒。两个页面必须新增 `int turnTimeLimit = 35` 可选构造参数。

#### 场景：跑得快使用自定义时限
- **当** 以 `PaodekaiPage(turnTimeLimit: 60)` 创建跑得快页面
- **那么** 倒计时初始值为 60 秒

#### 场景：升级使用自定义时限
- **当** 以 `ShengjiPage(turnTimeLimit: 15)` 创建升级页面
- **那么** 倒计时初始值为 15 秒

### 需求：其余游戏页面接受 turnTimeLimit 参数
斗地主、德州扑克、炸金花、21点、斗牛游戏页面必须新增 `int turnTimeLimit = 35` 可选构造参数，并将其传递给各自的倒计时机制。

#### 场景：德州扑克使用自定义时限
- **当** 以 `HoldemGamePage(turnTimeLimit: 25)` 创建德州扑克页面
- **那么** 行动倒计时初始值为 25 秒

#### 场景：所有游戏页面默认 35 秒
- **当** 不传入 turnTimeLimit 参数
- **那么** 所有游戏页面倒计时默认为 35 秒
