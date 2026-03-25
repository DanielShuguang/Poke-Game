import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 德州扑克大厅页面
class HoldemLobbyPage extends StatelessWidget {
  const HoldemLobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景 + 内容
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A5C35), Color(0xFF0D3B23)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🃏',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '德州扑克',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '现金局 · 3-6 人桌',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 48),
                    _LobbyButton(
                      icon: Icons.smart_toy_outlined,
                      label: '单人 AI 对战',
                      subtitle: '人机模式，AI 填充空位',
                      color: const Color(0xFF2E7D32),
                      onPressed: () => context.push('/texas-holdem/game'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 退出按钮（右上角，与其他游戏页面一致）
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.exit_to_app,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _LobbyButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }
}
