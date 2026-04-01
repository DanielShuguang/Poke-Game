## 上下文

跑得快游戏（`PaodekaiPage` + `CardHand`）当前仅支持逐张点击选牌，缺少拖拽选牌和出牌提示功能。斗地主（`HandCardsWidget` + `ActionButtonsWidget`）已有成熟实现，本次设计直接参考并移植到跑得快，保持代码风格统一。

当前 `CardHand` 是 `StatelessWidget`，接收 `Set<int> selectedIndices` 和 `ValueChanged<int> onCardTap`；选牌逻辑和提示逻辑完全在 `PaodekaiPage` 中。

## 目标 / 非目标

**目标：**
- `CardHand` 升级为 `StatefulWidget`，支持 `Listener`（`onPointerDown/Move/Up/Cancel`）拖拽滑选手势
- 拖拽过程中实时高亮"预览牌组"（调用 `ValidatePlayUseCase` 计算最优组合）
- 拖拽结束时将预览牌组同步到已选状态
- 新增 `HintUseCase`（`domain/paodekai/usecases/hint_usecase.dart`）封装"找最小合法出法"
- `PaodekaiPage` 新增"提示"按钮，调用 `HintUseCase`，结果以 `hintIndices` 高亮手牌
- 与在线模式兼容：提示和拖拽仅在 `_isLocalTurn` 时启用

**非目标：**
- 不修改 `PdkGameNotifier` 状态逻辑
- 不修改 AI 策略或网络适配器
- 不引入新的外部依赖

## 决策

### D1：`CardHand` 升级为 `StatefulWidget` 还是保持 `StatelessWidget` + 外部状态

**决策**：升级为 `StatefulWidget`，内部持有拖拽状态（`_isDragging`、`_draggedCards`、`_previewIndices`）。

**理由**：拖拽中间状态（划过哪些牌、预览高亮）是纯 UI 状态，不需要 Riverpod 状态管理。外置状态会导致每次 `PointerMove` 都触发 `setState` 并重建父组件，升级为 StatefulWidget 隔离重建范围。参考斗地主 `HandCardsWidget` 同样采用此模式。

**替代方案**：保持 StatelessWidget，在 `PaodekaiPage` 用 `ValueNotifier` 管理 → 组件间耦合更高，pass-down 参数增多，放弃。

### D2：拖拽命中检测方案

**决策**：使用 `GlobalKey` + `RenderBox.globalToLocal` + `_cachedCardRects` 缓存。在 `build()` 的 `addPostFrameCallback` 中刷新缓存。命中检测遍历 `_DraggableCard` 子元素获取 `RenderBox` 位置。

**理由**：与斗地主实现完全一致，经过验证。`GestureDetector.onPanUpdate` 不适合跨卡牌边界的滑选，`Listener` 提供更底层的指针事件控制，拖拽时禁用 `SingleChildScrollView` 滚动（`NeverScrollableScrollPhysics`）避免冲突。

### D3：`HintUseCase` 的实现位置

**决策**：新增 `lib/domain/paodekai/usecases/hint_usecase.dart`，复用 `ValidatePlayUseCase` 和 `PdkAiStrategy._decideOpen/_decideFollow` 的逻辑，独立封装为 `const` UseCase。

**理由**：遵循项目 Clean Architecture 规范，domain 层 UseCase 无 Flutter 依赖，便于单元测试。不直接复用 AI 策略私有方法，因为提示逻辑与 AI 决策有细微差别（AI 会考虑危险度，提示只需最小合法牌）。

**替代方案**：在 `PaodekaiPage` 内联提示逻辑 → 违反分层原则，放弃。

### D4：提示按钮位置

**决策**：放在"出牌"按钮左侧，与斗地主 `ActionButtonsWidget` 的提示按钮位置一致。使用 `TextButton.icon(Icons.lightbulb_outline)` + 琥珀色。非本玩家回合时按钮隐藏（与出牌/不出同级控制）。

## 风险 / 权衡

- [卡牌 Rect 缓存过期] 手牌数量变化时 `_cachedCardRects` 需在下一帧刷新，中间帧可能命中错误的牌 → 缓解：每次 `build()` 都调度 `addPostFrameCallback` 刷新，与斗地主一致，实测无感知问题
- [SingleChildScrollView + 拖拽冲突] 拖拽时禁用滚动物理效果，松手后恢复 → 缓解：`_isDragging` 标志控制 `physics` 参数，已在斗地主验证
- [提示无解时的状态] 当玩家手牌无法大过上家且无炸弹时，`HintUseCase` 返回 `null`，提示按钮无响应 → 缓解：按钮 `onPressed: null` 禁用，符合斗地主同样处理方式
