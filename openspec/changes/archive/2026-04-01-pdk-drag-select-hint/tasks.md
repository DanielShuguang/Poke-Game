## 1. Domain：新增 HintUseCase

- [x] 1.1 新增 `lib/domain/paodekai/usecases/hint_usecase.dart`，封装"找最小合法出法"逻辑：起手方返回最小单张，跟牌方返回最小能压过上家的同类型组合或最小炸弹，无解返回 `null`
- [x] 1.2 为 `HintUseCase` 添加单元测试（`test/domain/paodekai/hint_usecase_test.dart`），覆盖起手/跟牌/仅炸弹/无出法四种场景

## 2. UI：升级 CardHand 为 StatefulWidget + 拖拽选牌

- [x] 2.1 将 `lib/presentation/pages/paodekai/widgets/card_hand.dart` 改为 `ConsumerStatefulWidget`（或 `StatefulWidget`），新增内部状态：`_isDragging`、`_draggedIndices`、`_previewIndices`
- [x] 2.2 新增 `GlobalKey _containerKey` 和 `Map<int, Rect> _cachedCardRects`，在 `build()` 的 `addPostFrameCallback` 中刷新卡牌位置缓存
- [x] 2.3 用 `Listener`（`onPointerDown/Move/Up/Cancel`）包裹 `SingleChildScrollView`，实现拖拽命中检测逻辑 `_detectCardUnderPosition`
- [x] 2.4 在 `_onPointerMove` 中调用 `ValidatePlayUseCase` 计算 `_previewIndices` 并触发 `setState`
- [x] 2.5 在 `_onPointerUp` 中确认选择：若 `_previewIndices` 非空则更新 `selectedIndices`（通过 `onSelectionChanged` 回调传出），清除拖拽状态
- [x] 2.6 新增 `hintIndices` 参数到 `CardHand`，在 `_CardWidget` 中增加 `isHint` 视觉状态（琥珀色边框 glow）
- [x] 2.7 拖拽期间将 `SingleChildScrollView.physics` 切换为 `NeverScrollableScrollPhysics`

## 3. UI：PaodekaiPage 操作区新增提示按钮

- [x] 3.1 在 `PaodekaiPage._PaodekaiPageState` 新增 `Set<int> _hintIndices = {}` 状态
- [x] 3.2 新增 `_onHint()` 方法：调用 `HintUseCase` 获取推荐牌组，将结果转换为 `hintIndices` 并 `setState`
- [x] 3.3 在操作按钮行（出牌/不出左侧）新增"提示"按钮（`TextButton.icon`，`Icons.lightbulb_outline`，琥珀色），无合法提示时 `onPressed: null` 禁用
- [x] 3.4 玩家点击手牌（`onCardTap`）或拖拽确认后清除 `_hintIndices`
- [x] 3.5 将 `_hintIndices` 传给 `CardHand`，将 `_selectedIndices` 的管理方式与新的 `onSelectionChanged` 回调对接

## 4. 验证

- [x] 4.1 运行 `flutter analyze`，确保 0 issues
- [x] 4.2 运行 `flutter test`，所有测试通过（含新增 `hint_usecase_test.dart`）
- [x] 4.3 手工测试：单机模式下验证拖拽选牌、提示高亮、出牌流程正常
