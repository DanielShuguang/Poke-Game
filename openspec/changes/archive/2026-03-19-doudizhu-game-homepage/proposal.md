# Proposal: 游戏首页与斗地主游戏页

## Why

当前应用缺乏入口页面来展示游戏合集，用户无法直观浏览和选择想要游玩的游戏。同时，作为首个游戏模块，斗地主游戏的缺失使得应用缺乏核心玩法内容。

本次变更旨在：
1. 建立游戏首页，作为应用的主入口，展示所有可用及计划中的游戏
2. 实现斗地主游戏页面，作为首个可游玩的游戏模块

## What Changes

- **新增** 游戏首页页面，展示游戏列表（包含已上线、开发中、计划中的游戏）
- **新增** 斗地主游戏页面，支持人机对战模式
- **新增** 游戏路由配置，支持从首页跳转到各游戏页面
- **预留** 局域网对战架构扩展点，确保后续可无缝接入多人对战功能

## Capabilities

### New Capabilities

- `game-homepage`: 游戏首页能力，展示游戏合集列表，作为应用主入口
- `doudizhu-game`: 斗地主游戏能力，包含游戏核心逻辑、UI界面、AI对手、人机对战流程

### Modified Capabilities

无（本次为新增功能，不涉及既有能力修改）

## Impact

### 代码结构

```
lib/
├── presentation/
│   ├── pages/
│   │   ├── home/                    # 新增：首页模块
│   │   │   ├── home_page.dart
│   │   │   └── widgets/
│   │   └── doudizhu/                # 新增：斗地主游戏模块
│   │       ├── doudizhu_game_page.dart
│   │       ├── game_table_widget.dart
│   │       ├── player_hand_widget.dart
│   │       └── ...
│   └── widgets/                     # 共用组件
├── domain/
│   └── doudizhu/                    # 新增：斗地主业务逻辑
│       ├── entities/
│       ├── usecases/
│       └── ai/                      # AI 对手逻辑
└── data/
    └── doudizhu/                    # 新增：斗地主数据层
        ├── models/
        └── repositories/
```

### 架构扩展点

为局域网对战预留以下扩展点：
- `GameMode` 枚举：支持 `ai` / `lan` 模式切换
- `Player` 抽象接口：统一 AI 玩家与网络玩家行为
- `GameEvent` 事件系统：支持本地事件与网络事件统一处理

### 依赖

- 新增 `playing_cards` 或自定义卡牌渲染组件
- 可能需要 `flutter_animate` 用于卡牌动画效果

### 路由

```dart
GoRoute(path: '/', builder: (_, __) => HomePage()),
GoRoute(path: '/doudizhu', builder: (_, __) => DoudizhuGamePage()),
// 预留其他游戏路由
GoRoute(path: '/texas-holdem', builder: (_, __) => PlaceholderPage()),
```
