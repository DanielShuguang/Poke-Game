# Poke Game

一个基于 Flutter 开发的跨平台扑克游戏合集，支持单机 AI 对战与局域网联机对战。

## 已上线游戏

| 游戏 | 单机 AI | 局域网联机 |
|------|---------|-----------|
| 斗地主 | ✅ | ✅ |
| 德州扑克 | ✅ | ✅ |
| 炸金花 | ✅ | ✅ |
| 21点 | ✅ | ✅ |
| 斗牛 | ✅ | ✅ |
| 升级 | ✅ | ✅ |
| 跑得快 | ✅ | ✅ |
| 掼蛋 | ✅ | ✅ |

## 功能特性

### 单机游戏
- 斗地主：完整游戏流程，智能 AI（MCTS + 叫地主/出牌策略），支持所有牌型
- 德州扑克：现金局，支持 Hit/Stand/Double/Split/Surrender 等操作
- 炸金花：三张牌博弈，AI 跟注/加注/弃牌决策
- 21点：经典规则，Hard 17 庄家策略，Blackjack 1.5 倍赔率
- 斗牛：C(5,3) 枚举判牛，五小牛/炸弹/牛牛特殊牌型，倍率结算
- 升级：4 人两队组队斗牌，支持亮主/叫主，AI 策略出牌
- 跑得快：3 人竞速出牌，智能 AI 出牌提示，倒计时超时自动托管
- 掼蛋：4 人两队对抗（两副牌），MCTS AI，进贡/还贡机制，倒计时超时自动托管

### 局域网联机
- 基于 Wi-Fi 的局域网房间发现与创建
- Host/Client 适配器模式，Host 执行逻辑并广播状态
- 手牌隐私保护（showdown 前隐藏他人手牌）
- 可配置回合时限（15/25/35/60 秒），超时自动托管
- 支持观战模式

### 平台支持

- Android / iOS / Web / Windows / macOS / Linux

## 环境要求

- Flutter SDK >= 3.6.1
- Dart SDK >= 3.6.1

## 快速开始

```bash
# 克隆项目
git clone <repository-url>
cd poke_game

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 项目结构

```
lib/
├── core/
│   ├── router/                    # GoRouter 路由配置
│   ├── network/                   # 各游戏网络适配器（Host/Client 模式）
│   └── ai/mcts/                   # 通用 MCTS 引擎
├── domain/
│   ├── game/                      # 通用游戏实体（GameInfo、GameType）
│   ├── lan/                       # 局域网房间实体（Room、RoomInfo）
│   ├── doudizhu/                  # 斗地主领域（entities/usecases/validators/ai）
│   ├── texas_holdem/              # 德州扑克领域
│   ├── zhajinhua/                 # 炸金花领域
│   ├── blackjack/                 # 21点领域
│   ├── niuniu/                    # 斗牛领域
│   ├── shengji/                   # 升级领域
│   ├── paodekai/                  # 跑得快领域
│   └── guandan/                   # 掼蛋领域
└── presentation/
    └── pages/
        ├── home/                  # 首页（游戏列表）
        ├── room/                  # 局域网房间（扫描/创建/大厅）
        ├── doudizhu/              # 斗地主游戏页面
        ├── texas_holdem/          # 德州扑克游戏页面
        ├── zhajinhua/             # 炸金花游戏页面
        ├── blackjack/             # 21点游戏页面
        ├── niuniu/                # 斗牛游戏页面
        ├── shengji/               # 升级游戏页面
        ├── paodekai/              # 跑得快游戏页面
        ├── guandan/               # 掼蛋游戏页面
        └── settings/              # 设置页面
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.6.1+ |
| 状态管理 | flutter_riverpod |
| 不可变数据 | freezed |
| 路由 | GoRouter |
| 本地存储 | Hive / SharedPreferences |
| 屏幕适配 | FlutterScreenUtil |
| JSON 序列化 | json_serializable |

## 常用命令

```bash
flutter pub get                    # 安装依赖
flutter run                        # 运行应用
flutter test                       # 运行测试
flutter analyze                    # 代码分析
flutter build apk --release        # 构建 Android APK
flutter build ios --release        # 构建 iOS
flutter build web --release        # 构建 Web
flutter pub run build_runner build # 代码生成（freezed/json）
```

## License

MIT License
