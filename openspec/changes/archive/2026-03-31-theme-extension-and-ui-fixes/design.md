## 上下文

`GameColors` 目前是只包含静态常量的工具类。所有 Widget 通过 `GameColors.xxx` 直接访问颜色，绕过了 Flutter 的 `Theme` 体系。用户在设置中切换主题（浅色/深色/跟随系统）时，`MaterialApp` 的 `themeMode` 会正确更新，但游戏页面的颜色不变，因为它们读取的是静态常量而非主题感知数据。

此外，升级游戏（shengji）、局域网大厅、设置页面存在大量原始硬编码颜色（`Colors.white`、`Colors.teal`、`Colors.red`、`Colors.grey` 等），与其他游戏已统一的深色风格不一致。

## 目标 / 非目标

**目标：**
- `GameColors` 变为 `ThemeExtension<GameColors>`，在 `main.dart` 同时注册深色实例和浅色实例
- 全局提供 `context.gameColors` 扩展访问器，让任意 Widget 获取当前主题的颜色
- 迁移约 15 个文件，消除所有 `GameColors.staticField` 调用和游离 `Colors.xxx` 硬编码
- 升级游戏卡牌改为深色渐变（与其他游戏一致）
- 主题切换后所有页面颜色实时响应

**非目标：**
- 不修改游戏逻辑或状态管理
- 不引入新的 pub 依赖
- 不改变应用路由或局域网联机架构
- 不为每款游戏单独定制主题色（共用一套 `GameColors`）

## 决策

### 决策 1：使用 `ThemeExtension<T>` 而非 Riverpod Provider

**选择：** `ThemeExtension<GameColors>`

**理由：**
- `ThemeExtension` 与 `MaterialApp.themeMode` 天然联动，无需额外订阅
- `Theme.of(context).extension<GameColors>()` 是 Flutter 官方推荐的自定义主题色方案
- 避免在颜色数据上引入额外的状态管理层
- `BuildContext` 扩展方法 `context.gameColors` 调用比 `ref.watch(gameColorsProvider)` 更简洁

**备选方案：** Riverpod Provider —— 需要所有 Widget 持有 `WidgetRef`，包括 `StatelessWidget`，改造成本更高。

### 决策 2：保留向后兼容静态常量

**选择：** 在 `GameColors` 类中保留原有静态常量，但值改为指向 `GameColors.dark` 的对应字段

```dart
// 向后兼容（实际值等于深色主题）
static const Color bgBase = Color(0xFF0F0F0F); // == dark.bgBase
```

**理由：**
- 零风险迁移：不会因遗漏某个文件导致编译错误
- 可分批迁移：先改核心文件，其余文件逐步迁移
- 迁移完成后删除静态常量即可，不影响已迁移的代码

### 决策 3：`card_hand.dart` 的 `_buildCard` 添加 `BuildContext` 参数

**选择：** 改为 `Widget _buildCard(BuildContext context, ShengjiCard card, {bool isSelected})`

**理由：**
- `CardHand` 是 `StatelessWidget`，`build` 方法已有 `context`；向下传递成本极低
- 避免将 `CardHand` 改为 `ConsumerWidget` 仅为读取颜色

### 决策 4：`shengji_page.dart` 的 `_buildCardWidget` 改为实例方法使用 `context`

**选择：** `_buildCardWidget` 声明在 `State` 类中，直接通过 `context` getter 读取主题

**理由：**
- `shengji_page.dart` 的主页面是 `ConsumerStatefulWidget`，`State` 内可以直接用 `context`
- 不需要将方法改为顶级函数或传入额外参数

### 决策 5：新增颜色字段处理状态色和语义色

深色实例新增：`statusInfoColor`、`statusInfoBg`、`statusErrorBg`、`statusSuccessBg`、`accentAmberBg`、`teamColor`、`overlay`、`progressTrackBg`

**理由：** room_scan_page 和 doudizhu_page 使用了 `Colors.blue/green/red.shadeXXX` 做状态指示，需要对应的语义色替代。

## 风险 / 权衡

- **`const` 丢失**：用 `context.gameColors.cardBg1` 替换后，`LinearGradient` 不能再用 `const` 修饰。Widget 重建频率与之前相同（颜色来自 Theme，未额外监听），性能影响可忽略。→ 接受该权衡。
- **遗漏文件**：静态常量向后兼容，遗漏迁移的文件编译通过但颜色不会跟随主题切换。→ 迁移后运行 `flutter analyze` + `grep -r "GameColors\." lib/` 确认无残留。
- **`ThemeExtension` 未注册时的 fallback**：`Theme.of(context).extension<GameColors>()` 返回 `null`。→ 扩展方法加 `?? GameColors.dark` 兜底，确保不崩溃。

## 迁移计划

1. 重构 `game_colors.dart`，实现 `ThemeExtension<GameColors>`（保留静态常量）
2. 在 `main.dart` 的 `theme` 和 `darkTheme` 中各添加 `extensions: [GameColors.light]` / `extensions: [GameColors.dark]`
3. 按以下顺序迁移文件（每步均可独立提交）：
   - 公共组件：`game_back_button.dart`、`playing_card_widget.dart`、`game_card_widget.dart`
   - 首页：`home_page.dart`
   - 各游戏页面：`blackjack_page.dart`、`niuniu_page.dart`、`holdem_game_page.dart`、`zhajinhua_page.dart`、`doudizhu_game_page.dart`
   - 升级游戏：`shengji_page.dart`、`card_hand.dart`
   - 局域网+设置：`room_scan_page.dart`、`room_lobby_page.dart`、`game_rules_page.dart`、`settings_page.dart`
4. 迁移完成后删除向后兼容静态常量

**回滚：** 每步独立提交，任何时刻回滚单步不影响其他文件。

## 开放问题

无。
