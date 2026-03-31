import 'package:flutter/material.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/validators/call_validator.dart';

/// 叫牌对话框
class CallTrumpDialog extends StatelessWidget {
  final ShengjiGameState gameState;
  final String localPlayerId;
  final void Function(TrumpCall call) onCall;
  final VoidCallback onPass;

  const CallTrumpDialog({
    super.key,
    required this.gameState,
    required this.localPlayerId,
    required this.onCall,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final localPlayer = gameState.players.where((p) => p.id == localPlayerId).firstOrNull;
    if (localPlayer == null) return const SizedBox.shrink();

    final dealerTeam = gameState.teams.firstWhere((t) => t.isDealer, orElse: () => gameState.teams.first);
    final possibleCalls = CallValidator.findPossibleCalls(localPlayer.hand, dealerTeam.currentLevel);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '叫牌阶段 - 当前级牌: ${dealerTeam.levelName}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (possibleCalls.isEmpty)
              const Text(
                '你手中没有可叫的牌',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: possibleCalls.map((call) {
                  return ElevatedButton(
                    onPressed: () => onCall(call),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(call.toString()),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPass,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('不叫'),
            ),
          ],
        ),
      ),
    );
  }
}
