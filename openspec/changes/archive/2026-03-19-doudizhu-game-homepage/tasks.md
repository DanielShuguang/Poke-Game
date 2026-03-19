# Tasks: 游戏首页与斗地主游戏页

## 1. 项目基础设施

- [x] 1.1 添加依赖（flutter_riverpod、freezed、freezed_annotation、build_runner）
- [x] 1.2 创建目录结构（presentation/pages/home、presentation/pages/doudizhu、domain/doudizhu、data/doudizhu）
- [x] 1.3 配置 GoRouter 路由（/、/doudizhu）
- [x] 1.4 创建共用 GameInfo 实体（domain/game/entities/game_info.dart）
- [x] 1.5 配置 ProviderScope 在 main.dart 中

## 2. 首页模块

- [x] 2.1 创建 HomePage 页面框架（ConsumerWidget）（presentation/pages/home/home_page.dart）
- [x] 2.2 创建 HomeNotifier 和 HomeProvider（presentation/pages/home/home_provider.dart）
- [x] 2.3 实现 GameCardWidget 游戏卡片组件（presentation/pages/home/widgets/game_card_widget.dart）
- [x] 2.4 实现游戏分类展示（按扑克牌类、棋类、其他分组）
- [x] 2.5 实现游戏状态徽章（available / coming soon / planned）
- [x] 2.6 实现点击跳转逻辑（可用游戏跳转、不可用游戏提示）
- [x] 2.7 实现下拉刷新功能

## 3. 斗地主领域层 - 实体

- [x] 3.1 创建 Card 实体（花色、点数、大小王）（domain/doudizhu/entities/card.dart）
- [x] 3.2 创建 Player 抽象接口（domain/doudizhu/entities/player.dart）
- [x] 3.3 创建 GameState 实体（游戏阶段、玩家手牌、当前出牌者）（domain/doudizhu/entities/game_state.dart）
- [x] 3.4 创建 GameConfig 配置实体（domain/doudizhu/entities/game_config.dart）
- [x] 3.5 创建 GameEvent 事件基类及子类（PlayCardsEvent、CallLandlordEvent）

## 4. 斗地主领域层 - 用例

- [x] 4.1 创建 DealCardsUseCase 发牌用例（domain/doudizhu/usecases/deal_cards_usecase.dart）
- [x] 4.2 创建 CallLandlordUseCase 叫地主用例（domain/doudizhu/usecases/call_landlord_usecase.dart）
- [x] 4.3 创建 PlayCardsUseCase 出牌用例（domain/doudizhu/usecases/play_cards_usecase.dart）
- [x] 4.4 创建 CheckWinnerUseCase 判断胜负用例（domain/doudizhu/usecases/check_winner_usecase.dart）

## 5. 斗地主领域层 - 牌型验证

- [x] 5.1 创建 CardCombination 枚举（单张、对子、三张、三带一、三带二、顺子、连对、飞机、炸弹、王炸）
- [x] 5.2 实现单张牌型验证
- [x] 5.3 实现对子牌型验证
- [x] 5.4 实现三张牌型验证
- [x] 5.5 实现三带一牌型验证
- [x] 5.6 实现三带二牌型验证
- [x] 5.7 实现顺子牌型验证
- [x] 5.8 实现连对牌型验证
- [x] 5.9 实现飞机牌型验证
- [x] 5.10 实现炸弹牌型验证
- [x] 5.11 实现王炸牌型验证
- [x] 5.12 创建 CardValidator 牌型验证器（整合所有验证逻辑）
- [x] 5.13 实现牌型大小比较逻辑

## 6. 斗地主 AI 模块

- [x] 6.1 创建 AiPlayer 实现 Player 接口（domain/doudizhu/ai/ai_player.dart）
- [x] 6.2 创建 AiStrategy 抽象接口（domain/doudizhu/ai/strategies/play_strategy.dart）
- [x] 6.3 实现 CallStrategy 叫地主策略（评估手牌强度决定是否叫地主）
- [x] 6.4 实现 PlayStrategy 出牌策略（分析牌型、选择最优出牌）
- [x] 6.5 实现 AI 延迟响应（1-2 秒模拟思考时间）

