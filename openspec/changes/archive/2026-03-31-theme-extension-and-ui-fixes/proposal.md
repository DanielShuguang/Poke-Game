## 为什么

`GameColors` 当前是静态常量类，无法感知 `ThemeMode` 切换，导致所有游戏页面颜色固定为深色，设置中的主题切换形同虚设；同时升级游戏（shengji）、局域网大厅、设置页面仍残留大量白色背景卡牌和硬编码颜色（`Colors.teal`、`Colors.red`、`Colors.grey` 等），整体视觉不统一。

## 变更内容

- **重构** `GameColors` 为 `ThemeExtension<GameColors>`，提供 `dark` 和 `light` 两套静态实例，在 `main.dart` 的 `theme`/`darkTheme` 中注册
- **新增** `BuildContext` 扩展方法 `context.gameColors`，全局访问当前主题色
- **新增** 浅色主题配色方案（bgBase、bgSurface、bgTable、卡牌色、状态色等）
- **新增** 6 个状态/语义色字段：`statusInfoColor`、`statusInfoBg`、`statusErrorBg`、`statusSuccessBg`、`accentAmberBg`、`teamColor`、`overlay`、`progressTrackBg`
- **修改** 升级游戏（shengji_page.dart）：卡牌改为深色渐变样式，替换所有硬编码颜色
- **修改** card_hand.dart：`_buildCard` 接收 `BuildContext` 以获取主题色
- **修改** 首页和公共组件（home_page.dart、game_card_widget.dart、game_back_button.dart、playing_card_widget.dart）：`GameColors.xxx` → `context.gameColors.xxx`
- **修改** 各游戏页面（blackjack、niuniu、holdem、zhajinhua、doudizhu）：迁移到 `context.gameColors`，修复残留硬编码颜色
- **修改** 局域网页面（room_scan_page.dart、room_lobby_page.dart、game_rules_page.dart）：替换状态色硬编码
- **修改** 设置页面（settings_page.dart）：统一颜色风格

保留向后兼容：`GameColors.bgBase` 等静态常量继续存在（实际等于 `GameColors.dark.bgBase`），减少非 BuildContext 场景的迁移工作。

## 功能 (Capabilities)

### 新增功能

- `theme-extension`: 将 `GameColors` 重构为 `ThemeExtension`，支持深色/浅色两套主题，通过 `context.gameColors` 访问

### 修改功能

（无规范级行为变更，以下为实现层修改）

## 影响

**代码文件（约 15 个）：**
- `lib/presentation/shared/game_colors.dart`（核心重构）
- `lib/main.dart`（注册 extensions）
- `lib/presentation/pages/home/home_page.dart`
- `lib/presentation/widgets/game_card_widget.dart`（路径待确认）
- `lib/presentation/shared/game_back_button.dart`（路径待确认）
- `lib/presentation/widgets/playing_card_widget.dart`（路径待确认）
- `lib/presentation/pages/blackjack/blackjack_page.dart`
- `lib/presentation/pages/niuniu/niuniu_page.dart`
- `lib/presentation/pages/doudizhu/doudizhu_game_page.dart`
- `lib/presentation/pages/texas_holdem/holdem_game_page.dart`
- `lib/presentation/pages/zhajinhua/zhajinhua_page.dart`
- `lib/presentation/pages/shengji/shengji_page.dart`
- `lib/presentation/pages/shengji/widgets/card_hand.dart`
- `lib/presentation/pages/room/room_scan_page.dart`
- `lib/presentation/pages/room/room_lobby_page.dart`
- `lib/presentation/pages/room/game_rules_page.dart`
- `lib/presentation/pages/settings/settings_page.dart`

**依赖：** 无新增 pub 依赖，仅使用 Flutter 内置 `ThemeExtension` 机制。

**破坏性变更：** 无。静态常量保持兼容，`context.gameColors` 为新增访问方式。
