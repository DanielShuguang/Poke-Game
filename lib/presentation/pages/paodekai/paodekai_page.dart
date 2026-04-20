import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/core/network/pdk_network_adapter.dart';
import 'package:poke_game/domain/paodekai/ai/pdk_ai_strategy.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_game_state.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_network_action.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_player.dart';
import 'package:poke_game/presentation/pages/paodekai/providers/pdk_notifier.dart';
import 'package:poke_game/domain/paodekai/usecases/hint_usecase.dart';
import 'package:poke_game/domain/paodekai/usecases/validate_play_usecase.dart';
import 'package:poke_game/presentation/pages/paodekai/widgets/card_hand.dart';
import 'package:poke_game/presentation/pages/paodekai/widgets/game_result_dialog.dart';
import 'package:poke_game/presentation/pages/paodekai/widgets/opponent_seat.dart';
import 'package:poke_game/presentation/pages/paodekai/widgets/play_area.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';
import 'package:poke_game/presentation/shared/widgets/game_back_button.dart';

class PaodekaiPage extends ConsumerStatefulWidget {
  final bool isOnline;
  final PdkNetworkAdapter? networkAdapter;
  final int turnTimeLimit;

  const PaodekaiPage({
    super.key,
    this.isOnline = false,
    this.networkAdapter,
    this.turnTimeLimit = 35,
  });

  @override
  ConsumerState<PaodekaiPage> createState() => _PaodekaiPageState();
}

class _PaodekaiPageState extends ConsumerState<PaodekaiPage> {
  final Set<int> _selectedIndices = {};
  Set<int> _hintIndices = {};
  bool _showResultDialog = false;
  bool _isAiThinking = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  static const _validate = ValidatePlayUseCase();
  static const _ai = PdkAiStrategy();
  static const _hint = HintUseCase();

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
      if (!widget.isOnline) {
        _initSinglePlayer();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    widget.networkAdapter?.stop();
    super.dispose();
  }

  void _initSinglePlayer() {
    final notifier = ref.read(pdkGameProvider.notifier);
    notifier.startGame([
      const PdkPlayer(id: 'human', name: '玩家', hand: [], isAi: false),
      const PdkPlayer(id: 'ai1', name: 'AI 1', hand: [], isAi: true),
      const PdkPlayer(id: 'ai2', name: 'AI 2', hand: [], isAi: true),
    ]);
    _scheduleAiIfNeeded();
  }

  void _scheduleAiIfNeeded() {
    final state = ref.read(pdkGameProvider);
    if (state.phase != PdkGamePhase.playing) return;
    final current = state.currentPlayer;
    if (current.isAi && !_isAiThinking) {
      _runAi(state, current.id);
    }
  }

  Future<void> _runAi(PdkGameState state, String aiId) async {
    if (!mounted) return;
    setState(() => _isAiThinking = true);
    final cards = await _ai.decidePlay(state, aiId);
    if (!mounted) return;
    setState(() => _isAiThinking = false);
    final notifier = ref.read(pdkGameProvider.notifier);
    if (cards != null) {
      notifier.playCards(aiId, cards);
    } else {
      notifier.pass(aiId);
    }
    _scheduleAiIfNeeded();
  }

  void _onPlay() {
    final activeIndices = _selectedIndices.isNotEmpty ? _selectedIndices : _hintIndices;
    if (activeIndices.isEmpty) return;
    final state = ref.read(pdkGameProvider);
    final pidx = state.players.indexWhere((p) => p.id == localId);
    if (pidx == -1 || pidx != state.currentPlayerIndex) return;

    final selected =
        activeIndices.map((i) => state.players[pidx].hand[i]).toList();

    if (widget.isOnline) {
      widget.networkAdapter!.sendAction(
        PdkNetworkAction(
          action: PdkActionType.playCards,
          playerId: localId,
          cards: selected,
        ),
      );
    } else {
      final ok = ref.read(pdkGameProvider.notifier).playCards(localId, selected);
      if (!ok) return;
    }
    setState(() {
      _selectedIndices.clear();
      _hintIndices = {};
    });
    _stopCountdown();
    _scheduleAiIfNeeded();
  }

  void _onPass() {
    if (widget.isOnline) {
      widget.networkAdapter!.sendAction(
        PdkNetworkAction(
          action: PdkActionType.pass,
          playerId: localId,
        ),
      );
    } else {
      ref.read(pdkGameProvider.notifier).pass(localId);
    }
    setState(() {
      _selectedIndices.clear();
      _hintIndices = {};
    });
    _stopCountdown();
    _scheduleAiIfNeeded();
  }

  void _onHint() {
    final state = ref.read(pdkGameProvider);
    final pidx = state.players.indexWhere((p) => p.id == localId);
    if (pidx == -1) return;
    final hand = state.players[pidx].hand;
    final cards = _hint(hand: hand, lastPlayedHand: state.lastPlayedHand);
    if (cards == null) return;
    final indices = cards.map((c) => hand.indexOf(c)).where((i) => i != -1).toSet();
    setState(() {
      _selectedIndices.clear();
      _hintIndices = indices;
    });
  }

  bool get _canPlay {
    final state = ref.read(pdkGameProvider);
    final pidx = state.players.indexWhere((p) => p.id == localId);
    final activeIndices = _selectedIndices.isNotEmpty ? _selectedIndices : _hintIndices;
    if (pidx == -1 || activeIndices.isEmpty) return false;
    final hand = state.players[pidx].hand;
    final selected = activeIndices.map((i) => hand[i]).toList();
    return _validate(selectedCards: selected, state: state) != null;
  }

