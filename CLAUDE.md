# CLAUDE.md

## 项目概述

`poke_game` 是一个 Flutter 跨平台游戏应用，支持 Android、iOS、Web、Windows、macOS 和 Linux 平台。

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.6.1+ |
| 语言 | Dart |
| 状态管理 | Provider |
| 网络请求 | Dio |
| 本地存储 | Hive + SharedPreferences |
| 路由 | GoRouter |
| 屏幕适配 | FlutterScreenUtil |

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── app/                   # 应用配置（主题、路由、常量）
├── core/                  # 核心功能（网络、存储、工具类）
├── data/                  # 数据层（模型、仓库、数据源）
├── domain/                # 业务逻辑层（用例、实体）
├── presentation/          # 表现层（页面、组件、状态）
└── di/                    # 依赖注入
```

## 开发规范

### 代码风格

- 使用 `flutter analyze` 进行静态分析
- 遵循 Effective Dart 规范
- 文件命名：snake_case
- 类命名：PascalCase
- 变量/方法命名：camelCase
- 常量命名：camelCase 或 SCREAMING_SNAKE_CASE

### 状态管理

使用 Provider 进行状态管理：

```dart
// 定义 Model
class GameModel extends ChangeNotifier {
  int _score = 0;
  int get score => _score;

  void updateScore(int value) {
    _score = value;
    notifyListeners();
  }
}

// 在 Widget 中使用
Consumer<GameModel>(
  builder: (context, model, child) {
    return Text('Score: ${model.score}');
  },
)
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

# 代码生成（JSON 序列化、Hive Adapter）
flutter pub run build_runner build --delete-conflicting-outputs

# 清理构建缓存
flutter clean
```

## 依赖说明

### 运行依赖

| 包名 | 用途 |
|------|------|
| provider | 状态管理 |
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
| hive_generator | Hive TypeAdapter 生成 |
| mocktail | 单元测试 Mock 库 |

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
