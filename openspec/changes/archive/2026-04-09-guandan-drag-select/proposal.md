## 为什么

斗地主和跑得快各自独立实现了拖拽选牌功能，两份代码在指针事件处理、位置缓存、命中检测方面高度重复（约 150 行相同逻辑）。掼蛋目前仅支持点选，需要新增拖拽选牌。与其再复制一份，不如提取共享模块，三个游戏统一接入，消除重复并降低后续维护成本。

## 变更内容

1. **新增共享拖拽选牌组件** `DragSelectCardHand<T>`（`lib/presentation/shared/widgets/`）
   - 封装指针事件流程（down → move → up → cancel）
   - 封装位置缓存（`Map<int, Rect>`）与 RenderBox 测量
   - 封装命中检测（反向遍历 Rect，支持重叠卡牌）
   - 封装拖拽与滚动互斥
   - 通过回调暴露游戏特定逻辑：`onDragUpdate`（预览计算）、`onDragEnd`（选中确认）、`onTap`（单击）
   - 可配置：拖拽阈值、卡牌渲染 builder、布局方向

2. **重构斗地主 `HandCardsWidget`**：移除内联拖拽逻辑，改用共享组件 + 游戏回调
3. **重构跑得快 `CardHand`**：移除内联拖拽逻辑，改用共享组件 + 游戏回调
4. **掼蛋 `GuandanHandWidget` 接入拖拽**：从 StatelessWidget 升级为使用共享组件，增加拖拽选牌 + 预览高亮

## 功能 (Capabilities)

### 新增功能
- `drag-select-shared`: 共享拖拽选牌组件，封装指针事件、位置缓存、命中检测、滚动互斥等通用逻辑，通过回调接口支持各游戏差异化的验证与预览计算

### 修改功能
- `pdk-drag-select`: 从内联实现改为使用共享组件，行为不变，仅实现方式变更
- `doudizhu-game`: 手牌组件从内联拖拽改为使用共享组件，行为不变

## 影响

- **新增文件**：`lib/presentation/shared/widgets/drag_select_card_hand.dart`
- **修改文件**：
  - `lib/presentation/pages/doudizhu/widgets/hand_cards_widget.dart`（重构拖拽逻辑）
  - `lib/presentation/pages/paodekai/widgets/card_hand.dart`（重构拖拽逻辑）
  - `lib/presentation/pages/guandan/guandan_hand_widget.dart`（接入拖拽）
  - 掼蛋父页面（传递新的拖拽回调参数）
- **风险**：斗地主和跑得快的重构属于行为不变的重构，需确保回归测试通过
- **无 API/依赖变更**：纯 presentation 层改动，不涉及网络协议或领域逻辑
