import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/core/network/zhj_network_adapter.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_network_action.dart' show ZhjActionType, ZhjNetworkAction;
import 'package:poke_game/presentation/pages/zhajinhua/providers/zhj_game_provider.dart';
import 'package:poke_game/presentation/pages/zhajinhua/widgets/zhj_betting_panel.dart';
import 'package:poke_game/presentation/pages/zhajinhua/widgets/zhj_settlement_dialog.dart';
import 'package:poke_game/presentation/pages/zhajinhua/widgets/zhj_table_widget.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';
import 'package:poke_game/presentation/shared/widgets/game_back_button.dart';

class ZhajinhuaPage extends ConsumerStatefulWidget {
  /// 是否为联机模式
  final bool isOnline;

  /// 联机网络适配器（联机模式时提供）
  final ZhjNetworkAdapter? networkAdapter;

  const ZhajinhuaPage({
    super.key,
    this.isOnline = false,
    this.networkAdapter,
  });

  @override
  ConsumerState<ZhajinhuaPage> createState() => _ZhajinhuaPageState();
}

class _ZhajinhuaPageState extends ConsumerState<ZhajinhuaPage> {
  bool _settlementShown = false;

  @override
  void initState() {
    super.initState();
    // 横屏锁定
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // 恢复所有方向
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(zhjGameProvider);
    final notifier = ref.read(zhjGameProvider.notifier);
    final isOnline = widget.isOnline;
    final adapter = widget.networkAdapter;

    // 结算弹窗
    if (gameState.phase == ZhjGamePhase.settlement && !_settlementShown) {
      _settlementShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ZhjSettlementDialog(
            gameState: gameState,
            onPlayAgain: () {
              Navigator.pop(context);
              setState(() => _settlementShown = false);
              notifier.playAgain();
            },
            onExit: () {
              Navigator.pop(context); // 关闭弹窗
              Navigator.pop(context); // 返回大厅
            },
          ),
        );
      });
    }

    // 当开始新游戏时重置弹窗状态
    if (gameState.phase == ZhjGamePhase.betting && _settlementShown) {
      _settlementShown = false;
    }

    // 联机模式：本地玩家 ID 由 adapter 提供，否则使用 'human'
    final localId = (isOnline && adapter != null) ? adapter.localPlayerId : 'human';
    final humanIndex = gameState.players.indexWhere((p) => p.id == localId);
    final isMyTurn = humanIndex >= 0 &&
        gameState.currentPlayerIndex == humanIndex &&
        gameState.phase == ZhjGamePhase.betting;
    final humanHasPeeked =
        humanIndex >= 0 ? gameState.players[humanIndex].hasPeeked : false;
    // 联机模式比牌目标：存活的其他玩家
    final aliveOthers = gameState.alivePlayers.where((p) => p.id != localId).toList();
    final canShowdown = isMyTurn && aliveOthers.isNotEmpty;

    // 联机 Client 模式：非本地玩家回合，显示等待提示
    final isWaitingOnline = isOnline &&
        !isMyTurn &&
        gameState.phase == ZhjGamePhase.betting;

    /// 构造实际回调（task 5.3）
    void sendOrLocal(ZhjActionType actionType, {int? targetIdx}) {
      if (isOnline && adapter != null && !adapter.isHost) {
        // Client：发送行动给 Host
        adapter.sendAction(ZhjNetworkAction(
          playerId: localId,
          actionType: actionType,
          targetPlayerIndex: targetIdx,
        ));
      } else {
        // Host 或单机：直接调用 notifier
        switch (actionType) {
          case ZhjActionType.peek:
            notifier.playerPeek();
          case ZhjActionType.call:
            notifier.playerCall();
          case ZhjActionType.raise:
            notifier.playerRaise();
          case ZhjActionType.fold:
            notifier.playerFold();
          case ZhjActionType.showdown:
            if (targetIdx != null) notifier.playerShowdown(targetIdx);
        }
      }
    }

    return Scaffold(
      backgroundColor: context.gameColors.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            ZhjTableWidget(
              gameState: gameState,
              bettingPanel: ZhjBettingPanel(
                isMyTurn: isMyTurn,
                hasPeeked: humanHasPeeked,
                canShowdown: canShowdown,
                onPeek: () => sendOrLocal(ZhjActionType.peek),
                onCall: () => sendOrLocal(ZhjActionType.call),
                onRaise: () => sendOrLocal(ZhjActionType.raise),
                onFold: () => sendOrLocal(ZhjActionType.fold),
                onShowdown: () {
                  final target = aliveOthers.isNotEmpty
                      ? aliveOthers.first
                      : gameState.alivePlayers.first;
                  final targetIdx = gameState.players.indexOf(target);
                  sendOrLocal(ZhjActionType.showdown, targetIdx: targetIdx);
                },
              ),
            ),
            // 返回按钮
            Positioned(
              top: 8,
              left: 8,
              child: GameBackButton(onPressed: () => _confirmExit(context)),
            ),
            // 等待提示（单机：AI 思考中；联机：等待其他玩家）
            if (gameState.phase == ZhjGamePhase.betting && !isMyTurn)
              Positioned(
                top: 8,
                right: 16,
                child: Chip(
                  label: Text(
                    isWaitingOnline ? '等待其他玩家操作...' : 'AI 思考中...',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  backgroundColor: Colors.black45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出游戏'),
        content: const Text('确定要退出当前游戏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
    }
  }
}
