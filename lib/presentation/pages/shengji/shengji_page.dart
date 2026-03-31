import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/core/network/shengji_network_adapter.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_config.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/entities/shengji_network_action.dart';
import 'package:poke_game/domain/shengji/entities/shengji_player.dart';
import 'package:poke_game/domain/shengji/entities/shengji_team.dart';
import 'package:poke_game/domain/shengji/entities/trump_info.dart';
import 'package:poke_game/domain/shengji/notifiers/shengji_notifier.dart';
import 'package:poke_game/domain/shengji/validators/call_validator.dart';
import 'package:poke_game/presentation/pages/shengji/widgets/call_trump_dialog.dart';
import 'package:poke_game/presentation/pages/shengji/widgets/game_result_dialog.dart';
import 'package:poke_game/presentation/pages/shengji/widgets/player_seat.dart';
import 'package:poke_game/presentation/pages/shengji/widgets/score_board.dart';

class ShengjiPage extends ConsumerStatefulWidget {
  final bool isOnline;
  final ShengjiNetworkAdapter? networkAdapter;

  const ShengjiPage({
    super.key,
    this.isOnline = false,
    this.networkAdapter,
  });

  @override
  ConsumerState<ShengjiPage> createState() => _ShengjiPageState();
}

class _ShengjiPageState extends ConsumerState<ShengjiPage> {
  final Set<int> _selectedIndices = {}; // 使用索引而非牌对象，支持两副牌相同牌
  bool _showCallDialog = false;
  bool _showResultDialog = false;
  int _countdown = 0; // 倒计时秒数
  Timer? _countdownTimer; // 倒计时定时器

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
    final config = ShengjiGameConfig.defaultConfig;
    final notifier = ref.read(shengjiNotifierProvider.notifier);

    // 创建 4 名玩家
    final players = [
      ShengjiPlayer(
        id: 'human',
        name: '玩家',
        teamId: 0,
        hand: [],
        seatIndex: 0,
        isAi: false,
      ),
      ShengjiPlayer(
        id: 'ai1',
        name: 'AI 1',
        teamId: 1,
        hand: [],
        seatIndex: 1,
        isAi: true,
      ),
      ShengjiPlayer(
        id: 'ai2',
        name: 'AI 2',
        teamId: 0,
        hand: [],
        seatIndex: 2,
        isAi: true,
      ),
      ShengjiPlayer(
        id: 'ai3',
        name: 'AI 3',
        teamId: 1,
        hand: [],
        seatIndex: 3,
        isAi: true,
      ),
    ];

    // 创建两个队伍
    final teams = [
      ShengjiTeam(id: 0, playerIds: ['human', 'ai2'], currentLevel: config.initialLevel),
      ShengjiTeam(id: 1, playerIds: ['ai1', 'ai3'], currentLevel: config.initialLevel),
    ];

    notifier.initGame(players, teams);
    notifier.startGame();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onGameStateChanged(ShengjiGameState? previous, ShengjiGameState next) {
    // 进入叫牌阶段且轮到玩家
    if (next.phase == ShengjiPhase.calling) {
      final localPlayer = next.players.where((p) => p.id == localId).firstOrNull;
      if (localPlayer != null && next.currentSeatIndex == localPlayer.seatIndex) {
        if (!_showCallDialog) {
          setState(() => _showCallDialog = true);
        }
      }
    }

    // 进入出牌阶段
    if (next.phase == ShengjiPhase.playing && previous?.phase != ShengjiPhase.playing) {
      setState(() => _showCallDialog = false);
    }

    // 游戏结束
    if (next.phase == ShengjiPhase.finished && previous?.phase != ShengjiPhase.finished) {
      setState(() => _showResultDialog = true);
    }

    // 更新倒计时（轮到玩家时）
    _updateCountdown(next);
  }

  void _updateCountdown(ShengjiGameState state) {
    final localPlayer = state.players.where((p) => p.id == localId).firstOrNull;
    if (localPlayer == null || localPlayer.isAi) return;

    final isMyTurn = state.currentSeatIndex == localPlayer.seatIndex;
    final needCountdown = (state.phase == ShengjiPhase.calling || state.phase == ShengjiPhase.playing) && isMyTurn;

    if (needCountdown && _countdown == 0) {
      // 开始新的倒计时
      _startCountdown();
    } else if (!needCountdown) {
      // 不需要倒计时，重置
      _stopCountdown();
    }
  }

  bool get needMyTurn {
    final gameState = ref.read(shengjiNotifierProvider);
    final localPlayer = gameState.players.where((p) => p.id == localId).firstOrNull;
    if (localPlayer == null || localPlayer.isAi) return false;
    return gameState.currentSeatIndex == localPlayer.seatIndex &&
        (gameState.phase == ShengjiPhase.calling || gameState.phase == ShengjiPhase.playing);
  }

