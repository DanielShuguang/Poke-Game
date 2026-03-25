## 1. Domain 层 - 实体与数据模型

- [x] 1.1 创建 `lib/domain/zhajinhua/entities/zhj_card.dart`（ZhjCard：suit, rank, 复用/对齐现有 Card 结构）
- [x] 1.2 创建 `lib/domain/zhajinhua/entities/zhj_player.dart`（ZhjPlayer：id, name, cards, chips, hasPeeked, isFolded, isAi, aggression）
- [x] 1.3 创建 `lib/domain/zhajinhua/entities/zhj_game_state.dart`（ZhjGameState：players, pot, currentBet, currentPlayerIndex, phase, winner）
- [x] 1.4 创建 `lib/domain/zhajinhua/entities/zhj_game_config.dart`（ZhjGameConfig：playerCount, initialChips, baseBet, blindBetMultiplier）
- [x] 1.5 无需 freezed，改用手动 copyWith（无代码生成依赖）

## 2. Domain 层 - 牌型验证器

- [x] 2.1 创建 `lib/domain/zhajinhua/validators/zhj_card_validator.dart`，定义 `HandRank` 枚举（threeOfAKind, straightFlush, flush, straight, pair, highCard）
- [x] 2.2 实现 `ZhjCardValidator.evaluate(List<ZhjCard>)` 静态方法，返回 HandRank 及比较值
- [x] 2.3 实现 `ZhjCardValidator.compare(List<ZhjCard> a, List<ZhjCard> b)` 静态方法，返回 -1/0/1
- [x] 2.4 处理特殊顺子 A-2-3（最小顺子）和 A-K-Q（最大同花顺）边界情况
- [x] 2.5 为 ZhjCardValidator 编写单元测试（18个，全部通过）

## 3. Domain 层 - 用例

- [x] 3.1 创建 `lib/domain/zhajinhua/usecases/deal_cards_usecase.dart`（洗牌 52 张，每人发 3 张）
- [x] 3.2 创建 `lib/domain/zhajinhua/usecases/betting_usecase.dart`（处理跟注/加注/弃牌/All-in，更新底池和筹码）
- [x] 3.3 创建 `lib/domain/zhajinhua/usecases/peek_card_usecase.dart`（设置 hasPeeked=true，不可撤销）
- [x] 3.4 创建 `lib/domain/zhajinhua/usecases/showdown_usecase.dart`（比牌：翻牌、调用 validator 比较、淘汰失败者）
- [x] 3.5 为各 usecase 编写单元测试（11个，全部通过）

## 4. Domain 层 - AI 策略

- [x] 4.1 创建 `lib/domain/zhajinhua/ai/zhj_ai_strategy.dart`，实现 `decideAction(ZhjGameState, ZhjPlayer)` 方法
- [x] 4.2 实现蒙牌决策逻辑（基于牌力阈值 + aggression 参数）
- [x] 4.3 实现下注决策逻辑（跟注/加注/弃牌概率分布，依赖 HandRank + aggression）
- [x] 4.4 为 AI 策略编写单元测试（6个，全部通过）

## 5. Data 层 - Repository

- [x] 5.1 创建 `lib/domain/zhajinhua/repositories/zhj_game_repository.dart`（抽象接口）
- [x] 5.2 创建 `lib/data/zhajinhua/repositories/zhj_game_repository_impl.dart`（实现：初始化、保存/读取游戏状态）

## 6. Presentation 层 - 状态管理

- [x] 6.1 创建 `lib/presentation/pages/zhajinhua/providers/zhj_game_provider.dart`（StateNotifierProvider）
- [x] 6.2 实现 `ZhjGameNotifier extends StateNotifier<ZhjGameState>`，封装游戏流程状态机
- [x] 6.3 实现状态机方法：startGame、playerPeek、playerCall、playerRaise、playerFold、playerShowdown、playAgain、settle
- [x] 6.4 实现 AI 回合自动触发（500ms–1200ms 延迟后调用 ZhjAiStrategy）

## 7. Presentation 层 - UI 组件

- [x] 7.1 创建 `lib/presentation/pages/zhajinhua/widgets/zhj_table_widget.dart`（游戏桌面横屏布局：玩家位置 + 底池）
- [x] 7.2 创建 `lib/presentation/pages/zhajinhua/widgets/zhj_player_widget.dart`（玩家区域：手牌背/正面 + 状态标签 + 筹码显示）
- [x] 7.3 创建 `lib/presentation/pages/zhajinhua/widgets/zhj_hand_widget.dart`（3张牌显示：蒙牌/看牌切换动画）
- [x] 7.4 创建 `lib/presentation/pages/zhajinhua/widgets/zhj_betting_panel.dart`（操作面板：看牌/跟注/加注/弃牌/比牌按钮）
- [x] 7.5 创建 `lib/presentation/pages/zhajinhua/widgets/zhj_pot_display.dart`（底池 + 当前底注金额显示）
- [x] 7.6 创建 `lib/presentation/pages/zhajinhua/widgets/zhj_settlement_dialog.dart`（结算弹窗：输赢金额 + 再来一局/返回大厅）

## 8. Presentation 层 - 页面

- [x] 8.1 创建 `lib/presentation/pages/zhajinhua/zhajinhua_page.dart`（组合所有 widget，设置横屏，初始化 provider）
- [x] 8.2 在 `initState` 中设置横屏锁定，在 `dispose` 中恢复方向

## 9. 路由与导航

- [x] 9.1 在 `lib/core/router/app_router.dart` 中注册 `/zhajinhua` 路由，指向 ZhajinhuaPage
- [x] 9.2 在 `lib/presentation/pages/home/home_provider.dart` 将炸金花状态改为 available
- [x] 9.3 路由使用 GoRouter context.push('/zhajinhua')，返回大厅使用 Navigator.pop

## 10. 集成验证

- [x] 10.1 运行 `flutter analyze`：炸金花代码无新增警告/错误
- [x] 10.2 运行 `flutter test`：35个单元测试全部通过
- [ ] 10.3 在 Windows/Android 模拟器上运行完整游戏流程（发牌→下注→看牌→弃牌/比牌→结算→再来一局）
- [ ] 10.4 验证 AI 操作延迟和动画效果正常
- [ ] 10.5 验证弃牌确认对话框防误操作有效
