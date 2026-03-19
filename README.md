# Poke Game

一个基于 Flutter 开发的跨平台游戏应用。

## 功能特性

- 支持 Android、iOS、Web、Windows、macOS、Linux 多平台
- 高性能本地数据存储（Hive）
- 优雅的状态管理（Provider）
- 声明式路由（GoRouter）
- 响应式屏幕适配

## 环境要求

- Flutter SDK >= 3.6.1
- Dart SDK >= 3.6.1

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd poke_game
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行应用

```bash
flutter run
```

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── app/                   # 应用配置
│   ├── theme/             # 主题配置
│   ├── routes/            # 路由配置
│   └── constants/         # 常量定义
├── core/                  # 核心功能
│   ├── network/           # 网络封装
│   ├── storage/           # 存储封装
│   └── utils/             # 工具类
├── data/                  # 数据层
│   ├── models/            # 数据模型
│   ├── repositories/      # 数据仓库
│   └── datasources/       # 数据源
├── domain/                # 业务逻辑层
│   ├── entities/          # 实体
│   └── usecases/          # 用例
├── presentation/          # 表现层
│   ├── pages/             # 页面
│   ├── widgets/           # 组件
│   └── providers/         # 状态管理
└── di/                    # 依赖注入
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter |
| 状态管理 | Provider |
| 网络请求 | Dio |
| 本地存储 | Hive / SharedPreferences |
| 路由 | GoRouter |
| 屏幕适配 | FlutterScreenUtil |

## 构建命令

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## 测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/widget_test.dart

# 生成测试覆盖率报告
flutter test --coverage
```

## 代码规范

项目使用 `flutter_lints` 进行代码规范检查：

```bash
# 静态分析
flutter analyze

# 自动格式化
dart format .
```

## 依赖列表

### 运行依赖

| 包名 | 版本 | 说明 |
|------|------|------|
| provider | ^6.1.2 | 状态管理 |
| dio | ^5.7.0 | HTTP 客户端 |
| hive_flutter | ^1.1.0 | 本地数据库 |
| shared_preferences | ^2.3.3 | 键值存储 |
| go_router | ^14.6.2 | 路由管理 |
| flutter_screenutil | ^5.9.3 | 屏幕适配 |
| cached_network_image | ^3.4.1 | 图片缓存 |
| uuid | ^4.5.1 | UUID 生成 |
| intl | ^0.20.1 | 国际化 |
| logger | ^2.5.0 | 日志工具 |
| json_annotation | ^4.9.0 | JSON 序列化 |

### 开发依赖

| 包名 | 版本 | 说明 |
|------|------|------|
| build_runner | ^2.4.13 | 代码生成 |
| json_serializable | ^6.8.0 | JSON 序列化 |
| hive_generator | ^2.0.1 | Hive 适配器生成 |
| mocktail | ^1.0.4 | 测试 Mock |

## License

MIT License
