## 上下文

当前项目中 7 款游戏的超时托管时长统一硬编码为 35 秒：
- **NetworkAdapter 层**：每个 `XxxNetworkAdapter._resetTimeout()` 中 `Timer(const Duration(seconds: 35), ...)`
- **页面倒计时层**：跑得快 `paodekai_page.dart` 和升级 `shengji_page.dart` 的 `_startCountdown()` 中 `_countdown = 35`
- **掼蛋**：`GuandanNetworkAdapter` 有 35 秒超时托管，但游戏页面无倒计时 UI
- **其余 5 款游戏**（斗地主、德州扑克、炸金花、21点、斗牛）：NetworkAdapter 有 35 秒超时，页面各自有不同的倒计时实现（斗地主用 `TurnCountdownBar` 组件，德州用 `_CountdownBar`）

创建房间时 `gameConfig` 字段为空 `{}`，未承载任何配置。

## 目标 / 非目标

**目标：**
1. 掼蛋游戏页面添加出牌倒计时 UI（参考跑得快已有实现）
2. 创建房间页面新增「回合时限」选项，写入 `gameConfig['turnTimeLimit']`
3. 所有 NetworkAdapter 和页面倒计时从 `gameConfig` 读取时限，替代硬编码 35 秒
4. 单机模式使用默认 35 秒（无 gameConfig 时）

**非目标：**
- 不改变各游戏页面倒计时的 UI 风格（各游戏保留各自现有的倒计时组件样式）
- 不新增暂停/恢复倒计时功能
- 不修改 AI 出牌速度

## 决策

### 1. 配置传递方式：通过 `gameConfig` Map 传递

**选择**：在 `Room.gameConfig` 中新增 `turnTimeLimit` 整型字段（秒数）。

**替代方案**：
- A) 在 `Room` 实体新增顶层字段 `turnTimeLimit` → 需改 Room 类 + 序列化，侵入性更强
- B) 通过 `gameConfig` Map → 零侵入，`gameConfig` 本就为此设计，各适配器按需读取

**理由**：方案 B 不需要修改 Room 实体和序列化代码，`gameConfig` 已是 `Map<String, dynamic>` 类型，天然支持扩展。

### 2. 掼蛋倒计时实现方式：页面层 Timer（与跑得快/升级一致）

**选择**：在 `GuandanGamePage` 的 State 中新增 `_countdown` / `_countdownTimer`，参考 `paodekai_page.dart` 的模式。

**理由**：跑得快和升级已用此模式验证过，保持一致降低维护成本。掼蛋还需处理进贡/还贡阶段的倒计时。

### 3. 时限选项：固定 4 档 [15, 25, 35, 60]

**选择**：创建房间页面提供 4 个预设选项，默认 35 秒。

**理由**：覆盖快节奏（15s）到慢节奏（60s）场景，预设选项比自由输入更易操作。

### 4. 适配器获取配置的方式：构造参数 `turnTimeLimit`

**选择**：在各 `XxxNetworkAdapter` 构造函数新增 `int turnTimeLimit = 35` 参数。

**替代方案**：
- A) 从 notifier 的 state 中读取 → 耦合 state 结构
- B) 构造参数 → 简洁明确，遵循现有适配器参数风格

**理由**：方案 B 与现有的 `isHost`、`localPlayerId` 等参数风格一致。

### 5. 单机模式传递配置：页面构造参数 `turnTimeLimit`

**选择**：所有游戏页面新增 `int turnTimeLimit = 35` 可选参数。单机模式使用默认值 35 秒；联机模式从 `gameConfig` 读取后传入。

## 风险 / 权衡

- **[风险] 改动文件多（~15 个文件）** → 每个文件改动很小（替换硬编码常量），可逐个验证
- **[风险] 联机模式客户端可能看不到 gameConfig** → Host 在创建游戏时通过 `navigateToGame` 读取 `room.gameConfig`，已有机制传递；Client 通过状态同步获取
- **[权衡] 各游戏页面倒计时实现不统一** → 当前各游戏已有不同实现，本次不做统一重构，仅保证行为一致（读取相同配置值）