  void _startCountdown() {
    _countdown = 35;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _stopCountdown();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_countdown != 0) {
      setState(() => _countdown = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ShengjiGameState>(shengjiNotifierProvider, _onGameStateChanged);
    final gameState = ref.watch(shengjiNotifierProvider);
    final localPlayer = gameState.players.where((p) => p.id == localId).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Stack(
        children: [
          // 主游戏区域
          Column(
            children: [
              // 顶部信息栏
              _buildTopBar(gameState),
              // 中央游戏区域
              Expanded(
                child: _buildGameArea(gameState, localPlayer),
              ),
              // 底部手牌和操作区
              _buildBottomArea(gameState, localPlayer),
            ],
          ),
          // 叫牌对话框
          if (_showCallDialog && gameState.phase == ShengjiPhase.calling)
            CallTrumpDialog(
              gameState: gameState,
              localPlayerId: localId,
              onCall: (call) {
                _handleCall(call);
                setState(() => _showCallDialog = false);
              },
              onPass: () {
                _handlePass();
                setState(() => _showCallDialog = false);
              },
            ),
          // 结算对话框
          if (_showResultDialog && gameState.phase == ShengjiPhase.finished)
            GameResultDialog(
              gameState: gameState,
              onContinue: () {
                setState(() => _showResultDialog = false);
                ref.read(shengjiNotifierProvider.notifier).startGame();
              },
              onExit: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  /// 顶部信息栏
  Widget _buildTopBar(ShengjiGameState gameState) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => _showExitConfirmDialog(context),
          ),
          // 将牌信息
          if (gameState.trumpInfo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '将牌: ${gameState.trumpInfo}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          const Spacer(),
          // 倒计时
          if (_countdown > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _countdown <= 10 ? Colors.red.shade700 : Colors.orange.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_countdown 秒',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 12),
          // 计分板
          if (gameState.teams.isNotEmpty)
            ScoreBoard(teams: gameState.teams),
        ],
      ),
    );
  }

  /// 中央游戏区域
  Widget _buildGameArea(ShengjiGameState gameState, ShengjiPlayer? localPlayer) {
    return Stack(
      children: [
        // 四个座位（排除底部玩家，底部玩家标签放在手牌区）
        ...gameState.players.where((p) => p.seatIndex != 0).map((player) {
          return PlayerSeat(
            player: player,
            isCurrentPlayer: player.seatIndex == gameState.currentSeatIndex,
            isTeammate: localPlayer != null && player.isTeammateOf(localPlayer.seatIndex),
            playedCards: gameState.currentRound?.plays[player.seatIndex],
          );
        }),
        // 中央出牌区域
        if (gameState.currentRound != null)
          Center(
            child: _buildPlayArea(gameState),
          ),
      ],
    );
  }

  /// 中央出牌区域
  Widget _buildPlayArea(ShengjiGameState gameState) {
    final plays = gameState.currentRound?.plays ?? {};
    if (plays.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: plays.entries.map((entry) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '座位 ${entry.key}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: entry.value.map((card) => _buildCardWidget(card, 30)).toList(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 底部手牌和操作区
  Widget _buildBottomArea(ShengjiGameState gameState, ShengjiPlayer? localPlayer) {
    if (localPlayer == null) return const SizedBox.shrink();

    final isMyTurn = gameState.phase == ShengjiPhase.playing &&
        gameState.currentSeatIndex == localPlayer.seatIndex;

    final screenHeight = MediaQuery.of(context).size.height;
    // 底部最多占屏幕 55%，避免挤压中央游戏区
    final maxBottomHeight = (screenHeight * 0.55).clamp(140.0, 240.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxBottomHeight),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 玩家标签 + 操作按钮（同一行）
            Row(
              children: [
                _buildLocalPlayerLabel(localPlayer, gameState),
                if (isMyTurn) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _selectedIndices.isNotEmpty ? _handlePlay : null,
                    child: const Text('出牌', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _handleHint,
                    child: const Text('提示'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // 手牌换行展示
            _buildHandCards(localPlayer.hand, gameState),
          ],
        ),
      ),
    );
  }

  /// 本地玩家标签
  Widget _buildLocalPlayerLabel(ShengjiPlayer player, ShengjiGameState gameState) {
    final isCurrentPlayer = player.seatIndex == gameState.currentSeatIndex;
    final teammate = gameState.players.where((p) => p.seatIndex == 2).firstOrNull;
    final isTeammate = teammate != null && player.isTeammateOf(teammate.seatIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isTeammate ? Colors.blue.shade700 : Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentPlayer ? Border.all(color: Colors.yellow, width: 2) : null,
      ),
      child: Text(
        '${player.name}  ${player.hand.length}张',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  /// 手牌换行展示
  Widget _buildHandCards(List<ShengjiCard> hand, ShengjiGameState gameState) {
    final sortedHand = List<ShengjiCard>.from(hand)
      ..sort((a, b) {
        if (gameState.trumpInfo != null) {
          final aIsTrump = gameState.trumpInfo!.isTrump(a);
          final bIsTrump = gameState.trumpInfo!.isTrump(b);
          if (aIsTrump && !bIsTrump) return -1;
          if (!aIsTrump && bIsTrump) return 1;
        }
        return b.compareTo(a);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final availWidth = constraints.maxWidth;
        // 目标：2 行放完全部手牌，每行至少 5 张
        final perRow = (sortedHand.length / 2).ceil().clamp(5, 25);
        // 卡牌宽度 = (可用宽度 - 行间距) / 每行数量，限制在 20~50
        final cardWidth = ((availWidth - (perRow - 1) * 4) / perRow).clamp(20.0, 50.0);
        final cardHeight = (cardWidth / 0.7).clamp(28.0, 70.0);
        final selectOffset = (cardHeight * 0.16).clamp(4.0, 12.0);

        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(sortedHand.length, (index) {
            final card = sortedHand[index];
            final isSelected = _selectedIndices.contains(index);
            return GestureDetector(
              onTap: () => _toggleCardSelection(index),
              child: Transform.translate(
                offset: Offset(0, isSelected ? -selectOffset : 0),
                child: _buildCardWidget(card, cardHeight),
              ),
            );
          }),
        );
      },
    );
  }

  /// 牌面组件
  Widget _buildCardWidget(ShengjiCard card, double height) {
    return Container(
      width: height * 0.7,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
      ),
      child: Center(
        child: Text(
          card.toString(),
          style: TextStyle(
            color: card.isRed ? Colors.red : Colors.black,
            fontSize: height * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 切换牌选择
  void _toggleCardSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  /// 处理叫牌
  void _handleCall(TrumpCall call) {
    final notifier = ref.read(shengjiNotifierProvider.notifier);
    notifier.callTrump(localId, call);
  }

  /// 处理不叫
  void _handlePass() {
    final notifier = ref.read(shengjiNotifierProvider.notifier);
    notifier.passCall(localId);
  }

  /// 处理出牌
  void _handlePlay() {
    if (_selectedIndices.isEmpty) return;

    final gameState = ref.read(shengjiNotifierProvider);
    final localPlayer = gameState.players.where((p) => p.id == localId).firstOrNull;
    if (localPlayer == null) return;

    // 排序后获取选中的牌
    final sortedHand = List<ShengjiCard>.from(localPlayer.hand)
      ..sort((a, b) {
        if (gameState.trumpInfo != null) {
          final aIsTrump = gameState.trumpInfo!.isTrump(a);
          final bIsTrump = gameState.trumpInfo!.isTrump(b);
          if (aIsTrump && !bIsTrump) return -1;
          if (!aIsTrump && bIsTrump) return 1;
        }
        return b.compareTo(a);
      });

    final cards = _selectedIndices.map((i) => sortedHand[i]).toList();
    final notifier = ref.read(shengjiNotifierProvider.notifier);

    if (widget.isOnline && widget.networkAdapter != null && !widget.networkAdapter!.isHost) {
      // Client 发送行动
      widget.networkAdapter!.sendAction(ShengjiNetworkAction(
        action: ShengjiActionType.playCards,
        playerId: localId,
        cards: cards.map((c) => c.toJson()).toList(),
      ));
    } else {
      notifier.playCards(localId, cards);
    }

    setState(() => _selectedIndices.clear());
  }

  /// 处理提示
  void _handleHint() {
    // 简单提示：选择最小的牌
    final gameState = ref.read(shengjiNotifierProvider);
    final localPlayer = gameState.players.where((p) => p.id == localId).firstOrNull;
    if (localPlayer == null || localPlayer.hand.isEmpty) return;

    setState(() {
      _selectedIndices.clear();
      _selectedIndices.add(localPlayer.hand.length - 1); // 选中最后一张（排序后最小的牌）
    });
  }

  /// 显示退出确认对话框
  Future<void> _showExitConfirmDialog(BuildContext context) async {
    final navigator = Navigator.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出游戏'),
        content: const Text('确定要退出当前游戏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      navigator.pop();
    }
  }
}
