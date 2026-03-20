# 局域网多人游戏模式 - 技术设计

## 上下文

### 背景
当前扑克游戏合集应用采用单机架构，所有游戏逻辑在本地执行，AI 对手通过本地策略算法实现。用户无法与真人对战，限制了社交娱乐场景。

### 当前状态
- 架构：Clean Architecture（presentation → domain → data）
- 状态管理：flutter_riverpod
- 网络能力：仅 HTTP（Dio），无实时通信
- 游戏实现：斗地主（单机人机对战）

### 约束
- 必须支持跨平台（Android/iOS/Windows/macOS/Linux）
- 无需互联网连接和账号系统
- 局域网内延迟需 < 100ms
- 不引入服务器依赖，采用 P2P 架构

### 利益相关者
- 玩家：希望与朋友对战，无需注册账号
- 开发者：需要可扩展的游戏框架

## 目标 / 非目标

**目标：**
- ✅ 实现设备在局域网内的自动发现与连接
- ✅ 创建可配置的游戏房间（游戏类型、人数）
- ✅ 实时同步游戏状态（发牌、出牌、叫地主）
- ✅ 支持跨平台对战（Android ↔ iOS ↔ Windows 等）
- ✅ 保持现有单机模式不受影响

**非目标：**
- ❌ 互联网对战（需服务器中转）
- ❌ 用户账号系统
- ❌ 游戏数据持久化（积分、排行榜）
- ❌ 语音/视频通话

## 决策

### 1. 网络通信方案

**决策：** 采用 **混合方案** - HTTP 服务发现 + WebSocket 实时通信

**理由：**
- **考虑过的方案：**
  - ❌ **纯 Socket TCP**：需要自行实现协议，复杂度高
  - ❌ **纯 HTTP 轮询**：延迟高（> 500ms），不适合实时游戏
  - ✅ **混合方案**：HTTP 用于房间发现，WebSocket 用于游戏实时同步

**实现：**
- 房主设备启动 HTTP 服务器（端口 8080），提供房间信息 API
- 所有设备通过 UDP 广播（端口 8081）或 mDNS 发现房间
- 玩家加入房间后，升级为 WebSocket 连接进行实时通信
- WebSocket 采用 `shelf_web_socket` + `web_socket_channel`（跨平台）

### 2. 房间架构

**决策：** 采用 **Host-Authoritative** 模型

**理由：**
- **考虑过的方案：**
  - ❌ **Peer-to-Peer 全对等**：状态同步复杂，容易冲突
  - ✅ **Host-Authoritative**：房主作为权威服务器，简化同步逻辑

**实现：**
- 房主负责：发牌、验证出牌、判断胜负、广播状态
- 客户端负责：UI 交互、发送操作、接收更新
- 断线处理：房主离开则房间解散，客户端断线可重连（60秒超时）

### 3. 状态同步策略

**决策：** 采用 **Delta 同步 + 事件溯源**

**理由：**
- **考虑过的方案：**
  - ❌ **全量同步**：每次传输完整游戏状态，带宽浪费
  - ✅ **Delta 同步**：仅传输变化部分（如玩家出的牌）
  - ✅ **事件溯源**：客户端保存事件日志，支持断线重连后快速恢复

**实现：**
- 核心数据结构：
  ```dart
  class GameEvent {
    final String eventId;
    final String type; // deal, play_cards, call_landlord
    final Map<String, dynamic> payload;
    final DateTime timestamp;
  }
  ```
- 房主维护事件日志（最多 100 条）
- 客户端重连时，发送 `lastEventId`，房主回传后续事件

### 4. 服务发现机制

**决策：** 采用 **UDP 广播 + mDNS 混合方案**

**理由：**
- **考虑过的方案：**
  - ❌ **纯 mDNS**：Windows/Linux 支持不完善
  - ❌ **纯 UDP 广播**：iOS 限制后台 UDP 接收
  - ✅ **混合方案**：Android/Windows 使用 UDP，iOS/macOS 使用 mDNS

**实现：**
- Android/Windows/Linux：
  - 房主每 2 秒广播 UDP 包（`{"type": "room_announce", "roomInfo": {...}}`）
  - 客户端监听 UDP 广播，解析房间信息
- iOS/macOS：
  - 使用 `nsd` 插件的 NSD (Network Service Discovery)
  - 房主注册服务 `_pokegame._tcp`，客户端浏览服务
- 备用方案：手动输入 IP 地址

### 5. 游戏逻辑抽象

**决策：** 引入 **Player Interface** 抽象层

**理由：**
- 现有游戏逻辑硬编码为 AI 对手
- 需要统一本地 AI 和远程真人的接口

**实现：**
```dart
abstract class PlayerInterface {
  Future<void> onCardsDealt(List<Card> cards);
  Future<PlayAction> requestPlay(GameState state);
  Future<CallAction> requestCall(GameState state);
  void onGameEvent(GameEvent event);
}

class LocalAIPlayer implements PlayerInterface { /* 现有 AI */ }
class RemotePlayer implements PlayerInterface { /* 网络代理 */ }
```

## 风险 / 权衡

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 网络不稳定导致游戏中断 | 高 | 实现断线重连 + 本地事件缓存 |
| 房主设备性能瓶颈 | 中 | 限制房间人数（最多 6 人）|
| 跨平台网络权限差异 | 高 | 提供手动输入 IP 备用方案 |
| WiFi 隔离（AP 隔离） | 高 | 检测网络环境，提示用户关闭 AP 隔离 |
| iOS 后台限制 | 中 | iOS 使用 mDNS 而非 UDP 广播 |

## 迁移计划

### 阶段 1：基础设施（1-2 周）
- 实现网络层（HTTP Server + WebSocket）
- 实现服务发现（UDP 广播 + mDNS）
- 创建房间管理基础结构

### 阶段 2：游戏集成（2-3 周）
- 重构斗地主游戏逻辑，引入 Player Interface
- 实现游戏状态序列化/反序列化
- 实现网络同步机制

### 阶段 3：UI 与体验优化（1-2 周）
- 房间创建/发现页面
- 等待大厅与玩家状态展示
- 聊天与表情系统

### 阶段 4：测试与优化（1 周）
- 跨平台兼容性测试
- 性能优化（延迟、带宽）
- 异常场景处理（断线、超时）

### 回滚策略
- 局域网模式作为可选功能，可独立禁用
- 单机模式保持不变，用户可随时切换
- 新增代码模块化，易于移除

## 开放问题

1. **是否需要支持观战模式？**
   - 当前设计未包含，可作为后续功能
   - 如需支持，需要额外的权限控制和同步逻辑

2. **是否需要游戏回放功能？**
   - 事件溯源机制已支持，只需添加 UI
   - 考虑存储限制（本地最多保存 10 局回放）

3. **如何处理作弊问题？**
   - Host-Authoritative 模型降低风险
   - 客户端仅提交操作，由房主验证合法性
   - 未考虑加密通信（局域网环境信任度高）
