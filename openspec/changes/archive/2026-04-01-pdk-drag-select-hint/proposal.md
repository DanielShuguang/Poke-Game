## 为什么

跑得快游戏目前手牌交互仅支持逐张点击选牌，缺少拖拽滑选功能，操作效率低；且出牌前无任何合法牌型提示，玩家必须自行判断，上手门槛高。斗地主已有成熟的拖拽选牌和"提示"按钮机制，跑得快应对齐以保持产品体验一致性。

## 变更内容

- **新增**：手牌区支持横向拖拽滑选——手指滑过牌面即可批量选中/取消，与斗地主体验对齐
- **新增**：拖拽预览高亮——拖拽过程中自动计算并高亮最优合法牌型（类似斗地主 `_previewCards`）
- **新增**：出牌提示按钮（💡提示）——点击后自动推荐当前最小合法出法并高亮对应手牌
- **修改**：`CardHand` widget 从纯 StatelessWidget 升级为 StatefulWidget，支持拖拽手势与提示高亮状态
- **修改**：`PaodekaiPage` 操作区新增"提示"按钮，传递 `hintIndices` 给 `CardHand`

## 功能 (Capabilities)

### 新增功能
- `pdk-drag-select`: 跑得快手牌区拖拽滑选与拖拽预览高亮
- `pdk-hint`: 跑得快出牌提示（推荐最小合法牌组，高亮手牌）

### 修改功能
- `paodekai-ui`: `CardHand` 组件新增拖拽手势与提示状态参数（规范级接口变更）

## 影响

- `lib/presentation/pages/paodekai/widgets/card_hand.dart` — 重构为 StatefulWidget，增加拖拽 Listener 和提示高亮
- `lib/presentation/pages/paodekai/paodekai_page.dart` — 新增提示逻辑，传递 `hintIndices` 给 `CardHand`
- `lib/domain/paodekai/usecases/validate_play_usecase.dart` — 复用（只读），无需修改
- `lib/domain/paodekai/usecases/hint_usecase.dart` — 新增 UseCase，封装"找最小合法出法"逻辑
