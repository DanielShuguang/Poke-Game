## 1. Domain 实体层

- [x] 1.1 创建 `lib/domain/blackjack/entities/blackjack_card.dart`：牌面（suit/rank）、点数计算辅助方法
- [x] 1.2 创建 `lib/domain/blackjack/entities/blackjack_hand.dart`：手牌列表、点数计算（A 自动 1/11）、Blackjack/Bust/FiveCardCharlie 判定
- [x] 1.3 创建 `lib/domain/blackjack/entities/blackjack_player.dart`：玩家信息、筹码、下注额、手牌列表（支持 Split 多手）、行动状态
- [x] 1.4 创建 `lib/domain/blackjack/entities/blackjack_game_state.dart`（freezed）：牌堆、庄家手牌、玩家列表、当前玩家/手牌索引、阶段枚举（betting/dealing/playerTurn/dealerTurn/settlement）、toJson/fromJson（含 `includeAllCards` 参数）
- [x] 1.5 创建 `lib/domain/blackjack/entities/blackjack_game_config.dart`：fiveCardCharlie（默认 false）、dealerHitSoft17（默认 false）、initialChips

## 2. 游戏引擎 Use Cases

- [x] 2.1 创建 `lib/domain/blackjack/usecases/deal_cards_usecase.dart`：洗牌（6 副标准牌）、发 2 张给每位玩家和庄家（第二张为暗牌）
- [x] 2.2 创建 `lib/domain/blackjack/usecases/player_action_usecase.dart`：实现 Hit / Stand / Double / Split / Surrender 五种操作，返回新 `BlackjackGameState`
- [x] 2.3 创建 `lib/domain/blackjack/usecases/settle_usecase.dart`：逐手牌比较点数，计算赔付（Blackjack 1.5x、普通胜 1x、平局返还、五小龙胜），更新玩家筹码
- [x] 2.4 编写 `test/domain/blackjack/` 单元测试：点数计算覆盖 A 切换、Blackjack、Bust；结算覆盖全部场景

## 3. AI 庄家

- [x] 3.1 创建 `lib/domain/blackjack/ai/blackjack_dealer_ai.dart`：Hard 17 规则逻辑、Soft 17 可配置、每次 Hit 附加 600ms 延迟（单机 UI 动画用）
- [x] 3.2 编写庄家 AI 单元测试：验证 Hard 17 停牌、Soft 17 配置开关

## 4. 状态管理

- [x] 4.1 创建 `lib/presentation/pages/blackjack/providers/blackjack_game_notifier.dart`（StateNotifier）：封装引擎 use cases，暴露 bet / startGame / hit / stand / double / split / surrender 方法
- [x] 4.2 添加网络接口方法：`currentState` getter、`applyNetworkState`、`networkHit/Stand/Double/Split/Surrender`、`forcePlayerStand`

## 5. 联机网络适配器

- [x] 5.1 创建 `lib/domain/blackjack/entities/blackjack_network_action.dart`：action 枚举（hit/stand/double/split/surrender）+ playerId + handIndex
- [x] 5.2 创建 `lib/core/network/blackjack_network_adapter.dart`：start/stop、sendAction（Client）、_handleActionFromClient（Host 验证 + 路由）、_handleStateSyncFromHost（Client 应用状态）、_broadcastState（含暗牌过滤）、35s 超时 Stand Timer

## 6. 游戏 UI 页面

- [x] 6.1 创建 `lib/presentation/pages/blackjack/blackjack_page.dart`：ConsumerStatefulWidget，接收 `isOnline`/`networkAdapter`；`initState` 设置横屏
- [x] 6.2 实现牌桌布局：顶部庄家区（暗牌显示牌背）、底部玩家区、中部联机多玩家横向列表
- [x] 6.3 实现操作按钮栏：Hit / Stand / Double / Split / Surrender，根据手牌状态动态启用/禁用
- [x] 6.4 实现下注 UI：筹码面额按钮（10/50/100/500）、确认下注按钮、筹码余额显示
- [x] 6.5 实现结算覆盖层：展示每手牌胜负、筹码变化，3 秒后显示"再来一局"
- [x] 6.6 实现发牌/翻牌动画（AnimatedWidget 或 AnimationController）

## 7. 路由与接入

- [x] 7.1 在 `lib/core/router/app_router.dart` 注册 `/blackjack` 路由，参数：`isOnline`/`networkAdapter`
- [x] 7.2 在 `home_page.dart` 添加 21 点游戏卡片，`_supportsOnline` 加入 `blackjack`
- [x] 7.3 在 `room_lobby_page.dart` 的 `_navigateToGame()` 加入 `blackjack` 分支，创建 `BlackjackNetworkAdapter`
- [x] 7.4 在房间创建页支持 `blackjack` 游戏类型，人数限制 2–7 人

## 8. 验收测试

- [ ] 8.1 单机模式：完整玩一局（下注 → 发牌 → Hit/Stand → 庄家行动 → 结算）
- [ ] 8.2 单机 Split：两张同点数牌 → 分牌 → 各手操作 → 正确结算
- [ ] 8.3 联机模式：两台设备创建/加入房间 → 开始游戏 → Client 操作同步 → 超时自动 Stand
- [x] 8.4 运行 `flutter analyze` 确认 0 issues
