import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/core/network/guandan_network_adapter.dart';
import 'package:poke_game/domain/guandan/entities/guandan_card.dart';
import 'package:poke_game/domain/guandan/entities/guandan_game_state.dart';
import 'package:poke_game/domain/guandan/entities/guandan_network_action.dart';
import 'package:poke_game/domain/guandan/entities/guandan_player.dart';
import 'package:poke_game/presentation/pages/guandan/providers/guandan_game_notifier.dart';
import 'package:poke_game/domain/guandan/usecases/hint_usecase.dart';
import 'package:poke_game/domain/guandan/usecases/validate_hand_usecase.dart';
import 'package:poke_game/presentation/pages/guandan/widgets/guandan_hand_widget.dart';
import 'package:poke_game/presentation/pages/guandan/widgets/guandan_play_area_widget.dart';
import 'package:poke_game/presentation/pages/guandan/widgets/guandan_result_dialog.dart';
import 'package:poke_game/presentation/pages/guandan/widgets/guandan_tribute_dialog.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

class GuandanGamePage extends ConsumerStatefulWidget {
  final bool isOnline;
  final GuandanNetworkAdapter? networkAdapter;
  final int turnTimeLimit;

  const GuandanGamePage({
    super.key,
    this.isOnline = false,
    this.networkAdapter,
    this.turnTimeLimit = 35,
  });

  @override
  ConsumerState<GuandanGamePage> createState() => _GuandanGamePageState();
}

class _GuandanGamePageState extends ConsumerState<GuandanGamePage> {
  final Set<int> _selectedIndices = {};
  int _countdown = 0;
  Timer? _countdownTimer;

