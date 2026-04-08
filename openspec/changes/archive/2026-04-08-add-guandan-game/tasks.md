## 1. 领域实体

- [ ] 1.1 创建 `lib/domain/guandan/entities/guandan_card.dart`：定义 `GuandanCard`（suit、rank、isWild 标记），实现 `==`/`hashCode`/`toString`
- [ ] 1.2 创建 `lib/domain/guandan/entities/guandan_hand_type.dart`：定义 `HandType` 枚举（single、pair、triple、triplePair、straight、consecutivePairs、steelPlate、bomb、straightFlushBomb、kingBomb）
- [ ] 1.3 创建 `lib/domain/guandan/entities/guandan_hand.dart`：定义 `GuandanHand`（cards、type、rank）及比较方法 `beats(GuandanHand other)`
- [ ] 1.4 创建 `lib/domain/guandan/entities/guandan_player.dart`：定义 `GuandanPlayer`（id、name、avatarIndex、teamId、cards、finishRank）
- [ ] 1.5 创建 `lib/domain/guandan/entities/guandan_game_state.dart`：定义 `GuandanGameState`（phase、players、currentLevel、currentPlayerIndex、lastPlayedHand、tributeState、roundResult），实现 `copyWith`、`toJson`/`fromJson`（含 `includeAllCards` 参数）

## 2. 用例与判定逻辑

- [ ] 2.1 创建 `lib/domain/guandan/usecases/validate_hand_usecase.dart`：实现 `ValidateHandUsecase.validate(List<GuandanCard> cards, int level) → HandType?`，覆盖全部牌型
- [ ] 2.2 在 `ValidateHandUsecase` 中实现级牌百搭嵌入顺子逻辑：检测缺口、填补、验证两端约束
- [ ] 2.3 在 `GuandanHand.beats()` 中实现炸弹比较优先级：天王炸 > 同花顺炸（按张数）> 级牌炸（按张数）> 普通炸（按张数）
- [ ] 2.4 创建 `lib/domain/guandan/usecases/hint_usecase.dart`：实现 `HintUsecase.hint(List<GuandanCard> hand, GuandanHand? lastPlayed, int level) → List<List<GuandanCard>>`，返回可出的最小合法组合列表
- [ ] 2.5 创建 `lib/domain/guandan/usecases/deal_cards_usecase.dart`：108 张牌洗牌并发给 4 位玩家（每人 27 张）
- [ ] 2.6 创建 `lib/domain/guandan/usecases/round_result_usecase.dart`：根据 finishRank（头游/二游/三游/四游）计算升降级档数并更新 currentLevel

## 3. 单元测试

- [ ] 3.1 创建 `test/domain/guandan/validate_hand_usecase_test.dart`：测试全部合法牌型、非法牌型、级牌百搭边界（缺口数 vs 级牌数、两端约束）
- [ ] 3.2 创建 `test/domain/guandan/bomb_comparison_test.dart`：测试全部炸弹大小排序场景（天王炸 > 同花顺 > 级牌炸 > 普通炸，相同类型比张数）
- [ ] 3.3 创建 `test/domain/guandan/round_result_usecase_test.dart`：测试己方包揽升2级、头游/二游分属升1级/不升级、对方包揽降2级、升到A获胜

## 4. AI 策略

- [ ] 4.1 创建 `lib/domain/guandan/ai/guandan_ai_strategy.dart`：实现 `GuandanAiStrategy.decideAction(GuandanGameState state, String playerId) → GuandanAction`
- [ ] 4.2 实现跟牌逻辑：选择能压制且消耗最小的非炸弹组合；队友领先时强制 pass
- [ ] 4.3 实现先手逻辑：优先出最小单张，手牌全为连牌时出最长组合
- [ ] 4.4 实现贡牌自动化：自动选最大单张进贡；自动选最小单张还贡

## 5. 游戏状态管理

