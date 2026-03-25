import 'package:flutter/material.dart';

/// 下注操作面板
class ZhjBettingPanel extends StatelessWidget {
  final bool isMyTurn;
  final bool hasPeeked;
  final bool canShowdown; // 是否有可比牌目标
  final VoidCallback onPeek;
  final VoidCallback onCall;
  final VoidCallback onRaise;
  final VoidCallback onFold;
  final VoidCallback onShowdown;

  const ZhjBettingPanel({
    super.key,
    required this.isMyTurn,
    required this.hasPeeked,
    required this.canShowdown,
    required this.onPeek,
    required this.onCall,
    required this.onRaise,
    required this.onFold,
    required this.onShowdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          if (!hasPeeked)
            _btn('看牌', Colors.blue.shade700, isMyTurn, onPeek),
          _btn('跟注', Colors.green.shade700, isMyTurn, onCall),
          _btn('加注', Colors.orange.shade700, isMyTurn, onRaise),
          _btn('弃牌', Colors.red.shade700, isMyTurn, () => _confirmFold(context)),
          if (canShowdown)
            _btn('比牌', Colors.purple.shade700, isMyTurn, onShowdown),
        ],
      ),
    );
  }

  void _confirmFold(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('确认弃牌？', style: TextStyle(color: Colors.white)),
        content: const Text('弃牌后将无法继续参与本局。',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onFold();
            },
            child: const Text('确认弃牌', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, bool enabled, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