  String get localId =>
      widget.isOnline
          ? (widget.networkAdapter?.localPlayerId ?? 'human')
          : 'human';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isOnline) _initSinglePlayer();
    });
  }

  void _initSinglePlayer() {
    final notifier = ref.read(guandanGameProvider.notifier);
    notifier.startGame([
      GuandanPlayer(id: 'human', name: '玩家', teamId: 0, seatIndex: 0),
      GuandanPlayer(id: 'ai1', name: 'AI 1', teamId: 1, seatIndex: 1, isAi: true),
      GuandanPlayer(id: 'ai2', name: 'AI 2', teamId: 0, seatIndex: 2, isAi: true),
      GuandanPlayer(id: 'ai3', name: 'AI 3', teamId: 1, seatIndex: 3, isAi: true),
    ]);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    widget.networkAdapter?.stop();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // 倒计时
  // ──────────────────────────────────────────────────────────────

  void _startCountdown() {
    _countdown = widget.turnTimeLimit;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _stopCountdown();
        if (!widget.isOnline) _autoPlayOnTimeout();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (mounted && _countdown != 0) setState(() => _countdown = 0);
  }

  void _updateCountdown(GuandanGameState state) {
    final needCountdown = _isLocalActionNeeded(state);
    if (needCountdown && _countdown == 0) {
      _startCountdown();
    } else if (!needCountdown && _countdown > 0) {
      _stopCountdown();
    }
  }

  bool _isLocalActionNeeded(GuandanGameState state) {
    if (state.phase == GuandanPhase.playing) {
      return state.players.isNotEmpty && state.currentPlayer.id == localId;
    }
    if (state.phase == GuandanPhase.tribute) {
      final ts = state.tributeState;
      return ts != null && ts.pendingTributes.containsKey(localId);
    }
    if (state.phase == GuandanPhase.returnTribute) {
      final ts = state.tributeState;
      return ts != null && ts.pendingReturnTributes.containsKey(localId);
    }
    return false;
  }

  void _autoPlayOnTimeout() {
    final notifier = ref.read(guandanGameProvider.notifier);
    final state = ref.read(guandanGameProvider);

    if (state.phase == GuandanPhase.playing) {
      if (state.lastPlayedHand == null) {
        notifier.forcePlayCards(localId);
      } else {
        notifier.forcePass(localId);
      }
    } else if (state.phase == GuandanPhase.tribute) {
      final player = state.getPlayerById(localId);
      if (player != null) {
        final nonJokers = player.cards
            .where((c) => !c.isJoker)
            .toList()
          ..sort((a, b) => b.rank!.compareTo(a.rank!));
        if (nonJokers.isNotEmpty) notifier.tribute(localId, nonJokers.first);
      }
    } else if (state.phase == GuandanPhase.returnTribute) {
      final player = state.getPlayerById(localId);
      if (player != null && player.cards.isNotEmpty) {
        notifier.returnTribute(localId, player.cards.first);
      }
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 行动处理
  // ──────────────────────────────────────────────────────────────

  void _onPlay(GuandanGameState state) {
    final localPlayer = state.getPlayerById(localId);
    if (localPlayer == null) return;

    final selected = _selectedIndices
        .where((i) => i < localPlayer.cards.length)
        .map((i) => localPlayer.cards[i])
        .toList();

    if (widget.isOnline) {
      widget.networkAdapter?.sendAction(PlayCardsNetworkAction(cards: selected));
    } else {
      ref.read(guandanGameProvider.notifier).playCards(localId, selected);
    }
    setState(() => _selectedIndices.clear());
    _stopCountdown();
  }

  void _onPass(GuandanGameState state) {
    if (widget.isOnline) {
      widget.networkAdapter?.sendAction(const PassNetworkAction());
    } else {
      ref.read(guandanGameProvider.notifier).pass(localId);
    }
    setState(() => _selectedIndices.clear());
    _stopCountdown();
  }

  void _onHint(GuandanGameState state) {
    final localPlayer = state.getPlayerById(localId);
    if (localPlayer == null) return;

    final level = state.levelForTeam(localPlayer.teamId);
    final hints = HintUsecase.hint(localPlayer.cards, state.lastPlayedHand, level);
    if (hints.isEmpty) return;

    // 高亮第一个提示组合
    setState(() {
      _selectedIndices.clear();
      final hint = hints.first;
      for (int i = 0; i < localPlayer.cards.length; i++) {
        if (hint.any((c) => identical(c, localPlayer.cards[i]))) {
          _selectedIndices.add(i);
        }
      }
    });
  }

  void _onTribute(GuandanCard card) {
    _stopCountdown();
    if (widget.isOnline) {
      widget.networkAdapter?.sendAction(
        TributeNetworkAction(card: card, playerId: localId),
      );
    } else {
      ref.read(guandanGameProvider.notifier).tribute(localId, card);
    }
  }

  void _onReturnTribute(GuandanCard card) {
    _stopCountdown();
    if (widget.isOnline) {
      widget.networkAdapter?.sendAction(
        ReturnTributeNetworkAction(card: card, playerId: localId),
      );
    } else {
      ref.read(guandanGameProvider.notifier).returnTribute(localId, card);
    }
  }

  void _onRestart() {
    setState(() => _selectedIndices.clear());
    _initSinglePlayer();
  }

  // ──────────────────────────────────────────────────────────────
  // 退出确认
  // ──────────────────────────────────────────────────────────────

  Future<void> _onBack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出游戏'),
        content: const Text('确定要退出当前游戏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guandanGameProvider);
    final colors = context.gameColors;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateCountdown(state);
    });

    final localPlayer = state.getPlayerById(localId);
    final isLocalTurn = localPlayer != null &&
        state.players.isNotEmpty &&
        state.phase == GuandanPhase.playing &&
        state.currentPlayer.id == localId;

    return Scaffold(
      backgroundColor: colors.bgTable,
      body: Stack(
        children: [
          // 主游戏布局
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(state, colors),
                Expanded(
                  child: Row(
                    children: [
                      // 左侧对手（座位3）
                      _buildSidePlayer(state, 3, isLeft: true),

                      // 中央区域
                      Expanded(
                        child: Column(
                          children: [
                            // 顶部对家（座位2）
                            _buildOpponentTop(state, 2),
                            const SizedBox(height: 8),

                            // 中央出牌区
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLocalActionNeeded(state) &&
                                      _countdown > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: _countdown <= 10
                                            ? colors.dangerRed
                                            : colors.accentAmber,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$_countdown 秒',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: GuandanPlayAreaWidget(
                                      state: state,
                                      selectedIndices: _selectedIndices,
                                      localHand: localPlayer?.cards ?? [],
                                      isLocalTurn: isLocalTurn,
                                      canPlay: isLocalTurn &&
                                          _canPlay(state, localPlayer),
                                      canPass: isLocalTurn &&
                                          state.lastPlayedHand != null,
                                      onPlay: () => _onPlay(state),
                                      onPass: () => _onPass(state),
                                      onHint: () => _onHint(state),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                            // 底部本地玩家手牌
                            if (localPlayer != null)
                              _buildLocalHand(localPlayer),
                          ],
                        ),
                      ),

                      // 右侧对手（座位1）
                      _buildSidePlayer(state, 1, isLeft: false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 贡牌覆盖层
          if (state.phase == GuandanPhase.tribute ||
              state.phase == GuandanPhase.returnTribute)
            GuandanTributeDialog(
              state: state,
              localPlayerId: localId,
              onTribute: _onTribute,
              onReturnTribute: _onReturnTribute,
            ),

          // 结算弹窗
          if (state.phase == GuandanPhase.settling ||
              state.phase == GuandanPhase.finished)
            GuandanResultDialog(
              state: state,
              localPlayerId: localId,
              onPlayAgain: state.phase == GuandanPhase.settling
                  ? _onRestart
                  : null,
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 子组件
  // ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(GuandanGameState state, GameColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: _onBack,
          ),
          const Spacer(),
          Text(
            '掼蛋 | 队伍0: ${_levelName(state.team0Level)}  队伍1: ${_levelName(state.team1Level)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildOpponentTop(GuandanGameState state, int seatIndex) {
    final player = state.players.firstWhere(
      (p) => p.seatIndex == seatIndex,
      orElse: () => GuandanPlayer(
        id: '', name: '', teamId: 0, seatIndex: seatIndex),
    );
    final isCurrentTurn = state.players.isNotEmpty &&
        state.currentPlayer.seatIndex == seatIndex;

    return Column(
      children: [
        _playerLabel(player, isCurrentTurn),
        const SizedBox(height: 2),
        GuandanHandWidget(
          cards: player.cards,
          faceDown: true,
          cardWidth: 26,
          cardHeight: 40,
        ),
      ],
    );
  }

  Widget _buildSidePlayer(
      GuandanGameState state, int seatIndex, {required bool isLeft}) {
    final player = state.players.firstWhere(
      (p) => p.seatIndex == seatIndex,
      orElse: () => GuandanPlayer(
        id: '', name: '', teamId: 0, seatIndex: seatIndex),
    );
    final isCurrentTurn = state.players.isNotEmpty &&
        state.currentPlayer.seatIndex == seatIndex;

    return SizedBox(
      width: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _playerLabel(player, isCurrentTurn),
          const SizedBox(height: 4),
          GuandanHandWidget(
            cards: player.cards,
            faceDown: true,
            isHorizontal: false,
            cardWidth: 32,
            cardHeight: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildLocalHand(GuandanPlayer player) {
    final gameState = ref.read(guandanGameProvider);
    final level = gameState.levelForTeam(player.teamId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GuandanHandWidget(
        cards: player.cards,
        selectedIndices: _selectedIndices,
        cardWidth: 44,
        cardHeight: 66,
        onCardTap: (i) {
          setState(() {
            if (_selectedIndices.contains(i)) {
              _selectedIndices.remove(i);
            } else {
              _selectedIndices.add(i);
            }
          });
        },
        calculatePreview: (draggedIndices) {
          final draggedCards =
              draggedIndices.map((i) => player.cards[i]).toList();
          final hand = ValidateHandUsecase.validate(draggedCards, level);
          return hand != null ? draggedIndices.toSet() : {};
        },
        onDragEnd: (indices) {
          setState(() {
            _selectedIndices
              ..clear()
              ..addAll(indices);
          });
        },
      ),
    );
  }

  Widget _playerLabel(GuandanPlayer player, bool isCurrentTurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? GameColors.dark.accentAmber.withAlpha(180)
            : Colors.black38,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${player.name} (${player.cardCount})',
        style: const TextStyle(color: Colors.white, fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  bool _canPlay(GuandanGameState state, GuandanPlayer? player) {
    if (player == null || _selectedIndices.isEmpty) return false;
    final selected = _selectedIndices
        .where((i) => i < player.cards.length)
        .map((i) => player.cards[i])
        .toList();
    final level = state.levelForTeam(player.teamId);
    final hand = ValidateHandUsecase.validate(selected, level);
    if (hand == null) return false;
    if (state.lastPlayedHand == null) return true;
    return hand.beats(state.lastPlayedHand!, level);
  }

  String _levelName(int level) => switch (level) {
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        14 => 'A',
        _ => level.toString(),
      };
}
