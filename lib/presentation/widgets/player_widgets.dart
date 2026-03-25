import 'package:flutter/material.dart';
import 'package:poke_game/domain/lan/entities/player_identity.dart';

/// 玩家头像组件
class PlayerAvatar extends StatelessWidget {
  final PlayerIdentity player;
  final double size;
  final bool showStatus;
  final VoidCallback? onTap;

  const PlayerAvatar({
    super.key,
    required this.player,
    this.size = 48,
    this.showStatus = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getBackgroundColor(context),
              border: Border.all(
                color: _getBorderColor(context),
                width: 2,
              ),
            ),
            child: Center(
              child: player.isHost
                  ? Icon(
                      Icons.star,
                      color: Colors.white,
                      size: size * 0.5,
                    )
                  : Text(
                      '${player.seatNumber}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          if (showStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (player.isHost) return Colors.amber;
    return Theme.of(context).colorScheme.primary;
  }

  Color _getBorderColor(BuildContext context) {
    if (player.status == PlayerStatus.ready) {
      return Colors.green;
    }
    return Colors.transparent;
  }

  Color _getStatusColor() {
    switch (player.status) {
      case PlayerStatus.online:
        return Colors.grey;
      case PlayerStatus.ready:
        return Colors.green;
      case PlayerStatus.playing:
        return Colors.blue;
      case PlayerStatus.disconnected:
        return Colors.orange;
      case PlayerStatus.offline:
        return Colors.red;
      case PlayerStatus.muted:
        return Colors.purple;
    }
  }
}

/// 玩家信息卡片
class PlayerInfoCard extends StatelessWidget {
  final PlayerIdentity player;
  final bool isCurrentPlayer;
  final bool showActions;
  final VoidCallback? onKick;
  final VoidCallback? onMute;
  final VoidCallback? onTap;
  final void Function(String playerId, String playerName)? onPrivateMessage;

  const PlayerInfoCard({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
    this.showActions = false,
    this.onKick,
    this.onMute,
    this.onTap,
    this.onPrivateMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isCurrentPlayer
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PlayerAvatar(
                player: player,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.playerName,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.isHost) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '房主',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 14,
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          player.statusText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showActions && !isCurrentPlayer) ...[
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => _showPrivateMessageDialog(context),
                  tooltip: '私聊',
                ),
                if (onMute != null)
                  IconButton(
                    icon: Icon(
                      player.isMuted ? Icons.volume_off : Icons.volume_up,
                    ),
                    onPressed: onMute,
                    tooltip: player.isMuted ? '解除禁言' : '禁言',
                  ),
                if (onKick != null)
                  IconButton(
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: onKick,
                    tooltip: '踢出',
                    color: Colors.red,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (player.status) {
      case PlayerStatus.online:
        return Icons.circle_outlined;
      case PlayerStatus.ready:
        return Icons.check_circle_outline;
      case PlayerStatus.playing:
        return Icons.play_circle_outline;
      case PlayerStatus.disconnected:
        return Icons.warning_amber;
      case PlayerStatus.offline:
        return Icons.cancel_outlined;
      case PlayerStatus.muted:
        return Icons.volume_off;
    }
  }

  Color _getStatusColor() {
    switch (player.status) {
      case PlayerStatus.online:
        return Colors.grey;
      case PlayerStatus.ready:
        return Colors.green;
      case PlayerStatus.playing:
        return Colors.blue;
      case PlayerStatus.disconnected:
        return Colors.orange;
      case PlayerStatus.offline:
        return Colors.red;
      case PlayerStatus.muted:
        return Colors.purple;
    }
  }

  /// 显示私聊对话框
  void _showPrivateMessageDialog(BuildContext context) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('私聊: ${player.playerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final message = messageController.text.trim();
              if (message.isNotEmpty) {
                Navigator.pop(context);
                onPrivateMessage?.call(player.playerId, player.playerName);

                // 显示发送成功提示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已发送消息给 ${player.playerName}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }
}

/// 玩家详情弹窗
void showPlayerDetails(BuildContext context, PlayerIdentity player) {
  showModalBottomSheet(
    context: context,
    builder: (context) => _PlayerDetailsSheet(player: player),
  );
}

class _PlayerDetailsSheet extends StatelessWidget {
  final PlayerIdentity player;

  const _PlayerDetailsSheet({required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlayerAvatar(player: player, size: 64, showStatus: false),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.playerName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.seatNumber}号位',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow(context, '状态', player.statusText),
          if (player.deviceName != null)
            _buildInfoRow(context, '设备', player.deviceName!),
          if (player.ipAddress != null)
            _buildInfoRow(context, 'IP', player.ipAddress!),
          if (player.joinedAt != null)
            _buildInfoRow(
              context,
              '加入时间',
              '${player.joinedAt!.hour}:${player.joinedAt!.minute.toString().padLeft(2, '0')}',
            ),
          if (player.isMuted && player.muteEndTime != null)
            _buildInfoRow(
              context,
              '禁言结束',
              '${player.muteEndTime!.hour}:${player.muteEndTime!.minute.toString().padLeft(2, '0')}',
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
