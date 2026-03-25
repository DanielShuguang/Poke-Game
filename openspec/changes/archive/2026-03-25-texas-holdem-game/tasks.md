## 1. 项目结构与实体层

- [x] 1.1 创建目录结构：`lib/domain/texas_holdem/`、`lib/data/texas_holdem/`、`lib/presentation/pages/texas_holdem/`
- [x] 1.2 确认斗地主 `Card` 实体（Suit/Rank 枚举）可复用，若有冲突则在 `domain/texas_holdem/entities/` 中派生 `HoldemCard`
- [x] 1.3 创建 `HoldemPlayer` 实体：包含 id、name、chips（筹码）、holeCards（底牌）、currentBet、isFolded、isAllIn 字段
- [x] 1.4 创建 `Pot` 实体：包含 amount、eligiblePlayerIds 字段，用于表示主池和边池
- [x] 1.5 创建 `HoldemGameState` 实体（freezed）：包含 players、communityCards、pots、phase（Preflop/Flop/Turn/River/Showdown）、currentPlayerIndex、dealerIndex、smallBlind、bigBlind

## 2. 牌型评估引擎

- [x] 2.1 实现 `HandEvaluator.evaluate(List<Card> sevenCards) -> HandResult`：枚举 C(7,5)=21 种5张组合，返回最高评分
- [x] 2.2 实现 `HandResult` 类：包含 handRank（枚举10种牌型）、score（整数编码）、bestFive（最优5张）
- [x] 2.3 实现整数评分编码：高位存牌型等级，低位存点数序列，支持直接整数比较
- [x] 2.4 实现 A 低顺（A-2-3-4-5）特殊处理，A 视为1
- [x] 2.5 编写单元测试：覆盖全部10种牌型识别，含边界场景（A高顺、A低顺、同花顺 vs 顺子）
- [x] 2.6 编写单元测试：覆盖踢脚牌比较和平局场景

## 3. 边池计算器

- [x] 3.1 实现 `PotCalculator.calculate(List<HoldemPlayer> players) -> List<Pot>`：按 All-in 金额分层计算主池和各边池
- [x] 3.2 实现平局分配逻辑：奇数筹码余数归 Small Blind 最近活跃玩家
- [x] 3.3 编写单元测试：覆盖无 All-in、单人 All-in、多人不同金额 All-in 场景
- [x] 3.4 编写单元测试：验证所有场景下全局筹码总量守恒

## 4. 游戏核心引擎

- [x] 4.1 实现 `DealCardsUsecase`：洗牌、发2张底牌给每位玩家、设置 Dealer/SB/BB 位置、自动扣除盲注
- [x] 4.2 实现 `BettingRoundUsecase`：处理单轮投注，支持 Fold/Check/Call/Raise/All-in，维护当前最高注和最小加注额
- [x] 4.3 实现最小加注验证：Raise 增量不得低于上一次加注增量，首次下注最小为1个大盲注
- [x] 4.4 实现轮次推进逻辑：投注轮结束条件（所有活跃玩家注额相等 或 仅剩1人），按顺序翻出 Flop/Turn/River 公牌
- [x] 4.5 实现 `ShowdownUsecase`：调用 HandEvaluator 评估所有未弃牌玩家牌型，结合 PotCalculator 结果分配筹码
- [x] 4.6 实现提前结束逻辑：仅剩1名活跃玩家时直接分配底池，跳过 Showdown
- [x] 4.7 实现 Dealer Button 轮转：每局结束后顺时针移动，跳过筹码为0或已离开的玩家

## 5. 状态管理

- [x] 5.1 创建 `HoldemGameNotifier extends StateNotifier<HoldemGameState>`，暴露 startGame、fold、check、call、raise(amount) 方法
- [x] 5.2 创建 `holdemGameProvider`（StateNotifierProvider），注入所需 usecase 依赖
- [x] 5.3 实现行动权限验证：非当前玩家调用行动方法时抛出异常
- [x] 5.4 实现超时自动行动：30秒计时器到期时触发 check（可 check 时）或 fold

## 6. AI 策略

- [x] 6.1 实现 `MonteCarloSimulator.estimateEquity(holeCards, communityCards, playerCount, iterations) -> double`：在 Isolate 中执行蒙特卡洛模拟
- [x] 6.2 实现 `HoldemAiStrategy.decide(HoldemGameState, playerId) -> AiAction`：根据胜率和底池赔率返回决策
- [x] 6.3 实现决策规则：equity>0.65 倾向 Raise，0.35-0.65 参考底池赔率 Call/Fold，<0.35 倾向 Fold
- [x] 6.4 实现随机扰动（±15%概率偏移）和短筹码 All-in 保护逻辑
- [x] 6.5 实现 AI 行动延迟：决策后等待 500ms~2000ms 随机时间再执行
- [x] 6.6 在 `HoldemGameNotifier` 中集成 AI 驱动：轮到 AI 玩家时自动触发策略决策

## 7. 多人网络集成

- [x] 7.1 定义德州扑克专用消息类型：`HoldemAction`（fold/check/call/raise + amount）扩展至现有网络消息协议
- [x] 7.2 在 `HoldemGameNotifier` 中集成 `RoomStateSyncService`：多人模式下 Host 广播状态，客户端发送行动
- [x] 7.3 实现客户端行动上报：客户端调用行动方法时发送网络消息，Host 验证后广播新状态
- [x] 7.4 验证断线处理：客户端超时未发送行动时，Host 自动执行 fold

## 8. 游戏界面

- [x] 8.1 创建 `HoldemGamePage`：`initState` 中锁定横屏，`dispose` 中恢复方向
- [x] 8.2 实现公牌区 Widget：5个卡牌位置，未翻出显示牌背，翻出时带翻转动画
- [x] 8.3 实现底池金额显示（公牌区下方），实时监听状态变化
- [x] 8.4 实现玩家席位 Widget：显示名称、筹码、当前投注额、底牌、位置标记（D/SB/BB）
- [x] 8.5 实现当前行动玩家高亮和30秒倒计时进度条
- [x] 8.6 实现投注操作区：Fold/Check/Call/Raise 按钮，非本玩家回合时隐藏
- [x] 8.7 实现 Raise 金额滑动条：范围从最小加注额到 All-in，含 0.5x底池、1x底池、All-in 快捷按钮
- [x] 8.8 实现摊牌阶段：翻转对手底牌，标注最优牌型名称，高亮获胜手牌
- [x] 8.9 适配多平台布局：确保桌面端（Windows/macOS/Web）横屏下席位间距合理

## 9. 游戏选择页更新

- [x] 9.1 在游戏选择页新增德州扑克入口卡片，标注"现金局"，点击导航至德州扑克大厅页面
- [x] 9.2 创建德州扑克大厅页面：提供单人 AI 对战（选择人数）和局域网多人（创建/加入房间）两个入口

## 10. 集成测试与收尾

- [x] 10.1 编写游戏流程集成测试：完整模拟一局（发牌 → 投注 → 翻牌 → 结算），验证筹码守恒
- [x] 10.2 运行 `flutter analyze` 确保无静态分析警告
- [ ] 10.3 在 Android 和 Web 平台各测试一局单人 AI 对战，验证 Isolate 模拟无卡顿
- [ ] 10.4 测试多人局域网对战：2台设备，验证行动同步和状态广播正确性
