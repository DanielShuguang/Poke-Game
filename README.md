# Poke Game

一个基于 Flutter 开发的跨平台扑克游戏合集应用，目前实现了斗地主游戏。

## 功能特性

### 斗地主游戏

- 完整的斗地主游戏流程：发牌 → 叫地主 → 出牌 → 判断胜负
- 智能 AI 对手，具备叫地主和出牌策略
- 支持多种牌型：单张、对子、三张、顺子、连对、飞机、炸弹、火箭等
- 人机对战模式：确保至少一人叫地主
- 拖拽选牌功能
- 提示功能：智能推荐出牌

### 平台支持

- Android
- iOS
- Web
- Windows
- macOS
- Linux

### 技术特性

- 高性能本地数据存储（Hive）
- 响应式状态管理（flutter_riverpod）
- 声明式路由（GoRouter）
- 屏幕适配（FlutterScreenUtil）
- Material 3 设计风格

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
├── main.dart                          # 应用入口
├── core/                              # 核心功能
│   └── router/                        # 路由配置
├── data/                              # 数据层
│   └── doudizhu/
│       ├── models/                    # 数据模型
│       └── repositories/              # 仓库实现
├── domain/                            # 业务逻辑层
│   ├── doudizhu/                      # 斗地主游戏
│   │   ├── entities/                  # 实体定义
│   │   ├── usecases/                  # 业务用例
│   │   ├── validators/                # 牌型验证
│   │   ├── ai/                        # AI 逻辑
│   │   └── repositories/              # 仓库接口
│   └── game/                          # 通用游戏实体
└── presentation/                      # 表现层
    ├── pages/
    │   ├── home/                      # 首页
    │   ├── doudizhu/                  # 斗地主游戏页面
    │   └── settings/                  # 设置页面
    └── widgets/                       # 通用组件
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.6.1+ |
| 状态管理 | flutter_riverpod |
| 不可变数据 | freezed |
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
flutter test test/domain/doudizhu/validators/card_validator_test.dart

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
| flutter_riverpod | ^2.6.1 | 状态管理 |
| freezed_annotation | ^2.4.4 | 不可变数据类 |
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
| freezed | ^2.5.7 | 不可变数据类 |
| hive_generator | ^2.0.1 | Hive 适配器生成 |
| mocktail | ^1.0.4 | 测试 Mock |
| flutter_lints | ^5.0.0 | 代码规范 |

## 游戏截图

> 待添加

## 开发计划

- [ ] 德州扑克游戏
- [ ] 多人对战模式
- [ ] 游戏记录与统计
- [ ] 自定义主题

## License

MIT License
