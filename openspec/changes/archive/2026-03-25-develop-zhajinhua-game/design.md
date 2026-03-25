## 上下文

项目已实现斗地主（Clean Architecture + Riverpod）和德州扑克（单机 AI 对战），两者代码结构高度相似。炸金花将复用相同的架构分层（domain / data / presentation），但引入了斗地主和德州扑克都没有的**蒙牌机制**和**淘汰制下注引擎**，需要专门设计。

当前主页通过 `GameSelectionPage` 展示游戏入口，路由使用 GoRouter。

## 目标 / 非目标

**目标：**
- 实现炸金花单机 AI 对战（2-5人，1人类 + 1-4 AI）
- 完整的下注循环：底注 → 多轮跟/加/弃/比 → 结算
- 蒙牌/看牌状态管理（玩家可选择不看牌）
- 牌型评估：豹子 > 同花顺 > 同花 > 顺子 > 对子 > 散牌
- AI 对手具备基础策略（牌力评估 + 随机激进度）
- 横屏布局，风格与现有游戏一致

**非目标：**
- 多人联机对战（本期不做）
- 真实筹码 / 货币系统
- 成就系统 / 排行榜
- 蒙牌玩法的网络对战（信息隐藏在联机中有额外复杂度）

## 决策

### 1. 架构分层：复用 Clean Architecture

与斗地主保持一致：
```
domain/zhajinhua/
  entities/     # ZhjCard, ZhjPlayer, ZhjGameState, ZhjGameConfig
  usecases/     # DealCardsUsecase, BettingUsecase, ShowdownUsecase
  validators/   # ZhjCardValidator（牌型评估 + 比较）
  ai/           # ZhjAiStrategy（蒙牌决策 + 下注决策）
  repositories/ # ZhjGameRepository（接口）
data/zhajinhua/
  repositories/ # ZhjGameRepositoryImpl
presentation/pages/zhajinhua/
  zhajinhua_page.dart
  widgets/      # TableWidget, HandWidget, BettingPanel, ChipDisplay
```

**为何不合并到通用模块**：炸金花的下注逻辑（淘汰制、蒙牌倍率）与斗地主/德州扑克差异大，共享会增加耦合。

### 2. 状态管理：StateNotifierProvider（与斗地主一致）

`ZhjGameNotifier extends StateNotifier<ZhjGameState>`
- 避免引入新的状态管理方案，降低学习成本
- `ZhjGameState` 用 `freezed` 生成不可变类

### 3. 游戏状态机

```
Idle → Dealing → BettingRound(n) → Showdown → Settlement → Idle
```

每个 `BettingRound`：
- 遍历存活玩家（未弃牌）
- 人类轮到时暂停等待 UI 输入
- AI 自动执行决策
- 所有玩家完成本轮 → 检查是否只剩一人 / 进入下一轮

### 4. 蒙牌机制

`ZhjPlayer.hasPeeked: bool`（默认 false）
- 看牌操作：设置 `hasPeeked = true`，UI 翻开手牌
- 下注倍率：未看牌时跟注金额 = 当前底注，看牌后跟注金额 = 当前底注 × 2
- AI 策略：第一轮大概率蒙牌（增加随机性），牌力强时更倾向于加注

### 5. 牌型评估：纯函数设计

`ZhjCardValidator` 提供静态方法：
- `HandRank evaluate(List<ZhjCard> cards)` → 枚举 + 比较值
- `int compare(List<ZhjCard> a, List<ZhjCard> b)` → -1 / 0 / 1

无副作用，易于单元测试。

### 6. AI 激进度参数

每个 AI 玩家在创建时随机分配 `aggression: double (0.0-1.0)`：
- 低激进度：倾向于跟注/弃牌
- 高激进度：倾向于加注/蒙牌更久
- 避免 AI 行为千篇一律

## 风险 / 权衡

| 风险 | 缓解措施 |
|------|----------|
| 蒙牌下注倍率规则在不同地区有差异 | 在 `ZhjGameConfig` 中提供 `blindBetMultiplier` 配置项，默认 ×2 |
| 炸金花无"过"操作，弃牌即出局，UI 反馈需清晰 | 弃牌时播放动画 + 遮罩，避免误操作；添加确认对话框 |
| AI 思考无延迟会让玩家感觉突兀 | 添加 500ms-1000ms 随机延迟，模拟"思考" |
| 比牌操作（两玩家直接对比）容易实现错误 | 单独封装 `ShowdownUsecase`，添加完整单元测试 |
| freezed 代码生成在 Windows 路径可能有问题 | 与现有 doudizhu 实体保持相同生成方式，已验证可用 |
