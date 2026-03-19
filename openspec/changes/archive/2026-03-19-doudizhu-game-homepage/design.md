# Design: 游戏首页与斗地主游戏页

## Context

### 背景

本项目是一个扑克游戏合集应用，需要支持多种经典扑克游戏。当前处于初始开发阶段，需要：

1. **游戏首页**：作为应用主入口，展示游戏列表
2. **斗地主游戏**：首个可游玩的游戏模块

### 约束

- 跨平台支持：Android、iOS、Web、Windows、macOS、Linux
- 技术栈：Flutter 3.x + Dart SDK ^3.6.1
- UI 框架：Material Design 3
- 架构模式：Clean Architecture
- 状态管理：Riverpod（flutter_riverpod）

### 相关方

- 终端用户：期望流畅的游戏体验
- 开发团队：需要可扩展的架构以便后续添加新游戏

## Goals / Non-Goals

**Goals:**

- 设计可复用的游戏模块架构，支持快速添加新游戏
- 实现清晰的层级分离，便于测试和维护
- 预留局域网对战扩展点，最小化后续改造成本
- 设计直观的首页布局，展示游戏状态（已上线/开发中/计划中）
- 实现完整的斗地主游戏流程：发牌 → 叫地主 → 出牌 → 结算

**Non-Goals:**

- 本迭代不实现局域网对战功能（仅预留接口）
- 不实现用户账号系统、积分系统
- 不实现游戏设置、音效、背景音乐
- 不支持横屏模式

## Decisions

### D1: 架构模式 — Clean Architecture

**决策**：采用 Clean Architecture 三层架构

**理由**：
- 业务逻辑与 UI 解耦，便于单元测试
- 领域层独立，后续添加局域网对战只需替换数据层
- 符合项目现有结构约定

**目录结构**：

```
lib/
├── presentation/           # 表现层
│   ├── pages/
│   │   ├── home/
│   │   │   ├── home_page.dart
│   │   │   ├── home_viewmodel.dart
│   │   │   └── widgets/
│   │   │       └── game_card_widget.dart
│   │   └── doudizhu/
│   │       ├── doudizhu_game_page.dart
│   │       ├── doudizhu_viewmodel.dart
│   │       └── widgets/
│   │           ├── card_widget.dart
│   │           ├── player_area_widget.dart
│   │           ├── hand_cards_widget.dart
│   │           └── action_buttons_widget.dart
│   └── widgets/
│       └── playing_card_widget.dart  # 共用卡牌组件
│
├── domain/                 # 领域层
│   ├── doudizhu/
│   │   ├── entities/
│   │   │   ├── card.dart
│   │   │   ├── player.dart
│   │   │   ├── game_state.dart
│   │   │   └── game_config.dart
│   │   ├── repositories/
│   │   │   └── game_repository.dart
│   │   ├── usecases/
│   │   │   ├── deal_cards_usecase.dart
│   │   │   ├── call_landlord_usecase.dart
│   │   │   ├── play_cards_usecase.dart
│   │   │   └── check_winner_usecase.dart
│   │   └── ai/
│   │       ├── ai_player.dart
│   │       └── strategies/
│   │           ├── play_strategy.dart
│   │           └── call_strategy.dart
│   └── game/               # 共用领域
│       └── entities/
│           └── game_info.dart
│
├── data/                   # 数据层
│   └── doudizhu/
│       ├── models/
│       │   └── card_model.dart
│       └── repositories/
│           └── game_repository_impl.dart
│
└── core/
    └── router/
        └── app_router.dart
```

**替代方案**：
- MVVM with Provider：更简单，但 Riverpod 提供更好的编译时安全性和可测试性
- BLoC：适合复杂状态，但对斗地主游戏而言过于重量级

---

### D2: 玩家抽象 — 支持多模式扩展

**决策**：定义 `Player` 抽象接口，AI 与网络玩家实现同一接口

**理由**：
- 人机对战与局域网对战可复用相同游戏逻辑
- 便于测试（可用 Mock 玩家替代真实 AI）

**接口设计**：

