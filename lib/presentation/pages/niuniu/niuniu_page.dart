import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/core/network/niuniu_network_adapter.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_card.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_game_config.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_game_state.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_hand.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_network_action.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_player.dart';
import 'package:poke_game/presentation/pages/niuniu/providers/niuniu_game_notifier.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';
import 'package:poke_game/presentation/shared/widgets/game_back_button.dart';

class NiuniuPage extends ConsumerStatefulWidget {
  final bool isOnline;
  final NiuniuNetworkAdapter? networkAdapter;

  const NiuniuPage({
    super.key,
    this.isOnline = false,
    this.networkAdapter,
  });

  @override
  ConsumerState<NiuniuPage> createState() => _NiuniuPageState();
}

class _NiuniuPageState extends ConsumerState<NiuniuPage> {
  int _pendingBet = 0;
  bool _settlementVisible = false;
  Timer? _settlementTimer;
  // 已翻牌的玩家 id 集合（showdown 动画用）
  final Set<String> _revealed = {};
  bool _isRevealingCards = false;

  String get localId =>
      widget.isOnline ? (widget.networkAdapter?.localPlayerId ?? 'human') : 'human';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isOnline) {
        _initSinglePlayer();
      }
    });
  }

  void _initSinglePlayer() {
    final config = NiuniuGameConfig.defaultConfig;
    ref.read(niuniuGameProvider.notifier).init(
      players: [
        NiuniuPlayer(
          id: 'human',
          name: '玩家',
          isAi: false,
          role: NiuniuRole.banker,
          chips: config.initialChips,
        ),
        NiuniuPlayer(
          id: 'ai1',
          name: 'AI 1',
          isAi: true,
          role: NiuniuRole.punter,
          chips: config.initialChips,
        ),
        NiuniuPlayer(
          id: 'ai2',
          name: 'AI 2',
          isAi: true,
          role: NiuniuRole.punter,
          chips: config.initialChips,
        ),
        NiuniuPlayer(
          id: 'ai3',
          name: 'AI 3',
          isAi: true,
          role: NiuniuRole.punter,
          chips: config.initialChips,
        ),
      ],
    );
    // 启动 AI 自动下注
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(niuniuGameProvider.notifier).runAiBets();
      }
    });
  }

  @override
  void dispose() {
    _settlementTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _confirmBet() {
    if (_pendingBet <= 0) return;
    final notifier = ref.read(niuniuGameProvider.notifier);
    if (widget.isOnline && widget.networkAdapter != null && !widget.networkAdapter!.isHost) {
      widget.networkAdapter!.sendAction(NiuniuNetworkAction(
        action: NiuniuActionType.bet,
        playerId: localId,
        amount: _pendingBet,
      ));
    } else {
      notifier.networkBet(localId, _pendingBet);
    }
    setState(() => _pendingBet = 0);
  }

  Future<void> _startRevealAnimation(NiuniuGameState gameState) async {
    if (_isRevealingCards) return;
    _isRevealingCards = true;
    _revealed.clear();

    // 庄家先翻
    final banker = gameState.banker;
    if (banker != null) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _revealed.add(banker.id));
    }
    // 闲家依次翻
    for (final p in gameState.punters) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _revealed.add(p.id));
    }
    // 所有翻完后自动结算
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      ref.read(niuniuGameProvider.notifier).settle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(niuniuGameProvider);
    final localPlayer =
        gameState.players.where((p) => p.id == localId).firstOrNull;

    // 进入 showdown 自动翻牌
    if (gameState.phase == NiuniuPhase.showdown && !_isRevealingCards) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRevealAnimation(gameState);
      });
    }

    // 重置翻牌状态
    if (gameState.phase == NiuniuPhase.betting) {
      _isRevealingCards = false;
      _revealed.clear();
    }

    // 结算覆盖层
    if (gameState.phase == NiuniuPhase.settlement && !_settlementVisible) {
      _settlementVisible = true;
      _settlementTimer?.cancel();
      _settlementTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() {});
      });
    }
    if (gameState.phase != NiuniuPhase.settlement) {
      _settlementVisible = false;
    }

    return Scaffold(
      backgroundColor: context.gameColors.bgTable,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // 顶部工具栏
                _buildTopBar(context),
                // 主牌桌
                Expanded(
                  child: _buildTable(gameState),
                ),
                // 底部操作区
                _buildBottomBar(gameState, localPlayer),
              ],
            ),
          ),
          // 结算覆盖层
          if (gameState.phase == NiuniuPhase.settlement)
            _SettlementOverlay(
              gameState: gameState,
              onNextRound: () {
                _settlementVisible = false;
                ref.read(niuniuGameProvider.notifier).resetForNextRound();
                if (!widget.isOnline) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      ref.read(niuniuGameProvider.notifier).runAiBets();
                    }
                  });
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          GameBackButton(onPressed: () => _confirmExit(context)),
          const Text('斗牛',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (widget.isOnline)
            const Icon(Icons.wifi, color: Colors.greenAccent, size: 18),
        ],
      ),
    );
  }

  Widget _buildTable(NiuniuGameState gameState) {
    final banker = gameState.banker;
    final punters = gameState.punters;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // 庄家区
          if (banker != null)
            _PlayerZone(
              player: banker,
              isRevealed: _revealed.contains(banker.id),
              isBanker: true,
            ),
          const SizedBox(height: 12),
          // 闲家横向列表
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: punters
                    .map((p) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _PlayerZone(
                            player: p,
                            isRevealed: _revealed.contains(p.id),
                            isBanker: false,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(NiuniuGameState gameState, NiuniuPlayer? localPlayer) {
    if (gameState.phase != NiuniuPhase.betting) {
      return const SizedBox.shrink();
    }

    final isMyTurn = localPlayer?.status == NiuniuPlayerStatus.waiting &&
        localPlayer?.isPunter == true;
    final chips = localPlayer?.chips ?? 0;

    if (!isMyTurn) {
      return Container(
        color: Colors.black38,
        padding: const EdgeInsets.all(12),
        child: const Center(
          child: Text('等待其他玩家下注...',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return _BettingBar(
      chips: chips,
      pendingBet: _pendingBet,
      onChipTap: (amount) {
        if (chips - _pendingBet >= amount) {
          setState(() => _pendingBet += amount);
        }
      },
      onClear: () => setState(() => _pendingBet = 0),
      onConfirm: _pendingBet > 0 ? _confirmBet : null,
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

// ─── 玩家区域 ────────────────────────────────────────────────────────────────

class _PlayerZone extends StatelessWidget {
  final NiuniuPlayer player;
  final bool isRevealed;
  final bool isBanker;

  const _PlayerZone({
    required this.player,
    required this.isRevealed,
    required this.isBanker,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final hand = player.hand;
    return Container(
      width: isBanker ? double.infinity : 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBanker ? Colors.amber : Colors.white24,
          width: isBanker ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 玩家名称 + 筹码
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isBanker ? "👑 " : ""}${player.name}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '💰${player.chips}',
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 下注额
          if (player.betAmount != 0 && player.status == NiuniuPlayerStatus.bet)
            Text(
              '下注: ${player.betAmount}',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
            ),
          const SizedBox(height: 6),
          // 手牌
          if (hand != null && isRevealed) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: hand.cards
                  .map((c) => _CardWidget(card: c))
                  .toList(),
            ),
            const SizedBox(height: 4),
            // 牌型标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _rankColor(hand.rank, colors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${hand.rank.displayName} ×${hand.multiplier}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ] else if (hand != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                hand.cards.isNotEmpty ? 5 : 0,
                (_) => _CardBack(),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (_) => _CardBack()),
            ),
          ],
        ],
      ),
    );
  }

  Color _rankColor(NiuniuRank rank, GameColors colors) {
    switch (rank) {
      case NiuniuRank.bomb:
      case NiuniuRank.fiveSmall:
        return colors.dangerRed;
      case NiuniuRank.niuNiu:
        return colors.accentAmber;
      case NiuniuRank.niu7:
      case NiuniuRank.niu8:
      case NiuniuRank.niu9:
        return colors.teamColor;
      default:
        return colors.textSecondary;
    }
  }
}

// ─── 牌面 ─────────────────────────────────────────────────────────────────────

class _CardWidget extends StatelessWidget {
  final NiuniuCard card;
  const _CardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final isRed = card.isRed;
    final cardColor = isRed ? colors.cardBorderRed : colors.textPrimary;
    final borderColor = isRed ? colors.cardBorderRed : colors.cardBorderBlack;
    return Container(
      width: 36,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 1),
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
            card.displayText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cardColor,
            ),
          ),
          Text(
            card.suitSymbol,
            style: TextStyle(fontSize: 12, color: cardColor),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    return Container(
      width: 36,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 1),
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
}

// ─── 下注栏 ───────────────────────────────────────────────────────────────────

class _BettingBar extends StatelessWidget {
  final int chips;
  final int pendingBet;
  final void Function(int) onChipTap;
  final VoidCallback onClear;
  final VoidCallback? onConfirm;

  static const _denominations = [10, 50, 100, 500];

  const _BettingBar({
    required this.chips,
    required this.pendingBet,
    required this.onChipTap,
    required this.onClear,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = chips - pendingBet;
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 筹码信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('筹码: $chips', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('下注: $pendingBet', style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 12),
          // 面额按钮
          ..._denominations.map((d) {
            final disabled = remaining < d;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ElevatedButton(
                onPressed: disabled ? null : () => onChipTap(d),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  disabledBackgroundColor: Colors.grey.shade700,
                  minimumSize: const Size(44, 36),
                  padding: EdgeInsets.zero,
                ),
                child: Text('+$d', style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
            );
          }),
          const Spacer(),
          // 清除按钮
          if (pendingBet > 0)
            TextButton(
              onPressed: onClear,
              child: const Text('清除', style: TextStyle(color: Colors.white70)),
            ),
          // 确认下注
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('确认下注', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── 结算覆盖层 ───────────────────────────────────────────────────────────────

class _SettlementOverlay extends StatefulWidget {
  final NiuniuGameState gameState;
  final VoidCallback onNextRound;

  const _SettlementOverlay({
    required this.gameState,
    required this.onNextRound,
  });

  @override
  State<_SettlementOverlay> createState() => _SettlementOverlayState();
}

class _SettlementOverlayState extends State<_SettlementOverlay> {
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showButton = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.gameState.players;
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('结算', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: players.map((p) {
                final delta = p.betAmount; // settle 后存储净盈亏
                final isWin = delta > 0;
                final color = isWin ? Colors.greenAccent : Colors.redAccent;
                final sign = isWin ? '+' : '';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '$sign$delta',
                      style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_showButton)
              ElevatedButton(
                onPressed: widget.onNextRound,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                child: const Text('再来一局', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
