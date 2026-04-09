## 1. 创建房间配置

- [x] 1.1 在 `create_room_page.dart` 新增「回合时限」下拉选择器（选项：15/25/35/60 秒，默认 35），将选定值写入 `gameConfig['turnTimeLimit']`

## 2. 掼蛋倒计时 UI

- [x] 2.1 在 `GuandanGamePage` 新增 `int turnTimeLimit = 35` 可选构造参数
- [x] 2.2 在 `_GuandanGamePageState` 中新增 `_countdown`、`_countdownTimer` 状态变量，实现 `_startCountdown()`、`_stopCountdown()`、`_updateCountdown()` 方法（参考 `paodekai_page.dart`）
- [x] 2.3 在 build 中监听状态变化并调用 `_updateCountdown`，处理 playing/tribute/returnTribute 三种阶段
- [x] 2.4 在按钮区域上方添加倒计时标签 UI（`N 秒`，≤10 秒红色，>10 秒琥珀色）
- [x] 2.5 在出牌 `_onPlay`、不出 `_onPass`、进贡、还贡操作回调中调用 `_stopCountdown()`
- [x] 2.6 单机模式超时自动托管：倒计时归零时，出牌阶段调用 `forcePlayCards`/`forcePass`；进贡阶段自动选最大非鬼牌；还贡阶段自动选最小牌

## 3. NetworkAdapter 可配置超时

- [ ] 3.1 在 `GuandanNetworkAdapter` 构造函数新增 `int turnTimeLimit = 35` 参数，`_resetTimeout()` 中使用该参数替代硬编码 35
- [x] 3.2 在 `PdkNetworkAdapter` 构造函数新增 `int turnTimeLimit = 35` 参数，替代硬编码 35
- [x] 3.3 在 `ShengjiNetworkAdapter` 构造函数新增 `int turnTimeLimit = 35` 参数，替代硬编码 35
- [x] 3.4 在 `HoldemNetworkAdapter` 构造函数新增 `int turnTimeLimit = 35` 参数，替代硬编码 35
- [x] 3.5 在 `ZhjNetworkAdapter` 构造函数新增 `int turnTimeLimit = 35` 参数，替代硬编码 35
- [x] 3.6 在 `BlackjackNetworkAdapter` 构造函数新增 `int turnTimeLimit = 35` 参数，替代硬编码 35
- [x] 3.7 在 `NiuniuNetworkAdapter` 构造函数新增 `int turnTimeLimit = 35` 参数，替代硬编码 35

## 4. 游戏页面 turnTimeLimit 参数

- [x] 4.1 在 `PaodekaiPage` 新增 `int turnTimeLimit = 35` 构造参数，`_startCountdown()` 使用该值替代硬编码 35
- [x] 4.2 在 `ShengjiPage` 新增 `int turnTimeLimit = 35` 构造参数，`_startCountdown()` 使用该值替代硬编码 35
- [x] 4.3 在 `HoldemGamePage`、`ZhajinhuaPage`、`BlackjackPage`、`NiuniuPage`、`DoudizhuGamePage` 新增 `int turnTimeLimit = 35` 构造参数，传递给各自倒计时机制

## 5. navigateToGame 传递配置

- [x] 5.1 修改 `game_navigation_helper.dart` 中的 `navigateToGame()`：从 `room.gameConfig['turnTimeLimit']` 读取时限值（默认 35），传递给所有 NetworkAdapter 和游戏页面的 `turnTimeLimit` 参数

## 6. 验证

- [x] 6.1 运行 `flutter analyze` 确保零 issue
- [x] 6.2 运行现有测试确保无回归
