import 'package:flutter/material.dart';

/// 操作按钮组件
class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback? onCall;
  final VoidCallback? onPass;
  final VoidCallback? onPlay;
  final VoidCallback? onHint;
  final bool isCallPhase;
  final bool canPass;
  final bool canPlay;
  final bool hasHintCards;

  const ActionButtonsWidget({
    super.key,
    this.onCall,
    this.onPass,
    this.onPlay,
    this.onHint,
    this.isCallPhase = false,
    this.canPass = false,
    this.canPlay = true,
    this.hasHintCards = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCallPhase) {
      return _buildCallButtons(context);
    }
    return _buildPlayButtons(context);
  }

  Widget _buildCallButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: onCall,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('叫地主'),
        ),
        OutlinedButton(
          onPressed: onPass,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('不叫'),
        ),
      ],
    );
  }

  Widget _buildPlayButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 提示按钮
        if (canPlay)
          TextButton.icon(
            onPressed: onHint,
            icon: Icon(
              Icons.lightbulb_outline,
              color: onHint != null ? Colors.amber : Colors.grey,
            ),
            label: Text(
              '提示',
              style: TextStyle(
                color: onHint != null ? Colors.amber.shade700 : Colors.grey,
              ),
            ),
          ),
        // 出牌按钮
        ElevatedButton(
          onPressed: canPlay && onPlay != null ? onPlay : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canPlay ? Colors.teal : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('出牌'),
        ),
        if (canPass)
          OutlinedButton(
            onPressed: onPass,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('不出'),
          ),
      ],
    );
  }
}
