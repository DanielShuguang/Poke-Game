# CLAUDE.md

## 项目概述

Flutter 跨平台扑克游戏合集，已上线 6 款游戏（斗地主、德州扑克、炸金花、21点、斗牛、升级），全部支持单机 AI 对战与局域网联机对战，支持 Android/iOS/Web/Windows/macOS/Linux。

## 技术栈

Flutter 3.6.1+ | flutter_riverpod | freezed_annotation | Hive + SharedPreferences | GoRouter | FlutterScreenUtil

## 项目结构

```
lib/
├── core/
│   ├── router/                    # GoRouter 路由配置
│   └── network/                   # 各游戏网络适配器
├── domain/
│   ├── game/entities/             # GameInfo、GameTypeConfig
│   ├── lan/entities/              # Room、RoomInfo、GameType 枚举
│   ├── doudizhu/                  # 斗地主（entities/usecases/validators/ai）
│   ├── texas_holdem/              # 德州扑克
│   ├── zhajinhua/                 # 炸金花
│   ├── blackjack/                 # 21点
│   ├── niuniu/                    # 斗牛
│   └── shengji/                   # 升级
└── presentation/pages/
    ├── home/                      # 首页（游戏列表 + 局域网入口）
    ├── room/                      # 局域网（scan/create/lobby）
    ├── doudizhu/                  # 斗地主页面
    ├── texas_holdem/              # 德州扑克页面
    ├── zhajinhua/                 # 炸金花页面
    ├── blackjack/                 # 21点页面
    ├── niuniu/                    # 斗牛页面
    ├── shengji/                   # 升级页面
    └── settings/                  # 设置页面
```

## 局域网联机架构

**Host/Client 适配器模式**，每款游戏有对应的 `XxxNetworkAdapter`：

```
lib/core/network/
├── holdem_network_adapter.dart
├── zhj_network_adapter.dart
├── blackjack_network_adapter.dart
├── niuniu_network_adapter.dart
└── shengji_network_adapter.dart
```

适配器构造参数：`incomingStream`、`broadcastFn`、`notifier`、`isHost`、`localPlayerId`

- **Host**：接收行动消息 → 调用 notifier → 广播新状态
- **Client**：发送行动消息 → 等待状态同步
- 手牌隐私：`toJson(includeAllCards: false)` 在 showdown 前隐藏他人手牌
- 超时托管：Host 用 35s `Timer` 监听当前玩家，超时代为执行最小操作

**LobbyNotifier 暴露的网络接口**：
- `hostGameStream` → WebSocketManager.dataStream（Host 收消息）
- `clientGameStream` → WebSocketClient.messageStream（Client 收消息）
- `broadcastGameMessage(msg)` → Host 广播
- `sendGameMessage(msg)` → Client 发送

## 新增游戏接入清单

添加新游戏时需修改以下文件：

1. `domain/lan/entities/room_info.dart` — `GameType` 枚举 + 4 个 switch 分支
2. `domain/lan/entities/room_info.g.dart` / `room.g.dart` — 序列化映射
3. `core/router/app_router.dart` — 注册路由
4. `presentation/pages/home/home_provider.dart` — 游戏卡片数据
5. `presentation/pages/home/home_page.dart` — `_supportsOnline` 列表
6. `presentation/pages/room/room_lobby_page.dart` — `_navigateToGame()` switch 分支
7. `presentation/pages/room/game_rules_page.dart` — `_getRulesContent()` switch 分支

## UI 规范

**退出按钮**（所有游戏统一）：
- 位置：左上角
- 样式：`IconButton(icon: Icon(Icons.arrow_back, color: Colors.white70))`
- 行为：弹出确认对话框，确认后 `Navigator.pop(context)`

## 开发规范

- 代码风格：`flutter analyze`，Effective Dart，snake_case 文件名，PascalCase 类名
- 文件大小：单个 `.dart` 文件不超过 **500 行**；超出时拆分为职责单一的文件
- 函数长度：单个方法/函数不超过 **100 行**；超出时提取为私有辅助方法
- 状态管理：flutter_riverpod（StateNotifierProvider + ConsumerWidget）
- 提交格式：`type(scope): description`（feat/fix/refactor/docs/test/chore）

## 常用命令

```bash
flutter pub get                    # 安装依赖
flutter run                        # 运行应用
flutter test                       # 运行测试
flutter analyze                    # 代码分析（应保持 0 issues）
flutter build apk --release        # 构建 APK
flutter pub run build_runner build # 代码生成（freezed/json）
```

## 注意事项

- 横屏游戏：所有扑克游戏页面在 `initState` 锁定横屏，`dispose` 时恢复
- 性能优化：使用 `const` 构造函数，避免不必要 rebuild
- 内存泄漏：在 `dispose()` 中释放 Stream/Timer/Controller
- `GameType.niuniu` 对应游戏显示名为"斗牛"，但代码标识符保持 `niuniu`
