# CLAUDE.md

## 项目概述

Flutter 跨平台扑克游戏合集，目前实现斗地主，支持 Android/iOS/Web/Windows/macOS/Linux。

## 技术栈

Flutter 3.6.1+ | flutter_riverpod | freezed_annotation | Dio | Hive + SharedPreferences | GoRouter | FlutterScreenUtil

## 项目结构

```
lib/
├── core/router/                    # 路由配置
├── data/doudizhu/                  # 数据层（models, repositories）
├── domain/doudizhu/                # 业务层
│   ├── entities/                   # Card, Player, GameState, GameConfig
│   ├── usecases/                   # 发牌、叫地主、出牌、判断胜负
│   ├── validators/                 # 牌型验证（card_validator.dart）
│   ├── ai/strategies/              # AI 策略（叫地主、出牌）
│   └── repositories/               # 仓库接口
└── presentation/pages/             # home, doudizhu, settings
```

## 斗地主核心模块

| 目录 | 核心文件 |
|------|----------|
| entities | card.dart, player.dart, game_state.dart, game_config.dart |
| usecases | deal_cards_usecase.dart, call_landlord_usecase.dart, play_cards_usecase.dart |
| validators | card_validator.dart（支持单张到火箭全部牌型） |
| ai | call_strategy.dart, play_strategy.dart |

## 游戏配置

`GameConfig.isHumanVsAi`:
- `true`（人机模式）：玩家不叫时，最后一个 AI 必须叫地主
- `false`（非人机模式）：全部不叫时重新发牌

## 开发规范

- 代码风格：`flutter analyze`，Effective Dart，snake_case 文件名，PascalCase 类名
- 状态管理：flutter_riverpod（StateNotifierProvider + ConsumerWidget）
- 提交格式：`type(scope): description`（feat/fix/refactor/docs/test/chore）

## 常用命令

```bash
flutter pub get                    # 安装依赖
flutter run                        # 运行应用
flutter test                       # 运行测试
flutter analyze                    # 代码分析
flutter build apk --release        # 构建 APK
flutter pub run build_runner build # 代码生成
```

## 注意事项

- 横屏游戏：斗地主页面需在 `initState` 设置屏幕方向
- 性能优化：使用 `const` 构造函数，避免不必要 rebuild
- 内存泄漏：在 `dispose()` 中释放 Stream/Controller
