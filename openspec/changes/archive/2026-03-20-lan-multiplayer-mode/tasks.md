# 局域网多人游戏模式 - 实施任务清单

## 1. 基础设施搭建

- [x] 1.1 添加网络相关依赖到 pubspec.yaml
  - web_socket_channel
  - shelf
  - shelf_web_socket
  - nsd (Android/iOS)
  - multicast_dns (跨平台备选)
- [x] 1.2 创建网络层目录结构
  - lib/core/network/
  - lib/domain/lan/
  - lib/presentation/pages/room/
- [x] 1.3 配置平台权限
  - Android: ACCESS_WIFI_STATE, CHANGE_WIFI_MULTICAST_STATE
  - iOS: Bonjour 服务权限 (Info.plist)
- [x] 1.4 创建基础数据模型
  - GameEvent (事件模型)
  - RoomInfo (房间信息)
  - PlayerIdentity (玩家身份)

## 2. 局域网发现功能 (lan-discovery)

- [x] 2.1 实现 UDP 广播服务 (Android/Windows/Linux)
  - 创建 UdpBroadcaster 类
  - 实现 2 秒间隔广播房间信息
  - 实现 UDP 监听和解析
- [x] 2.2 实现 mDNS 服务发现 (iOS/macOS)
  - 创建 NsdService 类
  - 实现服务注册 (_pokegame._tcp)
  - 实现服务浏览和解析
- [x] 2.3 实现网络环境检测
  - WiFi 连接状态检测
  - AP 隔离检测与提示
  - 手动 IP 输入备用方案
- [x] 2.4 创建房间扫描 UI
  - 扫描中加载动画
  - 房间列表展示
  - 刷新和停止扫描按钮

## 3. 房间管理功能 (room-management)

- [x] 3.1 实现 HTTP 服务器 (房主端)
  - 创建 RoomServer 类 (基于 shelf)
  - 提供房间信息 API (GET /room/info)
  - 提供加入房间 API (POST /room/join)
- [x] 3.2 实现 WebSocket 连接管理
  - 创建 WebSocketManager 类
  - 处理客户端连接和断开
  - 实现消息广播
- [x] 3.3 实现房间生命周期管理
  - 创建 Room 实体类
  - 实现房间创建、销毁逻辑
  - 实现玩家加入、退出逻辑
- [x] 3.4 实现房间状态同步
  - 玩家列表变更广播
  - 房间配置变更通知
  - 房主离线检测 (60 秒超时)
- [x] 3.5 创建房间管理 UI
  - 创建房间页面 (选择游戏类型、人数)
  - 等待大厅页面 (玩家列表、准备状态)
  - 房主控制面板 (踢人、开始游戏)

## 4. 玩家管理功能 (player-management)

- [x] 4.1 创建玩家实体和仓库接口
  - Player 实体类 (id, name, seat, status)
  - PlayerRepository 接口
- [x] 4.2 实现玩家状态管理
  - 准备/取消准备逻辑
  - 玩家名称自定义
  - 座位分配算法
- [x] 4.3 实现断线重连机制
  - 心跳检测 (5 秒 Ping/Pong)
  - 事件日志缓存 (客户端保存最近 100 条)
  - 重连后状态恢复
- [x] 4.4 创建玩家信息 UI
  - 玩家头像和名称显示
  - 准备状态图标
  - 玩家详情弹窗

## 5. 游戏选择功能 (game-selection)

- [x] 5.1 创建游戏类型配置
  - GameType 枚举和元数据
  - 各游戏的人数限制配置
  - 游戏规则配置模板
- [x] 5.2 实现游戏选择逻辑
  - 游戏类型列表加载
  - 人数验证逻辑 (固定人数 vs 范围)
  - 规则配置 UI
- [x] 5.3 实现游戏规则展示
  - 规则详情页面
  - 配置变更全员通知
  - 准备状态重置

## 6. 网络同步功能 (network-sync)

- [x] 6.1 实现事件溯源机制
  - GameEventRepository
  - 事件存储和查询
  - 事件 ID 生成 (UUID)
- [x] 6.2 实现游戏状态序列化
  - GameState.toJson() / fromJson()
  - Card 和 Player 序列化
  - 压缩大消息 (gzip, >1KB)
- [x] 6.3 实现操作验证与广播
  - 出牌合法性验证
  - 叫地主验证
  - 批量消息合并发送
- [x] 6.4 实现网络延迟优化
  - 消息队列管理
  - 心跳超时检测 (15 秒)
  - 断线处理流程

## 7. 聊天系统功能 (chat-system)

- [x] 7.1 创建聊天消息模型
  - web_socket_channel
  - shelf
  - shelf_web_socket
  - nsd (Android/iOS)
  - multicast_dns (跨平台备选)
- [x] 7.2 实现聊天消息同步
- [x] 7.3 实现敏感词过滤
- [x] 7.4 实现房主禁言功能
- [x] 7.5 创建聊天 UI

## 8. 斗地主游戏适配 (doudizhu-game)

- [x] 8.1 创建 Player Interface 抽象层
  - PlayerInterface 抽象类
  - onCardsDealt() 方法
  - requestPlay() 方法
  - requestCall() 方法
  - onGameEvent() 方法
- [x] 8.2 重构现有 AI 为 LocalAIPlayer
  - 实现 PlayerInterface
  - 保持现有策略逻辑
- [x] 8.3 创建 RemotePlayer 实现
  - 实现 PlayerInterface
  - 通过网络代理玩家操作
- [x] 8.4 重构游戏初始化逻辑
- [x] 8.5 实现游戏状态网络同步
- [x] 8.6 实现断线处理

## 9. UI 与体验优化

- [x] 9.1 实现路由配置
- [x] 9.2 优化跨平台 UI 适配
- [x] 9.3 添加用户引导
- [x] 9.4 性能优化

## 10. 测试与发布

- [x] 10.1 单元测试
- [x] 10.2 集成测试
- [x] 10.3 跨平台兼容性测试
- [x] 10.4 性能测试
- [x] 10.5 发布准备
