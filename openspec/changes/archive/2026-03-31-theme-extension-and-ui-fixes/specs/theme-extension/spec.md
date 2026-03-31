## 新增需求

### 需求：GameColors 支持深色和浅色两套主题实例
`GameColors` 必须提供 `static const GameColors dark` 和 `static const GameColors light` 两个实例，分别对应深色和浅色配色方案。

#### 场景：访问深色主题颜色
- **当** 代码引用 `GameColors.dark.bgBase`
- **那么** 返回 `Color(0xFF0F0F0F)`（深色背景）

#### 场景：访问浅色主题颜色
- **当** 代码引用 `GameColors.light.bgBase`
- **那么** 返回 `Color(0xFFF5F5F5)`（浅色背景）

---

### 需求：GameColors 注册到 MaterialApp 主题
`main.dart` 中 `theme`（浅色）必须包含 `extensions: const [GameColors.light]`，`darkTheme`（深色）必须包含 `extensions: const [GameColors.dark]`。

#### 场景：浅色模式下 ThemeExtension 可访问
- **当** 用户切换到浅色模式，Widget 调用 `Theme.of(context).extension<GameColors>()`
- **那么** 返回 `GameColors.light` 实例（非 null）

#### 场景：深色模式下 ThemeExtension 可访问
- **当** 用户切换到深色模式，Widget 调用 `Theme.of(context).extension<GameColors>()`
- **那么** 返回 `GameColors.dark` 实例（非 null）

---

### 需求：BuildContext 扩展提供 gameColors 访问器
必须提供 `extension GameColorsContext on BuildContext` 扩展，使 `context.gameColors` 返回当前主题的 `GameColors` 实例；当 `ThemeExtension` 未注册时必须回退到 `GameColors.dark`。

#### 场景：主题已注册时返回正确实例
- **当** Widget 调用 `context.gameColors`
- **那么** 返回当前 `ThemeMode` 对应的 `GameColors` 实例

#### 场景：ThemeExtension 未注册时不崩溃
- **当** 某个 Widget 在未注册 `GameColors` 的 `MaterialApp` 下调用 `context.gameColors`
- **那么** 返回 `GameColors.dark`（fallback），不抛出异常

---

### 需求：GameColors 包含状态语义色字段
`GameColors` 必须包含以下新增字段：`statusInfoColor`、`statusInfoBg`、`statusErrorBg`、`statusSuccessBg`、`accentAmberBg`、`teamColor`、`overlay`、`progressTrackBg`。

#### 场景：深色模式状态色
- **当** 代码引用 `context.gameColors.statusInfoBg`（深色模式）
- **那么** 返回 `Color(0xFF1E3A5F)`（深蓝色背景）

#### 场景：浅色模式状态色
- **当** 代码引用 `context.gameColors.statusInfoBg`（浅色模式）
- **那么** 返回 `Color(0xFFDBEAFE)`（淡蓝色背景）

---

### 需求：所有游戏页面颜色跟随主题切换
所有游戏页面（斗地主、德州扑克、炸金花、21点、斗牛、升级）的颜色必须通过 `context.gameColors.xxx` 访问，禁止使用 `Colors.teal`、`Colors.red`、`Colors.grey`、`Colors.white`、`Colors.blue` 等硬编码颜色（游戏专有语义色除外，如底牌翻转动画）。

#### 场景：深色模式下游戏页背景
- **当** 应用切换为深色模式
- **那么** 所有游戏页面的 Scaffold 背景使用 `context.gameColors.bgTable`（`Color(0xFF1A2A1A)`）

#### 场景：浅色模式下游戏页背景
- **当** 应用切换为浅色模式
- **那么** 所有游戏页面的 Scaffold 背景使用 `context.gameColors.bgTable`（`Color(0xFF2D5016)`）

---

### 需求：升级游戏卡牌显示为深色渐变样式
升级游戏（shengji）的手牌和出牌区卡牌必须使用与其他游戏相同的深色渐变样式（`cardBg1` → `cardBg2` 渐变背景），禁止使用白色背景（`Colors.white`）。

#### 场景：红色花色卡牌样式
- **当** 显示 ♥ 或 ♦ 花色的升级游戏卡牌
- **那么** 卡牌背景为 `cardBg1`→`cardBg2` 渐变，文字颜色为 `cardBorderRed`，边框为 `cardBorderRed`

#### 场景：黑色花色卡牌样式
- **当** 显示 ♠ 或 ♣ 花色的升级游戏卡牌
- **那么** 卡牌背景为 `cardBg1`→`cardBg2` 渐变，文字颜色为 `textPrimary`，边框为 `cardBorderBlack`

---

### 需求：局域网和设置页面使用语义色替代硬编码
`room_scan_page.dart`、`room_lobby_page.dart`、`game_rules_page.dart`、`settings_page.dart` 中的 `Colors.blue.*`、`Colors.red.*`、`Colors.green.*`、`Colors.grey.*` 必须替换为 `context.gameColors` 对应的语义色字段。

#### 场景：扫描房间页网络状态横幅（检测中）
- **当** 局域网扫描正在进行
- **那么** 横幅背景使用 `statusInfoBg`，文字使用 `statusInfoColor`

#### 场景：扫描房间页网络状态横幅（错误）
- **当** 网络不可用
- **那么** 横幅背景使用 `statusErrorBg`，文字使用 `dangerRed`

#### 场景：扫描房间页网络状态横幅（成功）
- **当** 网络连接正常
- **那么** 横幅背景使用 `statusSuccessBg`，文字使用 `primaryGreen`

## 修改需求

（无现有规范级行为变更）

## 移除需求

（无）