## 7. 斗地主数据层

- [x] 7.1 创建 CardModel 数据模型（data/doudizhu/models/card_model.dart）
- [x] 7.2 实现 GameRepository 接口（domain/doudizhu/repositories/game_repository.dart）
- [x] 7.3 实现 GameRepositoryImpl（data/doudizhu/repositories/game_repository_impl.dart）

## 8. 斗地主状态管理（Riverpod）

- [x] 8.1 创建 DoudizhuState 不可变状态类（使用 freezed）（presentation/pages/doudizhu/doudizhu_state.dart）
- [x] 8.2 创建 DoudizhuNotifier（presentation/pages/doudizhu/doudizhu_notifier.dart）
- [x] 8.3 实现 startGame() 方法
- [x] 8.4 实现 callLandlord(bool call) 方法
- [x] 8.5 实现 playCards(List<Card> cards) 方法
- [x] 8.6 实现 passTurn() 方法
- [x] 8.7 实现 toggleCardSelection(Card card) 方法
- [x] 8.8 创建 Provider 定义（doudizhuProvider）（presentation/pages/doudizhu/doudizhu_provider.dart）
- [x] 8.9 创建 UseCase Providers（dealCardsUseCaseProvider 等）
- [x] 8.10 运行 build_runner 生成 freezed 代码（暂不需要，使用普通类代替）

## 9. 斗地主 UI 组件

- [x] 9.1 创建 CardWidget 卡牌组件（自定义绘制，支持选中状态）（presentation/widgets/playing_card_widget.dart）
- [x] 9.2 创建 HandCardsWidget 手牌组件（展示玩家手牌，支持选择）（presentation/pages/doudizhu/widgets/hand_cards_widget.dart）
- [x] 9.3 创建 PlayerAreaWidget 玩家区域组件（显示 AI 玩家卡背和数量）（presentation/pages/doudizhu/widgets/player_area_widget.dart）
- [x] 9.4 创建 ActionButtonsWidget 操作按钮组件（叫地主/不叫、出牌/不出）（presentation/pages/doudizhu/widgets/action_buttons_widget.dart）
- [x] 9.5 创建 CenterPlayAreaWidget 中央出牌区域组件
- [x] 9.6 创建 LandlordCardsWidget 底牌展示组件

## 10. 斗地主游戏页面

- [x] 10.1 创建 DoudizhuGamePage 页面框架（ConsumerWidget）（presentation/pages/doudizhu/doudizhu_game_page.dart）
- [x] 10.2 实现游戏桌面布局（顶部 2 个 AI、底部玩家、中央出牌区）
- [x] 10.3 实现叫地主阶段 UI（显示叫地主/不叫按钮）
- [x] 10.4 实现出牌阶段 UI（显示出牌/不出按钮）
- [x] 10.5 实现当前玩家高亮指示
- [x] 10.6 实现地主标识显示
- [x] 10.7 实现游戏结算界面（胜负展示、再来一局、返回首页）

## 11. 集成测试

- [x] 11.1 测试首页游戏列表展示
- [x] 11.2 测试首页游戏跳转
- [x] 11.3 测试斗地主发牌逻辑
- [x] 11.4 测试斗地主叫地主流程
- [x] 11.5 测试斗地主牌型验证
- [x] 11.6 测试斗地主出牌流程
- [x] 11.7 测试斗地主 AI 行为
- [x] 11.8 测试斗地主胜负判定

## 12. 优化与完善

- [x] 12.1 添加卡牌选择动画效果
- [x] 12.2 添加出牌动画效果
- [x] 12.3 优化 AI 策略（根据测试反馈调整）
- [x] 12.4 处理边界情况（如非法操作、网络异常预留）
