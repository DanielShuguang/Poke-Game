## 上下文

斗地主（`hand_cards_widget.dart`, 269行）和跑得快（`card_hand.dart`, 344行）各自实现了拖拽选牌，核心机制相同：`Listener` 指针事件 → 位置缓存（Element 树遍历）→ 命中检测（反向遍历 Rect）→ 预览计算 → 选中确认。掼蛋（`guandan_hand_widget.dart`, 172行）仅支持点击选牌。

三个实现的差异点：

| 维度 | 斗地主 | 跑得快 | 掼蛋（现状） |
|------|--------|--------|------------|
| 选中数据 | `Card` 对象 | `int` 索引 | `int` 索引 |
| 拖拽阈值 | 0（立即） | 4px | 无 |
| 布局 | `Row` + ScrollView | `Row` + ScrollView | `Stack` + Positioned |
| 预览验证 | `CardValidator` | `ValidatePlayUseCase` | 无 |
| 标记 Widget | `_DraggableCard` | `_CardItem` | 无 |
| 状态类型 | ConsumerStatefulWidget | StatefulWidget | StatelessWidget |

## 目标 / 非目标

**目标：**
- 提取共享拖拽选牌组件 `DragSelectCardHand`，封装通用逻辑
- 斗地主和跑得快重构为使用共享组件，行为完全不变
- 掼蛋接入拖拽选牌，获得与斗地主/跑得快一致的交互体验

**非目标：**
- 不改变任何游戏的牌型验证逻辑或 AI 行为
- 不改变卡牌渲染样式（各游戏保留自己的卡牌 Widget）
- 不支持竖向拖拽（仅水平手牌需要拖拽）
- 不改变联机协议或 NetworkAdapter

## 决策

### D1：统一使用索引（`int`）作为选中标识

**选择**：共享组件内部全部使用 `int` 索引，不使用 `Card` 对象。

**理由**：
- 跑得快和掼蛋已使用索引
- 掼蛋两副牌存在相同 suit+rank 的牌，用对象相等会命中多张（已知问题，见 MEMORY.md）
- 斗地主可在回调中通过 `cards[index]` 映射回 `Card` 对象

**替代方案**：泛型 `<T>` — 增加复杂度，且掼蛋的 `identical()` 问题仍需特殊处理，收益不大。

### D2：回调式预览计算

**选择**：共享组件通过 `Set<int> Function(List<int> draggedIndices)` 回调让各游戏提供预览逻辑。

**理由**：
- 预览计算是同步的，回调模式简单直接
- 各游戏验证器差异大（CardValidator / ValidatePlayUseCase / ValidateHandUsecase），无法统一
- 回调在 `_onPointerMove` 内同步调用，无需额外 setState 往返

**替代方案**：受控 `previewIndices` prop + `onDragUpdate` 回调 — 需要父组件 setState 再重新传入，多一次 rebuild。

### D3：统一 Row 布局，掼蛋从 Stack 切换

**选择**：共享组件采用 `Row` + `SingleChildScrollView` 布局，掼蛋水平手牌从 `Stack + AnimatedPositioned` 切换为 `Row`。

**理由**：
- 斗地主和跑得快已用 Row，Element 树遍历命中标记 Widget 的方式成熟可靠
- 掼蛋 Stack 布局中 `left: i * slotW` 的重叠效果，Row 中用 `margin` 或负 padding 同样可实现
- 选中抬起效果：跑得快已用 `Matrix4.translationValues(0, -12, 0)` 在 Row 中实现

**替代方案**：同时支持 Stack/Row 两种布局的命中检测 — 位置缓存逻辑需两套，复杂度翻倍，当前无实际需求。

### D4：可配置拖拽阈值，默认 4px

**选择**：`dragThreshold` 参数，默认 4px（跑得快模式），斗地主可传 0。

**理由**：
- 4px 阈值能有效区分"点击"和"拖拽"，避免手指微抖触发误拖拽
- 跑得快的 4px 阈值经过实际验证体验良好
- 斗地主当前无阈值（立即拖拽），改为 4px 也不影响体验，但保留配置灵活性

### D5：标记 Widget 用于位置缓存

**选择**：共享组件内置标记 Widget `_DragSelectItem`，通过 Element 树遍历识别位置。

**理由**：
- 这是斗地主和跑得快已验证的方案
- GlobalKey-per-card 方案在大量卡牌时 key 管理繁琐
- Element 树遍历无需额外 key，标记 Widget 本身就是位置锚点

## 风险 / 权衡

| 风险 | 缓解 |
|------|------|
| 斗地主重构后行为回归 | 重构前后用单元测试 + 手动测试验证拖拽选牌、点击选牌、预览高亮行为一致 |
| 掼蛋 Stack→Row 布局切换视觉差异 | 用 margin 精确还原卡牌重叠间距和选中抬起效果 |
| 掼蛋竖向手牌（对手）不需要拖拽 | 竖向手牌保留原 Stack 布局，仅水平本家手牌使用共享组件 |
| 共享组件 API 过早固化 | 仅 3 个游戏使用，API 已有足够样本验证，后续新游戏可扩展参数 |