```dart
/// 玩家抽象接口
abstract class Player {
  String get id;
  String get name;
  List<Card> get handCards;

  /// 出牌决策（异步，支持网络延迟）
  Future<PlayDecision> decidePlay(GameState state);

  /// 叫地主决策
  Future<CallDecision> decideCall(GameState state);
}

/// AI 玩家实现
class AiPlayer implements Player {
  final AiStrategy _strategy;
  // ...
}

/// 网络玩家（预留）
class NetworkPlayer implements Player {
  final NetworkClient _client;
  // ...
}
```

**替代方案**：
- 不抽象，直接使用具体类型：简单但无法扩展
- 使用事件流而非接口：更复杂，适合实时对战，当前不需要

---

### D3: 游戏状态管理 — Riverpod StateNotifier

**决策**：使用 `StateNotifier` 配合 `flutter_riverpod` 管理游戏状态

**理由**：
- 编译时安全性，避免运行时错误
- 更好的可测试性，无需 BuildContext 即可测试状态逻辑
- 状态不可变，减少意外修改的风险
- 支持状态组合和依赖注入，便于管理复杂状态
- ProviderScope 统一管理，避免内存泄漏

**状态类设计**：

```dart
/// 游戏状态数据类（不可变）
@freezed
class DoudizhuState with _$DoudizhuState {
  const factory DoudizhuState({
    required GamePhase phase,
    required List<Player> players,
    required int currentPlayerIndex,
    required List<Card> landlordCards,
    required List<Card>? lastPlayedCards,
    required int? lastPlayerIndex,
    required Set<Card> selectedCards,
  }) = _DoudizhuState;

  factory DoudizhuState.initial() => DoudizhuState(
    phase: GamePhase.waiting,
    players: [],
    currentPlayerIndex: 0,
    landlordCards: [],
    lastPlayedCards: null,
    lastPlayerIndex: null,
    selectedCards: {},
  );
}

/// 游戏状态 Notifier
class DoudizhuNotifier extends StateNotifier<DoudizhuState> {
  final DealCardsUseCase _dealCardsUseCase;
  final PlayCardsUseCase _playCardsUseCase;

  DoudizhuNotifier({
    required DealCardsUseCase dealCardsUseCase,
    required PlayCardsUseCase playCardsUseCase,
  }) : _dealCardsUseCase = dealCardsUseCase,
       _playCardsUseCase = playCardsUseCase,
       super(DoudizhuState.initial());

  Future<void> startGame() async { ... }
  Future<void> callLandlord(bool call) async { ... }
  Future<void> playCards(List<Card> cards) async { ... }
  void toggleCardSelection(Card card) { ... }
}

/// Provider 定义
final doudizhuProvider = StateNotifierProvider<DoudizhuNotifier, DoudizhuState>(
  (ref) => DoudizhuNotifier(
    dealCardsUseCase: ref.watch(dealCardsUseCaseProvider),
    playCardsUseCase: ref.watch(playCardsUseCaseProvider),
  ),
);

/// UI 中使用
class DoudizhuGamePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doudizhuProvider);
    final notifier = ref.read(doudizhuProvider.notifier);

    return Column(
      children: [
        Text('Phase: ${state.phase}'),
        ElevatedButton(
          onPressed: () => notifier.startGame(),
          child: Text('Start'),
        ),
      ],
    );
  }
}
```

**替代方案**：
- Provider + ChangeNotifier：更简单，但缺乏编译时安全性
- BLoC Cubit：类似效果，但 Riverpod 更轻量且功能更丰富

---

### D4: 卡牌渲染 — 自定义 Widget

**决策**：自定义 `CardWidget` 而非使用第三方库

**理由**：
- 斗地主卡牌样式特殊（需要红黑花色、大小王）
- 完全控制动画和交互
- 避免第三方库的样式限制和兼容性问题

**组件设计**：

```dart
class CardWidget extends StatelessWidget {
  final Card card;
  final bool isSelected;
  final bool faceUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: isSelected ? _raiseTransform : null,
        child: _buildCardFace(),
      ),
    );
  }
}
```

**替代方案**：
- `playing_cards` 包：样式固定，难以定制
- `flutter_deck`：针对卡牌游戏，但过于重量级

