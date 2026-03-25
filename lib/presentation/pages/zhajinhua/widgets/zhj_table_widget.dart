import 'package:flutter/material.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';
import 'zhj_player_widget.dart';
import 'zhj_pot_display.dart';

/// 游戏桌面：横屏布局，底部为人类玩家，顶部/侧面为AI
class ZhjTableWidget extends StatelessWidget {
  final ZhjGameState gameState;
  final Widget bettingPanel;

  const ZhjTableWidget({
    super.key,
    required this.gameState,
    required this.bettingPanel,
  });

  @override
  Widget build(BuildContext context) {
    final players = gameState.players;
    final humanIndex = players.indexWhere((p) => p.id == 'human');
    final aiPlayers = players.where((p) => p.isAi).toList();

    final isSettlement = gameState.phase == ZhjGamePhase.settlement;

    return Stack(
      children: [
        // 绿色桌面背景
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              radius: 1.2,
            ),
          ),
        ),

        Column(
          children: [
            // 顶部：AI 玩家区域
            Expanded(
              flex: 2,
              child: _buildAiRow(aiPlayers, gameState, isSettlement),
            ),

            // 中央：底池显示
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ZhjPotDisplay(
                pot: gameState.pot,
                currentBet: gameState.currentBet,
              ),
            ),

            // 底部：人类玩家 + 操作面板
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (humanIndex >= 0)
                    ZhjPlayerWidget(
                      player: players[humanIndex],
                      isCurrentTurn: gameState.currentPlayerIndex == humanIndex &&
                          gameState.phase == ZhjGamePhase.betting,
                      showFaceUp: isSettlement || players[humanIndex].hasPeeked,
                    ),
                  const SizedBox(height: 12),
                  bettingPanel,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiRow(
      List<ZhjPlayer> aiPlayers, ZhjGameState state, bool isSettlement) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: aiPlayers.map((p) {
        final idx = state.players.indexOf(p);
        return ZhjPlayerWidget(
          player: p,
          isCurrentTurn: state.currentPlayerIndex == idx &&
              state.phase == ZhjGamePhase.betting,
          showFaceUp: isSettlement,
        );
      }).toList(),
    );
  }
}
