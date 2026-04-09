import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/core/network/blackjack_network_adapter.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_config.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_network_action.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_player.dart';
import 'package:poke_game/presentation/pages/blackjack/providers/blackjack_game_notifier.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';
import 'package:poke_game/presentation/shared/widgets/game_back_button.dart';

class BlackjackPage extends ConsumerStatefulWidget {
  final bool isOnline;
  final BlackjackNetworkAdapter? networkAdapter;
  final int turnTimeLimit;

  const BlackjackPage({
    super.key,
    this.isOnline = false,
    this.networkAdapter,
    this.turnTimeLimit = 35,
  });

  @override
  ConsumerState<BlackjackPage> createState() => _BlackjackPageState();
}

class _BlackjackPageState extends ConsumerState<BlackjackPage>
    with TickerProviderStateMixin {
  bool _settlementShown = false;
  Timer? _settlementTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 初始化游戏（单机：玩家 vs AI 庄家）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isOnline) {
        ref.read(blackjackGameProvider.notifier).init(
          players: [
            BlackjackPlayer(
              id: 'human',
              name: '玩家',
              isAi: false,
              chips: BlackjackGameConfig.defaultConfig.initialChips,
            ),
          ],
        );
      }
    });
  }

  @override
  void dispose() {
    _settlementTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(blackjackGameProvider);
    final notifier = ref.read(blackjackGameProvider.notifier);
    final isOnline = widget.isOnline;
    final adapter = widget.networkAdapter;

    // 联机 localId
    final localId = isOnline ? (adapter?.localPlayerId ?? 'human') : 'human';

    // sendOrLocal: Client 走 adapter，Host/单机直调 notifier
    void sendOrLocal(BlackjackActionType action, {int handIndex = 0}) {
      if (isOnline && adapter != null && !(adapter.isHost)) {
        adapter.sendAction(BlackjackNetworkAction(
          action: action,
          playerId: localId,
          handIndex: handIndex,
        ));
      } else {
        switch (action) {
          case BlackjackActionType.hit:
            notifier.hit();
          case BlackjackActionType.stand:
            notifier.stand();
          case BlackjackActionType.doubleDown:
            notifier.doubleDown();
          case BlackjackActionType.split:
            notifier.split();
          case BlackjackActionType.surrender:
            notifier.surrender();
        }
      }
    }

    // 结算处理
    if (gameState.phase == BlackjackPhase.settlement && !_settlementShown) {
      _settlementShown = true;
      _settlementTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _settlementShown = false);
        }
      });
    }
    if (gameState.phase != BlackjackPhase.settlement) {
      _settlementShown = false;
    }

    final isMyTurn = gameState.currentPlayer?.id == localId &&
        gameState.phase == BlackjackPhase.playerTurn;

    return Scaffold(
      backgroundColor: context.gameColors.bgTable,
      appBar: AppBar(
        backgroundColor: context.gameColors.bgTable,
        foregroundColor: Colors.white,
        leading: GameBackButton(onPressed: () => _confirmExit(context)),
        title: const Text('21 点'),
        actions: [
          if (gameState.phase == BlackjackPhase.betting)
            TextButton(
              onPressed: notifier.startGame,
              child: const Text('开始', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // 庄家区
          _DealerZone(
            dealer: gameState.dealer,
            showHoleCard: gameState.phase == BlackjackPhase.dealerTurn ||
                gameState.phase == BlackjackPhase.settlement,
          ),
          const Divider(color: Colors.white24, height: 1),

          // 消息提示
          if (gameState.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                gameState.message!,
                style: const TextStyle(color: Colors.amber, fontSize: 14),
              ),
            ),

          // 结算覆盖层
          if (gameState.phase == BlackjackPhase.settlement)
            _SettlementOverlay(
              players: gameState.players,
              localId: localId,
              onPlayAgain: () {
                setState(() => _settlementShown = false);
                notifier.resetForNextRound();
              },
            ),

          // 玩家区
          Expanded(
            child: gameState.players.length > 1
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gameState.players.length,
                    itemBuilder: (context, i) => _PlayerZone(
                      player: gameState.players[i],
                      isCurrentTurn: gameState.currentPlayerIndex == i &&
                          gameState.phase == BlackjackPhase.playerTurn,
                      showCards: gameState.players[i].id == localId ||
                          gameState.phase == BlackjackPhase.settlement,
                    ),
                  )
                : gameState.players.isNotEmpty
                    ? _PlayerZone(
                        player: gameState.players[0],
                        isCurrentTurn: isMyTurn,
                        showCards: true,
                      )
                    : const SizedBox.shrink(),
          ),

          // 下注 UI
          if (gameState.phase == BlackjackPhase.betting &&
              gameState.players.any((p) => p.id == localId))
            _BettingBar(
              player: gameState.players.firstWhere((p) => p.id == localId),
              onBet: (amount) => notifier.bet(localId, amount),
            ),

          // 操作按钮
          if (gameState.phase == BlackjackPhase.playerTurn)
            _ActionBar(
              isMyTurn: isMyTurn,
              activeHand: gameState.currentPlayer?.activeHand,
              onAction: sendOrLocal,
              isOnline: isOnline,
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 庄家区
// ────────────────────────────────────────────────────────────────────────────

class _DealerZone extends StatelessWidget {
  final BlackjackPlayer dealer;
  final bool showHoleCard;

  const _DealerZone({required this.dealer, required this.showHoleCard});

  @override
  Widget build(BuildContext context) {
    final hand = dealer.hands.isNotEmpty ? dealer.hands[0] : null;
    final cards = hand?.cards ?? [];
    final value = showHoleCard ? (hand?.value.toString() ?? '?') : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '庄家  $value 点',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < cards.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _CardWidget(
                    card: cards[i],
                    faceDown: i == 1 && !showHoleCard,
                  ),
                ),
              if (cards.isEmpty)
                const Text('尚未发牌', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 玩家区
// ────────────────────────────────────────────────────────────────────────────

class _PlayerZone extends StatelessWidget {
  final BlackjackPlayer player;
  final bool isCurrentTurn;
  final bool showCards;

  const _PlayerZone({
    required this.player,
    required this.isCurrentTurn,
    required this.showCards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTurn
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                player.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${player.chips} 筹',
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...player.hands.asMap().entries.map((e) {
            final idx = e.key;
            final hand = e.value;
            final isActive = player.activeHandIndex == idx;
            return _HandWidget(
              hand: hand,
              isActive: isActive,
              showCards: showCards,
              label: player.hands.length > 1 ? '手牌 ${idx + 1}' : null,
            );
          }),
        ],
      ),
    );
  }
}

class _HandWidget extends StatelessWidget {
  final BlackjackHand hand;
  final bool isActive;
  final bool showCards;
  final String? label;

  const _HandWidget({
    required this.hand,
    required this.isActive,
    required this.showCards,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final statusText = _statusLabel(hand.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(label!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Row(
          children: [
            ...hand.cards.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _CardWidget(card: c, faceDown: !showCards),
                )),
          ],
        ),
        Row(
          children: [
            Text(
              showCards ? '${hand.value} 点' : '? 点',
              style: TextStyle(
                color: isActive ? Colors.amber : Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '下注: ${hand.bet}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            if (statusText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(hand.status, colors),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String? _statusLabel(BlackjackHandStatus status) {
    switch (status) {
      case BlackjackHandStatus.bust:
        return '爆牌';
      case BlackjackHandStatus.blackjack:
        return 'Blackjack!';
      case BlackjackHandStatus.surrendered:
        return '投降';
      case BlackjackHandStatus.fiveCardCharlie:
        return '五小龙';
      case BlackjackHandStatus.stood:
        return '停牌';
      case BlackjackHandStatus.active:
        return null;
    }
  }

  Color _statusColor(BlackjackHandStatus status, GameColors colors) {
    switch (status) {
      case BlackjackHandStatus.bust:
      case BlackjackHandStatus.surrendered:
        return colors.dangerRed;
      case BlackjackHandStatus.blackjack:
      case BlackjackHandStatus.fiveCardCharlie:
        return colors.accentAmber;
      default:
        return colors.textSecondary;
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 牌面 Widget
// ────────────────────────────────────────────────────────────────────────────

class _CardWidget extends StatelessWidget {
  final dynamic card; // BlackjackCard
  final bool faceDown;

  const _CardWidget({required this.card, this.faceDown = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    if (faceDown) {
      return Container(
        width: 36,
        height: 52,
        decoration: BoxDecoration(
          color: colors.cardBackBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: colors.cardBorderBlack.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Text(
            '🂠',
            style: TextStyle(fontSize: 20, color: colors.cardBorderBlack),
          ),
        ),
      );
    }
    final isRed = card.isRed as bool;
    final cardColor = isRed ? colors.cardBorderRed : colors.textPrimary;
    final borderColor = isRed ? colors.cardBorderRed : colors.cardBorderBlack;
    return Container(
      width: 36,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.cardBg1, colors.cardBg2],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.displayText as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cardColor,
            ),
          ),
          Text(
            card.suitSymbol as String,
            style: TextStyle(fontSize: 12, color: cardColor),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 下注栏
// ────────────────────────────────────────────────────────────────────────────

class _BettingBar extends StatelessWidget {
  final BlackjackPlayer player;
  final void Function(int) onBet;

  const _BettingBar({required this.player, required this.onBet});

  @override
  Widget build(BuildContext context) {
    const chips = [10, 50, 100, 500];
    final currentBet =
        player.hands.isNotEmpty ? player.hands[0].bet : 0;
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '余额: ${player.chips}  已注: $currentBet',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
          ...chips.map((c) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  onPressed: player.chips >= c ? () => onBet(c) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 36),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('+$c', style: const TextStyle(fontSize: 12)),
                ),
              )),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 操作按钮栏
// ────────────────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool isMyTurn;
  final BlackjackHand? activeHand;
  final void Function(BlackjackActionType, {int handIndex}) onAction;
  final bool isOnline;

  const _ActionBar({
    required this.isMyTurn,
    required this.activeHand,
    required this.onAction,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMyTurn) {
      return Container(
        color: Colors.black26,
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            isOnline ? '等待其他玩家操作...' : 'AI 思考中...',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      );
    }
    final hand = activeHand;
    final twoCards = hand != null && hand.cards.length == 2;
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
            label: '摸牌\nHit',
            onPressed: () => onAction(BlackjackActionType.hit),
          ),
          _ActionButton(
            label: '停牌\nStand',
            onPressed: () => onAction(BlackjackActionType.stand),
          ),
          _ActionButton(
            label: '加倍\nDouble',
            onPressed: twoCards ? () => onAction(BlackjackActionType.doubleDown) : null,
          ),
          _ActionButton(
            label: '分牌\nSplit',
            onPressed: (twoCards && (hand.canSplit))
                ? () => onAction(BlackjackActionType.split)
                : null,
          ),
          _ActionButton(
            label: '投降\nSurrender',
            onPressed: twoCards ? () => onAction(BlackjackActionType.surrender) : null,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null
              ? colors.primaryGreen
              : colors.textSecondary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 结算覆盖层
// ────────────────────────────────────────────────────────────────────────────

class _SettlementOverlay extends StatelessWidget {
  final List<BlackjackPlayer> players;
  final String localId;
  final VoidCallback onPlayAgain;

  const _SettlementOverlay({
    required this.players,
    required this.localId,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '结算',
            style: TextStyle(
                color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...players.map((p) => _PlayerResult(player: p, isLocal: p.id == localId)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onPlayAgain,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('再来一局', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _PlayerResult extends StatelessWidget {
  final BlackjackPlayer player;
  final bool isLocal;

  const _PlayerResult({required this.player, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            player.name,
            style: TextStyle(
              color: isLocal ? Colors.amber : Colors.white70,
              fontWeight: isLocal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 12),
          ...player.hands.map((h) {
            final payout = h.bet; // settle 后 bet 字段存赔付值
            final label = payout > 0
                ? '+$payout'
                : payout < 0
                    ? '$payout'
                    : '平局';
            final color = payout > 0
                ? Colors.greenAccent
                : payout < 0
                    ? Colors.red.shade300
                    : Colors.white54;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(label, style: TextStyle(color: color)),
            );
          }),
          const Spacer(),
          Text(
            '${player.chips} 筹',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
