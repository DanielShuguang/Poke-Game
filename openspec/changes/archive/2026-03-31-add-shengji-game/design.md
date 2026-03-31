# 升级游戏技术设计

## 上下文

项目已上线 5 款扑克游戏（斗地主、德州扑克、炸金花、21点、斗牛），均支持单机 AI 和局域网联机。升级是首款**四人组队对抗**游戏，核心特色：
- **将牌系统**：动态级牌（2-A循环）+ 叫牌花色
- **团队机制**：固定两人一队，对家为队友
- **持久化级别**：升级进度跨局保存

约束：
- 复用现有局域网架构（Host/Client 适配器模式）
- 遵循 Clean Architecture 三层结构
- 文件不超过 500 行，函数不超过 100 行

## 目标 / 非目标

**目标：**
- 实现完整的升级游戏核心逻辑（发牌、叫牌、出牌、计分、升级）
- 支持单机 AI 对战（4人，2人AI + 2人玩家，或全AI）
- 支持局域网联机（Host/Client 模式）
- AI 具备基本团队配合策略

**非目标：**
- 不支持在线服务器匹配（仅局域网）
- 不支持自定义规则变体（如"炒地皮"等地方规则）
- 不支持观战功能
- 不支持语音/文字聊天（复用现有聊天系统）

## 决策

### 1. 将牌系统设计

**决策**：使用 `TrumpInfo` 值对象封装将牌逻辑

```dart
class TrumpInfo {
  final Suit? trumpSuit;  // null = 无将
  final int rankLevel;     // 级牌（2-14）
}
```

**理由**：
- 将牌判断是高频操作，需内联优化
- 封装后便于 AI 评估手牌强度
- 支持序列化（网络传输）

**替代方案**：
- ❌ 在 Card 实体中添加 `isTrump` 标志：会导致状态不一致，每局需重新计算
- ❌ 全局变量存储当前将牌：违反无状态原则，不利于测试

### 2. 出牌验证架构

**决策**：采用责任链模式处理出牌验证

```
PlayValidator
├── HasCardsValidator      # 检查手牌
├── ShapeValidator         # 检查牌型（单张/对子/拖拉机）
├── FollowSuitValidator    # 检查跟花色规则
└── TrumpValidator         # 检查杀牌规则
```

**理由**：
- 验证规则复杂且可组合，责任链便于扩展
- 每个验证器独立测试，覆盖率高
- 可复用验证器（如拖拉机检测）

**替代方案**：
- ❌ 单一巨型验证函数：超过 100 行限制，难以维护
- ❌ 状态机模式：状态过多，复杂度不匹配

### 3. 队伍与升级持久化

**决策**：使用 SharedPreferences 存储队伍级别

```dart
class TeamProgress {
  final int teamLevel;  // 2-14 (2-A)
  final int totalGames;
  final int winGames;
}
```

**理由**：
- 级别是长期数据，需跨会话持久化
- SharedPreferences 足够轻量，无需数据库
- 支持多设备独立存档

**替代方案**：
- ❌ Hive：需要类型适配器，过度设计
- ❌ 内存存储：应用重启后丢失进度

### 4. AI 策略分层

**决策**：分离叫牌策略和出牌策略

```dart
abstract class CallStrategy {
  TrumpCall? evaluate(List<ShengjiCard> hand, int level);
}

abstract class PlayStrategy {
  List<ShengjiCard> decide(ShengjiGameState state, String playerId);
}
```

**理由**：
- 叫牌和出牌是独立决策点，职责分离
- 便于针对不同难度实现不同策略
- 复用现有 AI 框架

**替代方案**：
- ❌ 单一 AI 类：违反单一职责原则
- ❌ 硬编码规则：难以调试和优化

### 5. 网络适配器设计

**决策**：复用 `XxxNetworkAdapter` 模式

```dart
class ShengjiNetworkAdapter {
  final Stream<ShengjiNetworkAction> incomingStream;
  final void Function(Map<String, dynamic>) broadcast;
  final ShengjiNotifier notifier;
  final bool isHost;
  final String localPlayerId;
}
```

**网络行动类型**：
- `CallTrumpAction` - 叫牌
- `PlayCardsAction` - 出牌
- `StateSyncAction` - 状态同步

**理由**：
- 与现有游戏架构一致，降低学习成本
- Host 执行验证，Client 仅发送行动
- 复用 35 秒超时托管机制

## 风险 / 权衡

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 出牌验证逻辑复杂 | 高 | 完整测试用例覆盖，按牌型分类验证 |
| 拖拉机识别算法边界情况 | 中 | 参考斗地主连牌算法，增加边界测试 |
| AI 团队配合策略弱 | 中 | 优先实现基础策略，迭代优化 |
| 状态同步数据量大 | 低 | 仅同步必要字段，手牌编码压缩 |
| 级别持久化冲突 | 低 | 使用设备唯一标识区分存档 |

## 迁移计划

无需迁移。升级是新游戏模块，不影响现有游戏。

**部署步骤**：
1. 合并代码到主分支
2. 更新 `GameType` 枚举（兼容现有序列化）
3. 发布新版本

## 待解决问题

1. **AI 难度配置**：是否需要简单/普通/困难三档？
2. **无将模式优先级**：叫无将 vs 叫花色的优先级规则？
3. **底牌埋分**：是否支持庄家埋分到牌底？
