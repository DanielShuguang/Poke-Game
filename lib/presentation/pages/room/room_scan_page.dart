import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:poke_game/domain/lan/entities/room.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';
import 'package:poke_game/presentation/pages/room/room_lobby_page.dart';
import 'package:poke_game/presentation/pages/room/room_scan_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';

/// 房间扫描页面
class RoomScanPage extends ConsumerWidget {
  const RoomScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomScanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('局域网对战'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.status == ScanStatus.scanning
                ? null
                : () => ref.read(roomScanProvider.notifier).startScan(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateRoomDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildNetworkStatus(context, ref, state),
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
      floatingActionButton: state.status == ScanStatus.scanning
          ? FloatingActionButton.extended(
              onPressed: () => ref.read(roomScanProvider.notifier).stopScan(),
              icon: const Icon(Icons.stop),
              label: const Text('停止扫描'),
            )
          : FloatingActionButton.extended(
              onPressed: () => ref.read(roomScanProvider.notifier).startScan(),
              icon: const Icon(Icons.search),
              label: const Text('扫描房间'),
            ),
    );
  }

  /// 网络状态
  Widget _buildNetworkStatus(
    BuildContext context,
    WidgetRef ref,
    RoomScanState state,
  ) {
    final networkCheck = state.networkCheck;

    if (networkCheck == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Colors.blue.shade100,
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              '正在检测网络环境...',
              style: TextStyle(color: Colors.blue.shade900),
            ),
          ],
        ),
      );
    }

    if (!networkCheck.canPlayLanGame) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Colors.red.shade100,
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade900),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                networkCheck.message ?? '网络不可用',
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(roomScanProvider.notifier).checkNetwork(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.green.shade100,
      child: Row(
        children: [
          Icon(Icons.wifi, color: Colors.green.shade900),
          const SizedBox(width: 12),
          Text(
            '已连接 WiFi (${networkCheck.localIp})',
            style: TextStyle(color: Colors.green.shade900),
          ),
        ],
      ),
    );
  }

  /// 主体内容
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    RoomScanState state,
  ) {
    if (state.status == ScanStatus.scanning && state.rooms.isEmpty) {
      return _buildScanningIndicator(context);
    }

    if (state.status == ScanStatus.idle && state.rooms.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    if (state.status == ScanStatus.error) {
      return _buildErrorState(context, ref, state);
    }

    if (state.rooms.isNotEmpty) {
      return _buildRoomList(context, ref, state);
    }

    return _buildEmptyState(context, ref);
  }

  /// 扫描中指示器
  Widget _buildScanningIndicator(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            '正在扫描局域网房间...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '请确保设备在同一 WiFi 网络下',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_find_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '点击下方按钮扫描房间',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showManualInputDialog(context, ref),
            icon: const Icon(Icons.edit),
            label: const Text('手动输入 IP 地址'),
          ),
        ],
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    RoomScanState state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? '发生错误',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(roomScanProvider.notifier).startScan(),
              icon: const Icon(Icons.refresh),
              label: const Text('重新扫描'),
            ),
          ],
        ),
      ),
    );
  }

  /// 房间列表
  Widget _buildRoomList(
    BuildContext context,
    WidgetRef ref,
    RoomScanState state,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.rooms.length,
      itemBuilder: (context, index) {
        final room = state.rooms[index];
        return _RoomCard(room: room);
      },
    );
  }

  /// 显示创建房间对话框
  void _showCreateRoomDialog(BuildContext context) {
    context.push('/room/create');
  }

  /// 显示手动输入 IP 对话框
  void _showManualInputDialog(BuildContext context, WidgetRef ref) {
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '8080');
    final logger = Logger();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动输入房间地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP 地址',
                hintText: '例如: 192.168.1.100',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: portController,
              decoration: const InputDecoration(
                labelText: '端口',
                hintText: '默认: 8080',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = ipController.text.trim();
              final port = int.tryParse(portController.text) ?? 8080;

              if (ip.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入 IP 地址')),
                );
                return;
              }

              Navigator.pop(context);

              // 尝试连接
              try {
                final dio = Dio();
                final response = await dio.get(
                  'http://$ip:$port/room/info',
                  options: Options(
                    receiveTimeout: const Duration(seconds: 5),
                    sendTimeout: const Duration(seconds: 5),
                  ),
                );

                if (response.statusCode == 200 && response.data != null) {
                  final roomJson = response.data as Map<String, dynamic>;
                  final room = Room.fromJson(roomJson);

                  // 跳转到等待大厅（客户端模式）
                  ref.read(lobbyProvider.notifier).initClientMode(
                        room,
                        const Uuid().v4(),
                      );

                  if (context.mounted) {
                    context.push('/room/lobby');
                  }
                }
              } catch (e) {
                logger.e('连接房间失败: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('连接失败: $e')),
                  );
                }
              }
            },
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }
}

/// 房间卡片
class _RoomCard extends ConsumerWidget {
  final RoomInfo room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: room.canJoin ? () => _joinRoom(context, ref) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.roomName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.games_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    room.gameType.displayName,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.currentPlayerCount}/${room.maxPlayerCount}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                room.hostDeviceName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    if (room.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '已满',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      );
    }

    if (room.status == RoomStatus.playing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '游戏中',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '可加入',
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 12,
        ),
      ),
    );
  }

  void _joinRoom(BuildContext context, WidgetRef ref) {
    final logger = Logger();

    // 显示加载指示器
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在加入房间: ${room.roomName}')),
    );

    // 尝试加入房间
    _joinRoomAsync(context, ref, logger);
  }

  Future<void> _joinRoomAsync(
    BuildContext context,
    WidgetRef ref,
    Logger logger,
  ) async {
    try {
      final dio = Dio();

      // 生成玩家信息
      const uuid = Uuid();
      final playerId = uuid.v4();
      final playerName = '玩家_${playerId.substring(0, 4)}';

      // 发送加入请求
      final response = await dio.post(
        'http://${room.networkAddress}:8080/room/join',
        data: {
          'playerId': playerId,
          'playerName': playerName,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // 获取房间完整信息
        final roomResponse = await dio.get(
          'http://${room.networkAddress}:8080/room/info',
        );

        if (roomResponse.statusCode == 200 && roomResponse.data != null) {
          final fullRoom = Room.fromJson(roomResponse.data as Map<String, dynamic>);

          // 初始化客户端模式
          ref.read(lobbyProvider.notifier).initClientMode(fullRoom, playerId);

          if (context.mounted) {
            context.push('/room/lobby');
          }
        }
      }
    } catch (e) {
      logger.e('加入房间失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入房间失败: $e')),
        );
      }
    }
  }
}
