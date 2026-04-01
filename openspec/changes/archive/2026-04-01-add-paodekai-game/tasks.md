## 1. 核心实体（domain/paodekai/entities）

- [x] 1.1 创建 `PdkSuit` 枚举（spade/heart/club/diamond/none）和 `PdkRank` 枚举（three…ace, two, jokerSmall, jokerBig）
- [x] 1.2 创建 `PdkCard` 类（rank + suit，实现 `Comparable`，包含花色比较逻辑）
- [x] 1.3 创建 `PdkHandType` 枚举（single/pair/triple/straight/consecutivePairs/airplane/bomb/rocket）
- [x] 1.4 创建 `PdkPlayedHand` 类（type + cards + 关键牌用于比较）
- [x] 1.5 创建 `PdkPlayer` 类（id/name/handCards/isAi）
- [x] 1.6 创建 `PdkGamePhase` 枚举（waiting/dealing/playing/roundEnd/gameOver）
- [x] 1.7 用 freezed 创建 `PdkGameState`（players/currentPlayerIndex/lastPlayedHand/passCount/phase/rankings）
- [x] 1.8 创建 `PdkNetworkAction` 类（type/cards JSON 序列化）

## 2. 游戏用例（domain/paodekai/usecases）

- [x] 2.1 创建 `DealCardsUseCase`：54 张牌洗牌分发，找出 ♠3 确定先手
- [x] 2.2 创建 `HandTypeUseCase`：识别选中牌的牌型，返回 `PdkHandType?`（不合法返回 null）
- [x] 2.3 创建 `CompareHandsUseCase`：比较两手 `PdkPlayedHand`，返回是否可以跟出
- [x] 2.4 创建 `ValidatePlayUseCase`：校验出牌合法性（包含首轮必须带 ♠3 校验）
- [x] 2.5 创建 `CalculateScoreUseCase`：按名次计算积分（+2/0/-2）

## 3. 验证器（domain/paodekai/validators）

- [x] 3.1 创建 `CardValidator`：检查单张/对子/三张/炸弹/王炸
- [x] 3.2 创建 `StraightValidator`：检查顺子（≥5 连续，无 2 和王）
- [x] 3.3 创建 `ConsecutiveValidator`：检查连对（≥3 对连续）和飞机（≥2 组连续三张）

## 4. 游戏状态管理（domain/paodekai/notifiers）

- [x] 4.1 创建 `PdkNotifier extends StateNotifier<PdkGameState>`
- [x] 4.2 实现 `startGame()`：调用 `DealCardsUseCase`，初始化状态
- [x] 4.3 实现 `playCards(playerId, cards)`：校验 → 更新 lastPlayedHand → 切换玩家 → 判断胜负
- [x] 4.4 实现 `pass(playerId)`：累加 `passCount`，若 passCount==2 则开新轮
- [x] 4.5 实现 `syncState(PdkGameState)`：供联机 Client 同步 Host 状态
- [x] 4.6 实现 `forcePlayCards(playerId)` 和 `forcePass(playerId)`：超时托管用
- [x] 4.7 暴露 `currentState` getter（供网络适配器访问）

## 5. AI 策略（domain/paodekai/ai）

- [x] 5.1 创建 `PdkAiStrategy` 类，实现 `decidePlay(gameState, playerId) → List<PdkCard>?`（null 表示 pass）
- [x] 5.2 实现起手策略：优先出最小单张，无单张则最小对子，最后才考虑三张/顺子
- [x] 5.3 实现跟牌策略：找最小合法跟牌；对手 ≤3 张时优先出炸弹
- [x] 5.4 实现 800–1500ms 随机延迟（`Future.delayed`）后触发 AI 行动

## 6. 联机网络适配器（core/network）

- [x] 6.1 创建 `PdkNetworkAdapter`，构造参数：`incomingStream / broadcastFn / notifier / isHost / localPlayerId`
- [x] 6.2 实现 Host 端：监听 `incomingStream` → 解析 `PdkNetworkAction` → 调用 notifier → 广播完整状态 JSON
- [x] 6.3 实现 Client 端：监听 `incomingStream` → 调用 `notifier.syncState` 更新本地状态
- [x] 6.4 实现 `sendAction(PdkNetworkAction)` 供 Client UI 调用
- [x] 6.5 实现 Host 端 35 秒超时 `Timer`：超时后调用 `forcePass` 或 `forcePlayCards`
- [x] 6.6 在 `dispose()` 中释放所有 Timer/StreamSubscription

## 7. 游戏页面 UI（presentation/pages/paodekai）

- [x] 7.1 创建 `PaodekaiPage`（`ConsumerStatefulWidget`），`initState` 锁横屏，`dispose` 恢复
- [x] 7.2 实现三方座位布局：本地玩家底部，对手左上/右上
- [x] 7.3 创建 `CardHand` widget：本地玩家手牌（可点击上浮选中）
- [x] 7.4 创建 `OpponentSeat` widget：对手背面手牌扇形 + 剩余张数
- [x] 7.5 创建 `PlayArea` widget：中央出牌区，展示最新出牌和玩家名称，附淡出动画
- [x] 7.6 实现操作按钮（出牌/不出），起手方隐藏"不出"，出牌不合法时禁用"出牌"
- [x] 7.7 使用 `GameBackButton` 实现左上角退出 + 确认弹窗
- [x] 7.8 创建 `GameResultDialog`：结算弹窗，显示三人名次/积分变化，提供"再来一局"和"返回首页"
- [x] 7.9 应用 `GameColors.bgTable` 背景色，使用深色渐变卡牌组件保持视觉风格一致

## 8. 路由与系统接入

- [x] 8.1 在 `domain/lan/entities/room_info.dart` 中添加 `GameType.paodekai` 枚举及 4 个 switch 分支（displayName/minPlayers/maxPlayers/routePath）
- [x] 8.2 更新 `room_info.g.dart` 和 `room.g.dart` 序列化映射（运行 `build_runner build`）
- [x] 8.3 在 `core/router/app_router.dart` 注册 `/paodekai` 路由，支持 `isOnline`/`networkAdapter` 参数
- [x] 8.4 在 `presentation/pages/home/home_provider.dart` 添加跑得快游戏卡片数据
- [x] 8.5 在 `home_page.dart` 的 `_supportsOnline` 方法中新增 `'paodekai'`
- [x] 8.6 在 `room_lobby_page.dart` 的 `_navigateToGame()` 添加 `GameType.paodekai` switch 分支
- [x] 8.7 在 `game_rules_page.dart` 的 `_getRulesContent()` 添加跑得快规则说明文本

## 9. 代码质量

- [x] 9.1 运行 `flutter analyze`，确保 0 issues
- [x] 9.2 确认所有 .dart 文件不超过 500 行，单个方法不超过 100 行
