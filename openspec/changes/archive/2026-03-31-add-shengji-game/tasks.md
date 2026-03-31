# 升级游戏实现任务清单

## 1. 领域实体与核心类型

- [x] 1.1 创建 `lib/domain/shengji/entities/shengji_card.dart`：扑克牌实体（含大小王，复用 Suit 枚举）
- [x] 1.2 创建 `lib/domain/shengji/entities/trump_info.dart`：将牌信息值对象（级牌、将牌花色、判断方法）
- [x] 1.3 创建 `lib/domain/shengji/entities/shengji_player.dart`：玩家实体（队伍 ID、手牌、座位索引）
- [x] 1.4 创建 `lib/domain/shengji/entities/shengji_team.dart`：队伍实体（级别、得分、庄家标识）
- [x] 1.5 创建 `lib/domain/shengji/entities/shengji_game_state.dart`：游戏状态（阶段、玩家、队伍、底牌）
- [x] 1.6 创建 `lib/domain/shengji/entities/shengji_game_config.dart`：游戏配置（初始级别、AI 难度）

## 2. 出牌验证引擎

- [x] 2.1 创建 `lib/domain/shengji/validators/card_validator.dart`：牌型识别（单张、对子、拖拉机）
- [x] 2.2 实现拖拉机识别算法（连续对子检测）
- [x] 2.3 创建 `lib/domain/shengji/validators/play_validator.dart`：出牌验证（跟牌、杀牌、垫牌规则）
- [x] 2.4 实现将牌比较逻辑（大王 > 小王 > 级牌 > 将牌花色）
- [x] 2.5 创建 `lib/domain/shengji/validators/call_validator.dart`：叫牌验证（对子、拖拉机、无将）

## 3. 用例与核心逻辑

- [x] 3.1 创建 `lib/domain/shengji/usecases/deal_cards_usecase.dart`：发牌逻辑（108 张牌，留 8 张底牌）
- [x] 3.2 创建 `lib/domain/shengji/usecases/call_trump_usecase.dart`：叫牌逻辑（确定庄家和将牌）
- [x] 3.3 创建 `lib/domain/shengji/usecases/play_cards_usecase.dart`：出牌逻辑（验证、执行、轮转）
- [x] 3.4 创建 `lib/domain/shengji/usecases/calculate_score_usecase.dart`：计分逻辑（分值牌统计）
- [x] 3.5 创建 `lib/domain/shengji/usecases/settle_round_usecase.dart`：结算逻辑（升级判定）

## 4. AI 策略

- [x] 4.1 创建 `lib/domain/shengji/ai/strategies/call_strategy.dart`：叫牌策略（手牌评估、叫牌决策）
- [x] 4.2 创建 `lib/domain/shengji/ai/strategies/play_strategy.dart`：出牌策略（首出、跟牌、杀牌决策）
- [x] 4.3 实现团队配合逻辑（保护队友、信号传递）
- [x] 4.4 实现简单难度 AI（随机出合法牌）
- [x] 4.5 实现普通难度 AI（基本策略）

## 5. 游戏状态管理

- [x] 5.1 创建 `lib/domain/shengji/notifiers/shengji_notifier.dart`：游戏状态管理器
- [x] 5.2 实现叫牌阶段状态流转
- [x] 5.3 实现出牌阶段状态流转
- [x] 5.4 实现超时托管逻辑（35 秒自动操作）
- [x] 5.5 实现级别持久化（SharedPreferences）

## 6. 网络适配器

- [x] 6.1 创建 `lib/domain/shengji/entities/shengji_network_action.dart`：网络行动消息定义
- [x] 6.2 创建 `lib/core/network/shengji_network_adapter.dart`：局域网适配器
- [x] 6.3 实现 Host 消息处理（接收行动、执行验证、广播状态）
- [x] 6.4 实现 Client 消息发送（叫牌、出牌）
- [x] 6.5 实现状态序列化（toJson/fromJson，手牌隐私保护）

## 7. UI 界面

- [x] 7.1 创建 `lib/presentation/pages/shengji/shengji_page.dart`：主游戏页面（横屏布局）
- [x] 7.2 创建 `lib/presentation/pages/shengji/widgets/player_seat.dart`：玩家座位组件
- [x] 7.3 创建 `lib/presentation/pages/shengji/widgets/card_hand.dart`：手牌显示组件
- [x] 7.4 创建 `lib/presentation/pages/shengji/widgets/play_area.dart`：出牌区域组件
- [x] 7.5 创建 `lib/presentation/pages/shengji/widgets/score_board.dart`：计分板组件
- [x] 7.6 创建 `lib/presentation/pages/shengji/widgets/call_trump_dialog.dart`：叫牌界面
- [x] 7.7 创建 `lib/presentation/pages/shengji/widgets/game_result_dialog.dart`：结算界面
- [x] 7.8 实现退出确认对话框（统一样式）

## 8. 路由与接入

- [x] 8.1 修改 `lib/domain/lan/entities/room_info.dart`：GameType 枚举添加 `shengji`，switch 分支添加升级人数配置
- [x] 8.2 运行 `flutter pub run build_runner build` 生成序列化代码
- [x] 8.3 修改 `lib/core/router/app_router.dart`：注册 `/shengji` 路由
- [x] 8.4 修改 `lib/presentation/pages/home/home_provider.dart`：添加升级游戏卡片
- [x] 8.5 修改 `lib/presentation/pages/home/home_page.dart`：`_supportsOnline` 列表添加升级
- [x] 8.6 修改 `lib/presentation/pages/room/room_lobby_page.dart`：`_navigateToGame()` 添加升级分支
- [x] 8.7 修改 `lib/presentation/pages/room/game_rules_page.dart`：`_getRulesContent()` 添加升级规则

## 9. 测试与验收

- [x] 9.1 编写出牌验证单元测试（牌型识别、跟牌规则、将牌比较）
- [x] 9.2 编写计分结算单元测试（分值统计、升级判定）
- [x] 9.3 编写 AI 策略单元测试（叫牌决策、出牌决策）
- [x] 9.4 运行 `flutter analyze` 确保代码质量
- [x] 9.5 运行 `flutter test` 确保测试通过
- [ ] 9.6 真机测试单机 AI 对战
- [ ] 9.7 真机测试局域网联机
