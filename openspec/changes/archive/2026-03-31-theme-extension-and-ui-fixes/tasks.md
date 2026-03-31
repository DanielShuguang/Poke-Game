## 1. 重构 GameColors 为 ThemeExtension

- [x] 1.1 将 `lib/presentation/shared/game_colors.dart` 改为 `class GameColors extends ThemeExtension<GameColors>`，添加 26 个 `final` 颜色字段（含新增 8 个语义色）、`const GameColors({...})` 构造函数、`static const GameColors dark` 深色实例、`static const GameColors light` 浅色实例、`copyWith` 方法、`lerp` 方法
- [x] 1.2 在 `game_colors.dart` 末尾添加 `extension GameColorsContext on BuildContext { GameColors get gameColors => Theme.of(this).extension<GameColors>() ?? GameColors.dark; }`
- [x] 1.3 保留原有静态常量（向后兼容）：在 `GameColors` 类中添加 `static const Color bgBase = Color(0xFF0F0F0F);` 等与原文件相同的静态常量
- [x] 1.4 在 `lib/main.dart` 添加 `import 'package:poke_game/presentation/shared/game_colors.dart';`，在 `theme:` 的 `ThemeData` 中添加 `extensions: const [GameColors.light]`，在 `darkTheme:` 中添加 `extensions: const [GameColors.dark]`
- [x] 1.5 运行 `flutter analyze` 确认无编译错误

## 2. 迁移公共组件

- [x] 2.1 迁移 `lib/presentation/shared/game_back_button.dart`：找出所有 `GameColors.xxx` 引用，替换为 `context.gameColors.xxx`（需要将 `GameBackButton` 改为接受 `BuildContext` 或确保其 `build` 方法中使用 `context`）
- [x] 2.2 迁移 `lib/presentation/widgets/playing_card_widget.dart`（或实际路径）：将所有 `GameColors.xxx` 替换为 `context.gameColors.xxx`，`const LinearGradient` 改为非 const
- [x] 2.3 迁移 `lib/presentation/widgets/game_card_widget.dart`（或实际路径）：将所有 `GameColors.xxx` 替换为 `context.gameColors.xxx`
- [x] 2.4 迁移 `lib/presentation/pages/home/home_page.dart`：将所有 `GameColors.xxx` 替换为 `context.gameColors.xxx`
- [x] 2.5 运行 `flutter analyze` 确认无错误

## 3. 迁移各游戏页面

- [x] 3.1 迁移 `lib/presentation/pages/blackjack/blackjack_page.dart`：将约 16 处 `GameColors.xxx` 替换为 `context.gameColors.xxx`，`const LinearGradient` 改为非 const
- [x] 3.2 迁移 `lib/presentation/pages/niuniu/niuniu_page.dart`：将约 15 处 `GameColors.xxx` 替换为 `context.gameColors.xxx`
- [x] 3.3 迁移 `lib/presentation/pages/texas_holdem/holdem_game_page.dart`：将约 2 处 `GameColors.xxx` 替换为 `context.gameColors.xxx`
- [x] 3.4 迁移 `lib/presentation/pages/zhajinhua/zhajinhua_page.dart` 及 `zhj_hand_widget.dart`：将所有 `GameColors.xxx` 替换为 `context.gameColors.xxx`
- [x] 3.5 修复 `lib/presentation/pages/doudizhu/doudizhu_game_page.dart`：将 `GameColors.xxx` 替换为 `context.gameColors.xxx`；替换 `Colors.red` → `context.gameColors.dangerRed`、`Colors.grey.shade600` → `context.gameColors.textSecondary`、`Colors.grey.shade300` → `context.gameColors.progressTrackBg`、`Colors.teal` → `context.gameColors.primaryGreen`（在 `_TurnCountdown` 内，注意 `_BlinkText` 是嵌套 `StatefulWidget`，其 `context` 可直接用）
- [x] 3.6 运行 `flutter analyze` 确认无错误

## 4. 修复升级游戏样式

- [x] 4.1 修改 `lib/presentation/pages/shengji/widgets/card_hand.dart`：将 `_buildCard(ShengjiCard card, ...)` 改为 `_buildCard(BuildContext context, ShengjiCard card, ...)`；调用处改为 `_buildCard(context, card, isSelected: isSelected)`；将所有 `GameColors.xxx` 替换为 `context.gameColors.xxx`；将 `const LinearGradient(colors: [GameColors.cardBg1, GameColors.cardBg2])` 改为使用 `context.gameColors.cardBg1/cardBg2` 的非 const 版本
- [x] 4.2 修复 `lib/presentation/pages/shengji/shengji_page.dart` 中的 `_buildCardWidget` 方法：将 `Colors.white` 背景改为 `cardBg1`→`cardBg2` 渐变，`Colors.black26` 边框改为 `cardBorderRed`/`cardBorderBlack`，文字颜色改为 `cardBorderRed`/`textPrimary`
- [x] 4.3 修复 `shengji_page.dart` 其他硬编码颜色：`Colors.black38`（将牌背景）→ `context.gameColors.overlay`、`Colors.white`（文字）→ `context.gameColors.textPrimary`、`Colors.red.shade700`（倒计时紧急）→ `context.gameColors.dangerRed`、`Colors.orange.shade700`（倒计时正常）→ `context.gameColors.accentAmber`、`Colors.white70`（座位文字）→ `context.gameColors.textSecondary`、`Colors.blue.shade700`（队友标签）→ `context.gameColors.teamColor`、`Colors.yellow`（当前玩家边框）→ `context.gameColors.accentAmber`
- [x] 4.4 运行 `flutter analyze` 确认无错误

## 5. 修复局域网和设置页面样式

- [x] 5.1 修复 `lib/presentation/pages/room/room_scan_page.dart`：网络状态横幅的蓝色（检测中）→ `statusInfoBg`/`statusInfoColor`，红色（错误）→ `statusErrorBg`/`dangerRed`，绿色（成功）→ `statusSuccessBg`/`primaryGreen`；房间状态筹码橙色（游戏中）→ `accentAmberBg`/`accentAmber`，绿色（可加入）→ `statusSuccessBg`/`primaryGreen`；`Colors.grey.*` → `textSecondary`/`bgSurface`
- [x] 5.2 修复 `lib/presentation/pages/room/room_lobby_page.dart`：等待中绿色状态 → `statusSuccessBg`/`primaryGreen`；空座位灰色 → `bgSurface`/`textSecondary`；房主琥珀色 → `accentAmber`/`accentAmberBg`；就绪绿色 → `primaryGreen`；玩家名文字 → `textPrimary`
- [x] 5.3 修复 `lib/presentation/pages/room/game_rules_page.dart`：替换所有硬编码颜色为 `context.gameColors.xxx`
- [x] 5.4 修复 `lib/presentation/pages/settings/settings_page.dart`：仅头像颜色选择器（用户数据色）和彩色背景上的白字，均为有意设计，无需修改
- [x] 5.5 运行 `flutter analyze` 确认全局 0 issues，并热重载验证深色/浅色主题切换后所有页面颜色正确响应
