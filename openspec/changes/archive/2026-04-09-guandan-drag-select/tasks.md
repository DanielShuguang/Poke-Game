## 1. 共享拖拽组件

- [x] 1.1 创建 `lib/presentation/shared/widgets/drag_select_card_hand.dart`，实现 `DragSelectCardHand` StatefulWidget：Listener 指针事件、`_DragSelectItem` 标记 Widget、Element 树遍历位置缓存（`Map<int, Rect>`）、反向命中检测、`dragThreshold` 可配、滚动互斥（`NeverScrollableScrollPhysics`）
- [x] 1.2 实现回调接口：`cardBuilder(int index, {bool isDragged, bool isPreview})` 渲染委托、`Set<int> Function(List<int>)? calculatePreview` 预览计算、`void Function(Set<int>)? onDragEnd` 选中确认、`void Function(int)? onTap` 单击

## 2. 斗地主重构

- [x] 2.1 重构 `lib/presentation/pages/doudizhu/widgets/hand_cards_widget.dart`：移除内联拖拽逻辑（`_isDragging`、`_draggedCardsList`、`_previewCards`、`_cachedCardRects`、指针事件方法），改用 `DragSelectCardHand`
- [x] 2.2 实现斗地主回调：`calculatePreview` 中调用 `CardValidator.findBestCombination / findMinBeatingCombination`，`onDragEnd` 中调用 `notifier.selectCardsByDrag`，保留 `ConsumerStatefulWidget` 以访问 Riverpod

## 3. 跑得快重构

- [x] 3.1 重构 `lib/presentation/pages/paodekai/widgets/card_hand.dart`：移除内联拖拽逻辑，改用 `DragSelectCardHand`，保留 `_CardWidget` 渲染逻辑
- [x] 3.2 实现跑得快回调：`calculatePreview` 中调用 `ValidatePlayUseCase`，`onDragEnd` 中调用 `onSelectionChanged`

## 4. 掼蛋接入

- [x] 4.1 重构 `lib/presentation/pages/guandan/widgets/guandan_hand_widget.dart`：水平手牌从 `Stack + AnimatedPositioned` 切换为 `DragSelectCardHand`，竖向手牌保留原 Stack 布局不变
- [x] 4.2 实现掼蛋拖拽回调：`calculatePreview` 中调用 `ValidateHandUsecase.validate`（注意用 `identical()` 做牌匹配），`onDragEnd` 通知父组件更新 `selectedIndices`
- [x] 4.3 在掼蛋游戏页面（`guandan_game_page.dart`）中为手牌组件传递拖拽回调参数，确保拖拽选中与现有点击选中、提示选中共存

## 5. 验证

- [x] 5.1 手动验证斗地主：拖拽选牌、点击选牌、预览高亮、组合匹配行为与重构前一致
- [x] 5.2 手动验证跑得快：拖拽选牌、4px 阈值、预览高亮、点击不被拖拽拦截
- [x] 5.3 手动验证掼蛋：拖拽选牌、预览高亮、点击选牌、百搭牌预览、竖向对手手牌不受影响
- [x] 5.4 运行 `flutter analyze` 确保无分析错误
