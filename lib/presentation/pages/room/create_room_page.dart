import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poke_game/domain/lan/entities/player_identity.dart';
import 'package:poke_game/domain/lan/entities/room.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';
import 'package:poke_game/presentation/pages/room/room_lobby_page.dart';
import 'package:uuid/uuid.dart';

/// 创建房间页面 Provider
final createRoomFormProvider = StateProvider<CreateRoomFormData>((ref) {
  return CreateRoomFormData(
    roomName: '',
    gameType: GameType.doudizhu,
    maxPlayers: GameType.doudizhu.fixedPlayerCount ?? GameType.doudizhu.maxPlayerCount,
    hasPassword: false,
    password: '',
  );
});

/// 创建房间表单数据
class CreateRoomFormData {
  final String roomName;
  final GameType gameType;
  final int maxPlayers;
  final bool hasPassword;
  final String password;

  CreateRoomFormData({
    required this.roomName,
    required this.gameType,
    required this.maxPlayers,
    required this.hasPassword,
    required this.password,
  });

  CreateRoomFormData copyWith({
    String? roomName,
    GameType? gameType,
    int? maxPlayers,
    bool? hasPassword,
    String? password,
  }) {
    return CreateRoomFormData(
      roomName: roomName ?? this.roomName,
      gameType: gameType ?? this.gameType,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      hasPassword: hasPassword ?? this.hasPassword,
      password: password ?? this.password,
    );
  }
}

/// 创建房间页面
class CreateRoomPage extends ConsumerWidget {
  const CreateRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formData = ref.watch(createRoomFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建房间'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoomNameField(context, ref, formData),
            const SizedBox(height: 16),
            _buildGameTypeSelector(context, ref, formData),
            const SizedBox(height: 16),
            _buildPasswordSection(context, ref, formData),
            const SizedBox(height: 24),
            _buildPlayerCountConfig(context, ref, formData),
            const SizedBox(height: 32),
            _buildCreateButton(context, ref, formData),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomNameField(
    BuildContext context,
    WidgetRef ref,
    CreateRoomFormData formData,
  ) {
    return TextField(
      decoration: const InputDecoration(
        labelText: '房间名称',
        hintText: '请输入房间名称',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.label_outline),
      ),
      maxLength: 20,
      onChanged: (value) {
        ref.read(createRoomFormProvider.notifier).state =
            formData.copyWith(roomName: value);
      },
    );
  }

  Widget _buildGameTypeSelector(
    BuildContext context,
    WidgetRef ref,
    CreateRoomFormData formData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '游戏类型',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GameType.values.map((type) {
            final isSelected = formData.gameType == type;

            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // 切换游戏类型时重置 maxPlayers 为新类型的最大值
                  final newMaxPlayers =
                      type.fixedPlayerCount ?? type.maxPlayerCount;
                  ref.read(createRoomFormProvider.notifier).state =
                      formData.copyWith(
                    gameType: type,
                    maxPlayers: newMaxPlayers,
                  );
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPasswordSection(
    BuildContext context,
    WidgetRef ref,
    CreateRoomFormData formData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('设置密码'),
          subtitle: const Text('其他玩家需要输入密码才能加入'),
          value: formData.hasPassword,
          onChanged: (value) {
            ref.read(createRoomFormProvider.notifier).state =
                formData.copyWith(hasPassword: value);
          },
        ),
        if (formData.hasPassword) ...[
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: '房间密码',
              hintText: '请输入房间密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            maxLength: 10,
            onChanged: (value) {
              ref.read(createRoomFormProvider.notifier).state =
                  formData.copyWith(password: value);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPlayerCountConfig(
    BuildContext context,
    WidgetRef ref,
    CreateRoomFormData formData,
  ) {
    final gameType = formData.gameType;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline),
                const SizedBox(width: 8),
                Text(
                  '人数配置',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (gameType.fixedPlayerCount != null)
              Text('固定人数：${gameType.fixedPlayerCount} 人')
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('最大人数：${formData.maxPlayers} 人'),
                  Text(
                    '${gameType.minPlayerCount} - ${gameType.maxPlayerCount} 人',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Slider(
                value: formData.maxPlayers.toDouble(),
                min: gameType.minPlayerCount.toDouble(),
                max: gameType.maxPlayerCount.toDouble(),
                divisions: gameType.maxPlayerCount - gameType.minPlayerCount,
                label: '${formData.maxPlayers} 人',
                onChanged: (value) {
                  ref.read(createRoomFormProvider.notifier).state =
                      formData.copyWith(maxPlayers: value.toInt());
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(
    BuildContext context,
    WidgetRef ref,
    CreateRoomFormData formData,
  ) {
    final canCreate = formData.roomName.isNotEmpty &&
        (!formData.hasPassword || formData.password.isNotEmpty);

    return ElevatedButton(
      onPressed: canCreate
          ? () => _createRoom(context, ref, formData)
          : null,
      child: const Text('创建房间'),
    );
  }

  void _createRoom(
    BuildContext context,
    WidgetRef ref,
    CreateRoomFormData formData,
  ) {
    // 验证表单
    if (formData.roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入房间名称')),
      );
      return;
    }

    if (formData.hasPassword && formData.password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入房间密码')),
      );
      return;
    }

    // 生成房间 ID 和玩家 ID
    const uuid = Uuid();
    final roomId = uuid.v4();
    final hostPlayerId = uuid.v4();

    // 人数：固定游戏类型取固定值，否则取用户选择的值
    final maxPlayerCount =
        formData.gameType.fixedPlayerCount ?? formData.maxPlayers;

    // 创建房间
    final room = Room(
      roomId: roomId,
      roomName: formData.roomName,
      gameType: formData.gameType,
      hostPlayerId: hostPlayerId,
      players: [
        PlayerIdentity(
          playerId: hostPlayerId,
          playerName: '房主',
          seatNumber: 1,
          status: PlayerStatus.online,
          isHost: true,
          joinedAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        ),
      ],
      status: RoomStatus.waiting,
      maxPlayerCount: maxPlayerCount,
      gameConfig: {},
      createdAt: DateTime.now(),
      password: formData.hasPassword ? formData.password : null,
    );

    // 设置房间到 LobbyProvider
    ref.read(lobbyProvider.notifier).setRoom(room, hostPlayerId);

    // 跳转到等待大厅
    context.push('/room/lobby');
  }
}
