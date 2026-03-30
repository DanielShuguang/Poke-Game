## 1. Domain 实体层

- [x] 1.1 创建 `lib/domain/niuniu/entities/niuniu_card.dart`：复用 `Suit`（typedef），rank 1-13（A=1, J=11, Q=12, K=13），`pointValue` getter（J/Q/K/10 均返回 10，其余返回 rank）
- [x] 1.2 创建 `lib/domain/niuniu/entities/niuniu_hand.dart`：持有5张牌，枚举 C(5,3) 组合判断有无牛，计算 `NiuniuRank`（noPoints/niu1~niu9/niuNiu/fiveSmall/bomb）、`multiplier`（×1/×2/×3/×5）、`compareTo(other)`
- [x] 1.3 创建 `lib/domain/niuniu/entities/niuniu_player.dart`：玩家ID、昵称、筹码、下注额、手牌（`NiuniuHand?`）、角色（bankerRole/punterRole）、状态（waiting/bet/broke）
- [x] 1.4 创建 `lib/domain/niuniu/entities/niuniu_game_state.dart`（freezed）：牌堆、庄家ID、玩家列表、阶段枚举（betting/dealing/showdown/settlement）、`toJson`/`fromJson`（含 `includeAllCards` 参数，showdown 前隐藏他人手牌）
- [x] 1.5 创建 `lib/domain/niuniu/entities/niuniu_game_config.dart`：`deckCount`（默认6）、`initialChips`（默认1000）、`aiDelayMs`（默认400）
- [x] 1.6 创建 `lib/domain/niuniu/entities/niuniu_network_action.dart`：`NiuniuActionType`（bet）+ `playerId` + `amount`

## 2. 游戏引擎 Use Cases

- [x] 2.1 创建 `lib/domain/niuniu/usecases/deal_niuniu_usecase.dart`：从牌堆为每位玩家发5张牌，发牌后阶段切换为 `showdown`
- [x] 2.2 创建 `lib/domain/niuniu/usecases/settle_niuniu_usecase.dart`：将每位闲家手牌与庄家比较，按倍率结算筹码（闲家胜：赢 `bet × 闲家倍率`；庄家胜/平局：赢 `bet × 闲家倍率`）
- [x] 2.3 编写 `test/domain/niuniu/niuniu_engine_test.dart`：覆盖无牛/牛1~牛9/牛牛/五小牛/炸弹判定，compareTo 全场景，结算计算正确性

## 3. AI

- [x] 3.1 创建 `lib/domain/niuniu/ai/niuniu_ai.dart`：`decideBet(chips)` 返回 `[50, min(200, chips)]` 随机整数；`runAsync(notifier, aiPlayerIds)` 依次为 AI 闲家执行下注（带 `aiDelayMs` 延迟）
- [x] 3.2 编写 `test/domain/niuniu/niuniu_ai_test.dart`：验证下注范围合法、筹码不足时不超限

## 4. 状态管理

- [x] 4.1 创建 `lib/presentation/pages/niuniu/providers/niuniu_game_notifier.dart`（StateNotifier）：封装引擎 use cases，暴露 `init`、`bet`、`startGame`（发牌）、`settle` 方法
- [x] 4.2 添加网络接口方法：`currentState` getter、`applyNetworkState`、`networkBet`、`forceMinBet`（超时托管）

## 5. 联机网络适配器

- [x] 5.1 创建 `lib/core/network/niuniu_network_adapter.dart`：`_NiuniuMessageType.action = 'niuniu_action'`、`stateSync = 'niuniu_state'`；`sendAction`（Client）；`_handleActionFromClient`（Host 验证 playerId → 调用 notifier → 广播状态）；`_handleStateSyncFromHost`（Client 应用状态）；`_broadcastState`（showdown 前用 `includeAllCards: false`，showdown 后用 `true`）；35s 超时 → `forceMinBet`

## 6. 游戏 UI 页面

- [x] 6.1 创建 `lib/presentation/pages/niuniu/niuniu_page.dart`：`ConsumerStatefulWidget`，接收 `isOnline`/`networkAdapter`；`initState` 设置横屏，初始化单机游戏（1人类+3AI）
- [x] 6.2 实现下注区：筹码面额按钮（10/50/100/500）、确认下注按钮、筹码余额显示、不足时禁用对应面额
- [x] 6.3 实现牌桌布局：顶部庄家区（5张牌 + 牌型标签）、底部闲家横向列表（每人5张牌 + 牌型倍率）
- [x] 6.4 实现翻牌动画：showdown 阶段庄家先翻，闲家依次翻开（400ms 间隔，单机模式）
- [x] 6.5 实现结算覆盖层：每位玩家显示 `+X` / `-X` 筹码变化（赢绿/输红），3秒后显示"再来一局"按钮
- [x] 6.6 联机等待提示：非本地玩家下注时显示"等待其他玩家下注..."并禁用下注按钮

## 7. 路由与接入

- [x] 7.1 在 `lib/core/router/app_router.dart` 注册 `/niuniu` 路由，参数：`isOnline`/`networkAdapter`
- [x] 7.2 在 `lib/domain/lan/entities/room_info.dart` 添加 `GameType.niuniu`，补全全部 switch 分支（displayName='牛牛', minPlayers=2, maxPlayers=6）；更新 `room_info.g.dart` 和 `room.g.dart` 序列化映射
- [x] 7.3 在 `home_provider.dart` 中将牛牛 `status` 改为 `GameStatus.available`；在 `home_page.dart` 的 `_supportsOnline` 加入 `'niuniu'`
- [x] 7.4 在 `room_lobby_page.dart` 的 `_navigateToGame()` 加入 `niuniu` 分支，创建 `NiuniuNetworkAdapter` 并跳转
- [x] 7.5 在 `game_rules_page.dart` 添加牛牛规则文本（GameType.niuniu case）
- [x] 7.6 在房间创建页支持 `niuniu` 游戏类型，人数限制 2~6 人（`create_room_page.dart` 使用 `GameType.values` 动态遍历，无需修改）

## 8. 验收测试

- [x] 8.1 单机模式：完整玩一局（下注 → AI自动下注 → 发牌 → 翻牌 → 结算）
- [x] 8.2 特殊牌型：验证五小牛(×5)、炸弹(×5)、牛牛(×3) 的倍率结算正确
- [x] 8.3 联机模式：两台设备创建/加入房间 → 开始游戏 → Client 下注同步 → 超时自动最小下注
- [x] 8.4 运行 `flutter analyze` 确认 0 issues