  bool get _canHint {
    final state = ref.read(pdkGameProvider);
    final pidx = state.players.indexWhere((p) => p.id == localId);
    if (pidx == -1) return false;
    return _hint(
          hand: state.players[pidx].hand,
          lastPlayedHand: state.lastPlayedHand,
        ) !=
        null;
  }

  bool get _isLocalTurn {
    final state = ref.read(pdkGameProvider);
    final pidx = state.players.indexWhere((p) => p.id == localId);
    return pidx != -1 && pidx == state.currentPlayerIndex;
  }

  bool get _isStartOfRound {
    final state = ref.read(pdkGameProvider);
    return state.lastPlayedHand == null;
  }

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
        if (!widget.isOnline) {
          final notifier = ref.read(pdkGameProvider.notifier);
          final s = ref.read(pdkGameProvider);
          if (s.lastPlayedHand == null) {
            notifier.forcePlayCards(localId);
          } else {
            notifier.forcePass(localId);
          }
          _scheduleAiIfNeeded();
        }
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (mounted && _countdown != 0) setState(() => _countdown = 0);
  }

  void _updateCountdown(PdkGameState state) {
    final pidx = state.players.indexWhere((p) => p.id == localId);
    final isMyTurn = pidx != -1 &&
        pidx == state.currentPlayerIndex &&
        state.phase == PdkGamePhase.playing;
    if (isMyTurn && _countdown == 0) {
      _startCountdown();
    } else if (!isMyTurn && _countdown > 0) {
      _stopCountdown();
    }
  }

  void _showExitDialog() {
    final colors = context.gameColors;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgSurface,
        title: Text('退出游戏', style: TextStyle(color: colors.textPrimary)),
        content: Text('确定要退出吗？', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('确定', style: TextStyle(color: colors.dangerRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pdkGameProvider);
    final colors = context.gameColors;

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCountdown(state));

    // 结算弹窗
    if (state.phase == PdkGamePhase.gameOver && !_showResultDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showResultDialog = true);
      });
    }

    final localIdx = state.players.indexWhere((p) => p.id == localId);
    final localPlayer = localIdx != -1 ? state.players[localIdx] : null;
    final opponents =
        state.players.where((p) => p.id != localId).toList();

    // 上次出牌玩家名（使用 state 中记录的精确下标，而非当前玩家前一位）
    String? lastPlayerName;
    final lastIdx = state.lastPlayedPlayerIndex;
    if (state.lastPlayedHand != null && lastIdx != null &&
        lastIdx < state.players.length) {
      lastPlayerName = state.players[lastIdx].name;
    }

    // 当前应出牌的玩家名
    final currentPlayerName = state.players.isNotEmpty
        ? state.players[state.currentPlayerIndex].name
        : '';

    return Scaffold(
      backgroundColor: colors.bgTable,
      body: Stack(
        children: [
          // 退出按钮
          Positioned(
            top: 8,
            left: 8,
            child: GameBackButton(onPressed: _showExitDialog),
          ),

          // 对手区域（左上 + 右上）
          if (opponents.isNotEmpty)
            Positioned(
              top: 16,
              left: 80,
              child: OpponentSeat(
                player: opponents[0],
                isCurrentPlayer: state.players.indexOf(opponents[0]) ==
                    state.currentPlayerIndex,
              ),
            ),
          if (opponents.length > 1)
            Positioned(
              top: 16,
              right: 16,
              child: OpponentSeat(
                player: opponents[1],
                isCurrentPlayer: state.players.indexOf(opponents[1]) ==
                    state.currentPlayerIndex,
              ),
            ),

          // 中央出牌区
          Center(
            child: PlayArea(
              lastPlayedHand: state.lastPlayedHand,
              lastPlayerName: lastPlayerName,
              currentPlayerName: currentPlayerName,
            ),
          ),

          // 本地玩家手牌 + 操作按钮
          if (localPlayer != null)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLocalTurn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_countdown > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 3),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _canHint ? _onHint : null,
                                icon: Icon(
                                  Icons.lightbulb_outline,
                                  color: _canHint
                                      ? colors.accentAmber
                                      : Colors.white30,
                                  size: 18,
                                ),
                                label: Text(
                                  '提示',
                                  style: TextStyle(
                                    color: _canHint
                                        ? colors.accentAmber
                                        : Colors.white30,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton(
                                onPressed: _canPlay ? _onPlay : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: colors.primaryGreen.withValues(alpha: 0.35),
                                  disabledForegroundColor: Colors.white54,
                                ),
                                child: const Text('出牌'),
                              ),
                              const SizedBox(width: 12),
                              if (!_isStartOfRound)
                                OutlinedButton(
                                  onPressed: _onPass,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white60),
                                  ),
                                  child: const Text('不出'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  CardHand(
                    cards: localPlayer.hand,
                    selectedIndices: _selectedIndices,
                    hintIndices: _hintIndices,
                    enabled: _isLocalTurn,
                    onCardTap: (i) {
                      setState(() {
                        _hintIndices = {};
                        if (_selectedIndices.contains(i)) {
                          _selectedIndices.remove(i);
                        } else {
                          _selectedIndices.add(i);
                        }
                      });
                    },
                    onSelectionChanged: (indices) {
                      setState(() {
                        _hintIndices = {};
                        _selectedIndices
                          ..clear()
                          ..addAll(indices);
                      });
                    },
                  ),
                ],
              ),
            ),

          // 结算弹窗
          if (_showResultDialog)
            Center(
              child: GameResultDialog(
                state: state,
                onPlayAgain: () {
                  setState(() {
                    _showResultDialog = false;
                    _selectedIndices.clear();
                    _hintIndices = {};
                  });
                  _initSinglePlayer();
                },
                onExit: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }
}
