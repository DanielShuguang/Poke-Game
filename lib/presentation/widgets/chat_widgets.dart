import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/lan/entities/chat_message.dart';

/// 聊天面板组件
class ChatPanel extends ConsumerStatefulWidget {
  final String currentPlayerId;
  final Function(String message)? onSendMessage;
  final Function(String emojiId)? onSendEmoji;

  const ChatPanel({
    super.key,
    required this.currentPlayerId,
    this.onSendMessage,
    this.onSendEmoji,
  });

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _messageController = TextEditingController();
  bool _showEmojiPanel = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 这里应该从 provider 获取消息，简化处理
    final messages = <ChatMessage>[];

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('暂无消息'))
              : ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return _ChatMessageItem(
                      message: message,
                      isOwnMessage: message.senderId == widget.currentPlayerId,
                    );
                  },
                ),
        ),

        // 表情面板
        if (_showEmojiPanel) _buildEmojiPanel(),

        // 输入区域
        _buildInputArea(context),
      ],
    );
  }

  Widget _buildEmojiPanel() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: PresetEmoji.defaultEmojis.length,
        itemBuilder: (context, index) {
          final emoji = PresetEmoji.defaultEmojis[index];
          return InkWell(
            onTap: () {
              widget.onSendEmoji?.call(emoji.id);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  emoji.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // 表情按钮
          IconButton(
            icon: Icon(
              _showEmojiPanel ? Icons.keyboard : Icons.emoji_emotions_outlined,
            ),
            onPressed: () {
              setState(() {
                _showEmojiPanel = !_showEmojiPanel;
              });
            },
          ),

          // 输入框
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLength: 100,
              onSubmitted: _sendMessage,
            ),
          ),

          // 发送按钮
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(_messageController.text),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    widget.onSendMessage?.call(text.trim());
    _messageController.clear();
  }
}

/// 聊天消息项
class _ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isOwnMessage;

  const _ChatMessageItem({
    required this.message,
    required this.isOwnMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              child: Text(message.senderName[0]),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isOwnMessage)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (message.type == ChatMessageType.emoji)
                    Text(
                      message.content,
                      style: const TextStyle(fontSize: 32),
                    )
                  else
                    Text(
                      message.displayContent,
                      style: TextStyle(
                        color: isOwnMessage ? Colors.white : Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}

/// 聊天按钮（显示在游戏界面）
class ChatButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onTap;

  const ChatButton({
    super.key,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FloatingActionButton(
          mini: true,
          onPressed: onTap,
          child: const Icon(Icons.chat),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// 表情动画显示组件
class EmojiAnimation extends StatefulWidget {
  final String emoji;
  final VoidCallback? onComplete;

  const EmojiAnimation({
    super.key,
    required this.emoji,
    this.onComplete,
  });

  @override
  State<EmojiAnimation> createState() => _EmojiAnimationState();
}

class _EmojiAnimationState extends State<EmojiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: _animation,
        child: Text(
          widget.emoji,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }
}
