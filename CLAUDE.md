# CLAUDE.md

## 项目概述

`poke_game` 是一个 Flutter 跨平台扑克游戏合集应用，目前实现了斗地主游戏，支持 Android、iOS、Web、Windows、macOS 和 Linux 平台。

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.6.1+ |
| 语言 | Dart 3.6.1+ |
| 状态管理 | flutter_riverpod |
| 不可变数据 | freezed_annotation |
| 网络请求 | Dio |
| 本地存储 | Hive + SharedPreferences |
| 路由 | GoRouter |
| 屏幕适配 | FlutterScreenUtil |

## 项目结构

```
lib/
├── main.dart                          # 应用入口
├── core/                              # 核心功能
│   └── router/                        # 路由配置
│       └── app_router.dart
├── data/                              # 数据层
│   └── doudizhu/
│       ├── models/                    # 数据模型
│       └── repositories/              # 仓库实现
├── domain/                            # 业务逻辑层
│   ├── doudizhu/                      # 斗地主游戏
│   │   ├── entities/                  # 实体（Card, Player, GameState 等）
│   │   ├── usecases/                  # 用例（发牌、叫地主、出牌、判断胜负）
│   │   ├── validators/                # 牌型验证器
│   │   ├── ai/                        # AI 玩家逻辑
│   │   │   ├── ai_player.dart
│   │   │   └── strategies/            # AI 策略（叫地主、出牌）
│   │   └── repositories/              # 仓库接口
│   └── game/                          # 通用游戏实体
│       └── entities/
│           └── game_info.dart
└── presentation/                      # 表现层
    ├── pages/
    │   ├── home/                      # 首页
    │   ├── doudizhu/                  # 斗地主游戏页面
    │   │   ├── doudizhu_game_page.dart
    │   │   ├── doudizhu_notifier.dart # Riverpod Notifier
    │   │   ├── doudizhu_state.dart    # UI 状态
    │   │   ├── doudizhu_provider.dart # Provider 定义
    │   │   └── widgets/               # 游戏组件
    │   └── settings/                  # 设置页面
    └── widgets/                       # 通用组件
        └── playing_card_widget.dart
```

## 游戏功能模块

### 斗地主（Doudizhu）

核心文件位于 `lib/domain/doudizhu/` 和 `lib/presentation/pages/doudizhu/`。

#### 实体层（entities）

| 文件 | 说明 |
|------|------|
| `card.dart` | 扑克牌实体（花色、点数、大小王） |
| `player.dart` | 玩家接口（手牌、角色、决策方法） |
| `game_state.dart` | 游戏状态（阶段、玩家、当前出牌等） |
| `game_config.dart` | 游戏配置（玩家数量、AI延迟、人机模式等） |
| `game_event.dart` | 游戏事件定义 |

#### 用例层（usecases）

| 文件 | 说明 |
|------|------|
| `deal_cards_usecase.dart` | 发牌逻辑（54张牌分发给3个玩家+3张底牌） |
| `call_landlord_usecase.dart` | 叫地主逻辑（支持人机/非人机模式） |
| `play_cards_usecase.dart` | 出牌逻辑（验证牌型、比较大小） |
| `check_winner_usecase.dart` | 判断胜负逻辑 |

#### 验证器（validators）

`card_validator.dart` - 牌型验证，支持：
- 单张、对子、三张、三带一/二、顺子、连对、飞机、炸弹、火箭等

#### AI 策略（ai/strategies）

| 文件 | 说明 |
|------|------|
| `call_strategy.dart` | 叫地主决策策略 |
| `play_strategy.dart` | 出牌决策策略（智能选牌、拆牌逻辑） |

### 游戏配置

`GameConfig` 支持两种模式：
- **人机模式**（`isHumanVsAi: true`）：玩家不叫时，最后一个AI必须叫地主
- **非人机模式**（`isHumanVsAi: false`）：全部不叫时重新发牌

## 开发规范

### 代码风格

- 使用 `flutter analyze` 进行静态分析
- 遵循 Effective Dart 规范
- 文件命名：snake_case
- 类命名：PascalCase
- 变量/方法命名：camelCase
- 常量命名：camelCase 或 SCREAMING_SNAKE_CASE

### 状态管理

使用 flutter_riverpod 进行状态管理：

```dart
// 定义 Provider
final doudizhuProvider =
    StateNotifierProvider.autoDispose<DoudizhuNotifier, DoudizhuUiState>(
  (ref) => DoudizhuNotifier(),
);

// 在 Widget 中使用
class GamePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doudizhuProvider);
    final notifier = ref.read(doudizhuProvider.notifier);
    // ...
  }
}
```

### 网络请求

使用 Dio 进行网络请求，建议封装为 Repository：

```dart
class ApiRepository {
  final Dio _dio;

  Future<T> request<T>(String path, {Map<String, dynamic>? params}) async {
    final response = await _dio.get(path, queryParameters: params);
    return response.data as T;
  }
}
```

### 本地存储

- 简单键值对：SharedPreferences
- 复杂数据：Hive（需生成 TypeAdapter）

```dart
// Hive 使用示例
await Hive.initFlutter();
Hive.registerAdapter(GameDataAdapter());
var box = await Hive.openBox<GameData>('game_box');
await box.put('current', gameData);
```

## 常用命令

```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run

# 构建 APK（Release）
flutter build apk --release

# 构建 iOS（Release）
flutter build ios --release

# 构建 Web
flutter build web --release

# 代码分析
flutter analyze

# 运行测试
flutter test

# 代码生成（JSON 序列化、Hive Adapter、Freezed）
flutter pub run build_runner build --delete-conflicting-outputs

# 清理构建缓存
flutter clean
```

## 依赖说明

### 运行依赖

| 包名 | 用途 |
|------|------|
| flutter_riverpod | 状态管理（Riverpod） |
| freezed_annotation | 不可变数据类注解 |
| dio | HTTP 客户端，支持拦截器、缓存等 |
| hive_flutter | 高性能 NoSQL 本地数据库 |
| shared_preferences | 轻量级键值存储 |
| go_router | 声明式路由管理 |
| flutter_screenutil | 屏幕尺寸适配 |
| cached_network_image | 网络图片缓存加载 |
| uuid | 唯一标识符生成 |
| intl | 国际化与日期格式化 |
| logger | 结构化日志输出 |
| json_annotation | JSON 序列化注解 |

### 开发依赖

| 包名 | 用途 |
|------|------|
| build_runner | 代码生成工具 |
| json_serializable | JSON 序列化代码生成 |
| freezed | 不可变数据类代码生成 |
| hive_generator | Hive TypeAdapter 生成 |
| mocktail | 单元测试 Mock 库 |
| flutter_lints | Flutter 代码规范检查 |

## Git 工作流

- 主分支：master
- 提交格式：`type(scope): description`
  - feat: 新功能
  - fix: 修复 Bug
  - refactor: 重构
  - docs: 文档更新
  - test: 测试相关
  - chore: 构建/工具相关

## 注意事项

1. **平台差异**：开发时注意各平台特性差异，特别是文件路径、权限等
2. **性能优化**：使用 `const` 构造函数、避免不必要的 rebuild
3. **资源管理**：图片资源放置在 `assets/` 目录，并在 `pubspec.yaml` 中声明
4. **异步处理**：使用 `async/await`，避免回调地狱
5. **内存泄漏**：注意 Stream、Controller 的释放，在 `dispose()` 中关闭
6. **横屏游戏**：斗地主游戏页面使用横屏模式，需在 `initState` 中设置屏幕方向