- [ ] 5.1 创建 `lib/domain/guandan/guandan_game_notifier.dart`：`StateNotifier<GuandanGameState>`，暴露 `startGame`、`playCards`、`pass`、`tribute`、`returnTribute` 方法
- [ ] 5.2 在 `GuandanGameNotifier` 中实现 AI 托管：单机模式下非本地玩家轮次自动调用 `GuandanAiStrategy`
- [ ] 5.3 实现贡牌阶段状态流转：上局结果 → 贡牌 phase → 还贡 → 出牌 phase
- [ ] 5.4 实现升降级结算：局结束后调用 `RoundResultUsecase`，更新 `currentLevel`，触发新局或游戏结束

## 6. 局域网联机适配器

- [ ] 6.1 创建 `lib/domain/guandan/entities/guandan_network_action.dart`：定义 sealed class `GuandanNetworkAction`（PlayCards、Pass、Tribute、ReturnTribute），实现 JSON 序列化
- [ ] 6.2 创建 `lib/core/network/guandan_network_adapter.dart`：构造参数 `incomingStream`、`broadcastFn`、`notifier`、`isHost`、`localPlayerId`
- [ ] 6.3 在适配器中实现 Host 逻辑：接收行动消息 → 验证合法性 → 调用 notifier → 广播 `toJson(includeAllCards: false)` 状态
- [ ] 6.4 在适配器中实现 Client 逻辑：本地行动 → 发送消息；接收广播状态 → 更新本地 notifier
- [ ] 6.5 在适配器中实现 35 秒超时托管：Host 端每次轮次开始启动 Timer，超时代执行 pass 或自动贡牌
- [ ] 6.6 实现联机贡牌阶段同步：Host 顺序处理贡牌消息，广播中间态，避免并发冲突

## 7. UI 页面

- [ ] 7.1 创建 `lib/presentation/pages/guandan/guandan_game_page.dart`：横屏锁定、围桌布局（底部本地手牌、顶部对家、左右两侧对手），`initState` 锁定横屏，`dispose` 恢复
- [ ] 7.2 创建 `lib/presentation/pages/guandan/widgets/guandan_hand_widget.dart`：手牌展示组件（正面/背面切换，支持选中高亮）
- [ ] 7.3 创建 `lib/presentation/pages/guandan/widgets/guandan_play_area_widget.dart`：中央出牌区（当前牌堆、当前级牌、出牌/pass 按钮）
- [ ] 7.4 创建 `lib/presentation/pages/guandan/widgets/guandan_tribute_dialog.dart`：贡牌阶段覆盖弹窗（选牌进贡/还贡）
- [ ] 7.5 实现退出确认弹窗：左上角 `IconButton(Icons.arrow_back, white70)` + `showDialog` 确认后 `Navigator.pop`
- [ ] 7.6 实现局结算弹窗：展示头游/二游/三游/四游归属及升降级结果，提供"再来一局"按钮

## 8. 路由与接入

- [ ] 8.1 在 `lib/domain/lan/entities/room_info.dart` 的 `GameType` 枚举中新增 `guandan`，补全全部 switch 分支
- [ ] 8.2 手动更新 `lib/domain/lan/entities/room_info.g.dart` 与 `room.g.dart` 的序列化映射（新增 `guandan` 条目）
- [ ] 8.3 在 `lib/core/router/app_router.dart` 注册 `/guandan` 路由
- [ ] 8.4 在 `lib/presentation/pages/home/home_provider.dart` 添加掼蛋游戏卡片数据
- [ ] 8.5 在 `lib/presentation/pages/home/home_page.dart` 的 `_supportsOnline` 列表中添加掼蛋游戏 ID
- [ ] 8.6 在 `lib/presentation/pages/room/room_lobby_page.dart` 的 `_navigateToGame()` 中添加 `guandan` 分支
- [ ] 8.7 在 `lib/presentation/pages/room/game_rules_page.dart` 的 `_getRulesContent()` 中添加掼蛋规则文本
