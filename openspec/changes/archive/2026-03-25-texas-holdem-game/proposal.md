## 为什么

游戏合集目前仅有斗地主，受众有限。德州扑克是全球最流行的扑克游戏，加入后可显著扩大用户群体，同时复用已有的房间管理、局域网发现和多人网络同步基础设施。

## 变更内容

- **新增** 德州扑克游戏模式（现金局）
- **新增** 单人 AI 对战（3-6 人桌，AI 填充空位）
- **新增** 局域网多人对战（复用现有房间系统）
- **新增** 牌型判断引擎（7选5，从底牌+公牌中选最优5张）
- **新增** 德州扑克投注系统（Fold / Check / Call / Raise / All-in）
- **新增** 边池（Side Pot）计算逻辑
- **修改** 游戏选择页面：增加德州扑克入口

## 功能 (Capabilities)

### 新增功能

- `texas-holdem-engine`: 德州扑克核心游戏引擎，包含发牌流程（Preflop / Flop / Turn / River）、盲注机制（小盲/大盲）、轮次管理（dealer button 轮转）
- `texas-holdem-betting`: 投注系统，支持 Fold / Check / Call / Raise / All-in，含边池（Side Pot）计算与筹码结算
- `texas-holdem-hand-evaluator`: 牌型评估引擎，从7张牌中选最优5张，支持皇家同花顺到高牌的全部10种牌型，用于胜负判断
- `texas-holdem-ai`: AI 决策策略，基于当前手牌强度（蒙特卡洛胜率估算）和投注历史，模拟合理的 Fold / Call / Raise 行为
- `texas-holdem-ui`: 德州扑克游戏界面，横屏布局，展示公牌区、玩家手牌、筹码、投注按钮和行动提示

### 修改功能

- `game-selection`: 在游戏选择页新增德州扑克入口卡片

## 影响

- **新增目录**：`lib/domain/texas_holdem/`、`lib/data/texas_holdem/`、`lib/presentation/pages/texas_holdem/`
- **复用现有**：`room-management`、`lan-discovery`、`network-sync`、`player-management` 规范中的房间和网络能力
- **依赖变更**：可能需要引入概率计算辅助库，或纯 Dart 实现蒙特卡洛模拟
- **不涉及破坏性变更**：斗地主模块完全独立，现有功能不受影响