---

### D5: AI 策略 — 规则引擎 + 简单评估

**决策**：采用规则引擎实现 AI 出牌策略

**理由**：
- 规则引擎可调试、可调整
- 性能足够（单局游戏 AI 决策次数有限）
- 便于后续优化策略

**AI 策略层次**：

```
AiStrategy
├── 分析当前牌型（单张、对子、三带一、顺子等）
├── 评估手牌强度
├── 选择最优出牌
└   └── 无牌可出时 PASS
```

**替代方案**：
- 蒙特卡洛树搜索（MCTS）：计算量大，不必要
- 深度学习：需要训练数据和模型部署，过度工程化

---

### D6: 游戏路由 — GoRouter

**决策**：使用项目已有的 GoRouter 进行路由管理

**理由**：
- 项目已依赖 GoRouter
- 声明式路由，便于维护
- 支持深链接（后续可扩展）

**路由配置**：

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => HomePage(),
    ),
    GoRoute(
      path: '/doudizhu',
      name: 'doudizhu',
      builder: (context, state) => DoudizhuGamePage(),
    ),
    // 预留其他游戏路由
    GoRoute(
      path: '/game/:gameId',
      builder: (context, state) => GamePlaceholderPage(),
    ),
  ],
);
```

---

### D7: 局域网扩展架构 — 事件驱动

**决策**：采用事件驱动架构，统一处理本地与网络事件

**理由**：
- AI 操作与网络操作可统一为事件流
- 便于后续添加回放功能
- 解耦 UI 与游戏逻辑

**事件系统设计**：

```dart
/// 游戏事件基类
abstract class GameEvent {
  final int timestamp;
  final String playerId;
}

/// 出牌事件
class PlayCardsEvent extends GameEvent {
  final List<Card> cards;
}

/// 叫地主事件
class CallLandlordEvent extends GameEvent {
  final bool call;
}

/// 事件处理器
class GameEventProcessor {
  void process(GameEvent event) {
    if (event is PlayCardsEvent) { ... }
    else if (event is CallLandlordEvent) { ... }
  }
}

/// 本地事件源（AI）
class LocalEventSource {
  Stream<GameEvent> get events;
}

/// 网络事件源（预留）
class NetworkEventSource {
  Stream<GameEvent> get events;
}
```

## Risks / Trade-offs

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| AI 策略过于简单导致游戏体验差 | 用户流失 | 采用分级难度，简单模式使用随机策略，困难模式使用优化策略 |
| 状态管理复杂度随游戏规则增加 | 维护困难 | 将状态拆分为多个子状态类，单一职责 |
| 自定义卡牌组件工作量大 | 延期风险 | 先实现基础样式，后续迭代优化 |
| 局域网扩展架构设计不足 | 重构成本高 | 设计 Review，确保接口抽象合理 |
| 跨平台渲染性能差异 | 体验不一致 | 使用 `const` 构造函数，避免过度重绘；低端设备降级动画 |

## Migration Plan

### 上线步骤

1. **阶段一：首页 + 基础游戏框架**
   - 实现首页 UI
   - 实现斗地主发牌、基础出牌逻辑
   - 无 AI，仅支持手动操作测试

2. **阶段二：完整游戏流程**
   - 实现叫地主流程
   - 实现牌型判断（单张、对子、三带一、顺子、炸弹等）
   - 实现基础 AI 策略

3. **阶段三：优化与完善**
   - 动画效果优化
   - AI 策略优化
   - 边界情况处理

### 回滚策略

- 使用 Feature Flag 控制游戏入口显示
- 若发现严重问题，可快速隐藏入口而不影响应用其他功能

## Open Questions

1. **卡牌资源**：是使用图片资源还是纯代码绘制？
   - 建议：初期使用纯代码绘制（Container + Text），后续可替换为图片

2. **AI 难度分级**：是否需要在第一版就实现多难度？
   - 建议：第一版仅实现中等难度，观察用户反馈

3. **游戏数据持久化**：是否需要保存游戏进度？
   - 建议：第一版不实现，简化开发
