import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/shengji/ai/strategies/call_strategy.dart';
import 'package:poke_game/domain/shengji/ai/strategies/play_strategy.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_config.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/entities/shengji_player.dart';
import 'package:poke_game/domain/shengji/entities/shengji_team.dart';
import 'package:poke_game/domain/shengji/usecases/call_trump_usecase.dart';
import 'package:poke_game/domain/shengji/usecases/deal_cards_usecase.dart';
import 'package:poke_game/domain/shengji/usecases/play_cards_usecase.dart';
import 'package:poke_game/domain/shengji/usecases/settle_round_usecase.dart';
import 'package:poke_game/domain/shengji/validators/call_validator.dart';
import 'package:poke_game/domain/shengji/validators/play_validator.dart';

/// 升级游戏状态管理器
class ShengjiNotifier extends StateNotifier<ShengjiGameState> {
  final ShengjiGameConfig _config;
  final DealCardsUseCase _dealCardsUseCase;
  final CallTrumpUseCase _callTrumpUseCase;
  final PlayCardsUseCase _playCardsUseCase;
  final SettleRoundUseCase _settleRoundUseCase;

  Timer? _timeoutTimer;

  ShengjiNotifier({
    ShengjiGameConfig config = const ShengjiGameConfig(),
  })  : _config = config,
        _dealCardsUseCase = DealCardsUseCase(),
        _callTrumpUseCase = CallTrumpUseCase(),
        _playCardsUseCase = PlayCardsUseCase(),
        _settleRoundUseCase = SettleRoundUseCase(),
        super(const ShengjiGameState());

  /// 初始化游戏
  void initGame(List<ShengjiPlayer> players, List<ShengjiTeam> teams) {
    state = state.copyWith(
      phase: ShengjiPhase.waiting,
      players: players,
      teams: teams,
    );
  }

  /// 开始游戏
  void startGame() {
    if (state.players.length != 4) return;

    // 发牌
    final result = _dealCardsUseCase.deal(
      playerIds: state.players.map((p) => p.id).toList(),
      playerNames: state.players.map((p) => p.name).toList(),
      teamIds: state.players.map((p) => p.teamId).toList(),
      seatIndices: state.players.map((p) => p.seatIndex).toList(),
    );

    state = state.copyWith(
      phase: ShengjiPhase.calling,
      players: result.players,
      bottomCards: result.bottomCards,
      currentSeatIndex: _getRandomDealer(),
      callHistory: {},
      completedRounds: [],
      currentRound: null,
    );

    _startTimeoutIfNeeded();
  }

  /// 叫牌
  void callTrump(String playerId, TrumpCall call) {
    _cancelTimeout();

    final result = _callTrumpUseCase.call(
      state: state,
      playerId: playerId,
      call: call,
    );

    if (result.success) {
      state = state.copyWith(
        callHistory: result.callHistory,
        trumpInfo: result.trumpInfo,
        dealerId: result.dealerId,
        currentSeatIndex: result.nextSeatIndex ?? state.currentSeatIndex,
      );

      if (result.callComplete) {
        _enterPlayingPhase();
      } else {
        _startTimeoutIfNeeded();
      }
    } else {
      state = state.copyWith(message: result.errorMessage);
    }
  }

  /// 跳过叫牌
  void passCall(String playerId) {
    _cancelTimeout();

    final result = _callTrumpUseCase.pass(
      state: state,
      playerId: playerId,
    );

    if (result.success) {
      state = state.copyWith(
        callHistory: result.callHistory,
        currentSeatIndex: result.nextSeatIndex ?? state.currentSeatIndex,
      );

      if (result.callComplete) {
        if (result.trumpInfo != null && result.dealerId != null) {
          state = state.copyWith(
            trumpInfo: result.trumpInfo,
            dealerId: result.dealerId,
          );
        }
        _enterPlayingPhase();
      } else {
        _startTimeoutIfNeeded();
      }
    }
  }

  /// 出牌
  void playCards(String playerId, List<ShengjiCard> cards) {
    _cancelTimeout();

    final result = _playCardsUseCase.play(
      state: state,
      playerId: playerId,
      cards: cards,
    );

    if (result.success) {
      state = state.copyWith(
        players: result.players,
        currentRound: result.currentRound,
      );

      // 检查一轮是否结束
      if (result.currentRound?.winnerSeatIndex != null) {
        _handleRoundEnd();
      } else {
        // 下一个玩家
        state = state.copyWith(
          currentSeatIndex: (state.currentSeatIndex + 1) % 4,
        );
        _startTimeoutIfNeeded();
      }
    } else {
      state = state.copyWith(message: result.errorMessage);
    }
  }

  /// 处理一轮结束
  void _handleRoundEnd() {
    final winnerSeatIndex = state.currentRound!.winnerSeatIndex!;
    final roundScore = state.currentRound!.getRoundScore();

    // 更新队伍得分
    final winner = state.getPlayerBySeat(winnerSeatIndex);
    if (winner == null) return;

    final newTeams = state.teams.map((team) {
      if (team.id == winner.teamId) {
        return team.copyWith(roundScore: team.roundScore + roundScore);
      }
      return team;
    }).toList();

    // 记录完成的轮次
    final completedRounds = [...state.completedRounds, state.currentRound!];

    // 检查是否所有牌都出完
    final allHandsEmpty = state.players.every((p) => p.hand.isEmpty);

    if (allHandsEmpty) {
      // 游戏结束，结算
      _settleGame(newTeams);
    } else {
      // 开始新一轮
      state = state.copyWith(
        teams: newTeams,
        completedRounds: completedRounds,
        currentRound: null,
        currentSeatIndex: winnerSeatIndex,
        clearCurrentRound: true,
      );
      _startTimeoutIfNeeded();
    }
  }

  /// 结算游戏
  void _settleGame(List<ShengjiTeam> teams) {
    final dealerTeam = teams.firstWhere((t) => t.isDealer);
    final opponentTeam = teams.firstWhere((t) => !t.isDealer);

    final result = _settleRoundUseCase.settle(
      state: state,
      dealerTeamScore: dealerTeam.roundScore,
      opponentTeamScore: opponentTeam.roundScore,
    );

    state = state.copyWith(
      phase: ShengjiPhase.finished,
      teams: result.newTeams,
      message: result.description,
    );
  }

  /// AI 自动操作
  void aiAutoAction(String playerId) {
    final player = state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null || !player.isAi) return;

    switch (state.phase) {
      case ShengjiPhase.calling:
        _aiCall(playerId, player);
        break;
      case ShengjiPhase.playing:
        _aiPlay(playerId, player);
        break;
      default:
        break;
    }
  }

  /// AI 叫牌
  void _aiCall(String playerId, ShengjiPlayer player) {
    final strategy = _config.aiDifficulty == AiDifficulty.easy
        ? EasyCallStrategy()
        : NormalCallStrategy();

    final dealerTeam = state.teams.firstWhere((t) => t.isDealer, orElse: () => state.teams.first);
    final call = strategy.evaluate(player.hand, dealerTeam.currentLevel);

    if (call != null) {
      callTrump(playerId, call);
    } else {
      passCall(playerId);
    }
  }

  /// AI 出牌
  void _aiPlay(String playerId, ShengjiPlayer player) {
    final strategy = _config.aiDifficulty == AiDifficulty.easy
        ? EasyPlayStrategy()
        : NormalPlayStrategy();

    // ignore: avoid_print
    print('[AI Play] $playerId phase=${state.phase} seat=${state.currentSeatIndex} trumpInfo=${state.trumpInfo} leadCards=${state.currentRound?.leadCards}');
    final cards = strategy.decide(state: state, playerId: playerId);
    // ignore: avoid_print
    print('[AI Play] $playerId decided: $cards');
    if (cards.isNotEmpty) {
      playCards(playerId, cards);
    } else {
      // ignore: avoid_print
      print('[AI Play] $playerId decided EMPTY cards - game will be stuck!');
    }
  }

  /// 进入出牌阶段
  void _enterPlayingPhase() {
    // 庄家获得底牌
    final dealer = state.dealer;
    if (dealer == null) return;

    final newPlayers = state.players.map((p) {
      if (p.id == dealer.id) {
        return p.copyWith(hand: [...p.hand, ...state.bottomCards]);
      }
      return p;
    }).toList();

    state = state.copyWith(
      phase: ShengjiPhase.playing,
      players: newPlayers,
      currentSeatIndex: dealer.seatIndex,
    );

    _startTimeoutIfNeeded();
  }

  /// 开始超时计时器
  void _startTimeoutIfNeeded() {
    if (!_config.enableTimeout) return;

    final currentPlayer = state.currentPlayer;
    if (currentPlayer == null) return;

    // 如果当前是 AI，立即执行
    if (currentPlayer.isAi) {
      Future.delayed(const Duration(milliseconds: 500), () {
        aiAutoAction(currentPlayer.id);
      });
      return;
    }

    _timeoutTimer = Timer(Duration(seconds: _config.timeoutSeconds), () {
      _handleTimeout(currentPlayer.id);
    });
  }

  /// 处理超时
  void _handleTimeout(String playerId) {
    final player = state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null || player.isAi) return;

    // 超时自动执行最小操作
    switch (state.phase) {
      case ShengjiPhase.calling:
        passCall(playerId);
        break;
      case ShengjiPhase.playing:
        _autoPlaySmallest(playerId);
        break;
      default:
        break;
    }
  }

  /// 自动出最小牌
  void _autoPlaySmallest(String playerId) {
    final player = state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) return;

    final hand = List<ShengjiCard>.from(player.hand);
    if (hand.isEmpty) return;

    hand.sort((a, b) => a.compareTo(b));

    // 尝试出最小的合法牌
    final leadCards = state.currentRound?.leadCards ?? [];
    if (leadCards.isEmpty) {
      playCards(playerId, [hand.first]);
    } else {
      // 找最小的合法牌组合
      final targetCount = leadCards.length;
      final combinations = _generateCombinations(hand, targetCount);

      for (final combo in combinations) {
        final validation = PlayValidator.validate(
          hand: hand,
          playedCards: combo,
          leadCards: leadCards,
          trumpInfo: state.trumpInfo!,
        );
        if (validation.isValid) {
          playCards(playerId, combo);
          return;
        }
      }

      // 无法找到合法牌，出最小的
      playCards(playerId, hand.sublist(0, targetCount.clamp(1, hand.length)));
    }
  }

  /// 生成牌组合
  List<List<ShengjiCard>> _generateCombinations(List<ShengjiCard> cards, int count) {
    if (count == 1) return cards.map((c) => [c]).toList();
    if (count > cards.length) return [];

    final result = <List<ShengjiCard>>[];
    _combine(cards, count, 0, <ShengjiCard>[], result);
    return result;
  }

  void _combine(
    List<ShengjiCard> cards,
    int count,
    int start,
    List<ShengjiCard> current,
    List<List<ShengjiCard>> result,
  ) {
    if (current.length == count) {
      result.add(List<ShengjiCard>.from(current));
      return;
    }
    for (int i = start; i < cards.length; i++) {
      current.add(cards[i]);
      _combine(cards, count, i + 1, current, result);
      current.removeLast();
    }
  }

  /// 取消超时计时器
  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// 获取随机庄家
  int _getRandomDealer() {
    return DateTime.now().millisecond % 4;
  }

  /// 清除消息
  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  /// 获取当前状态（供网络适配器使用）
  ShengjiGameState get currentState => state;

  /// 应用网络状态（供 Client 接收 Host 广播时使用）
  void applyNetworkState(ShengjiGameState newState) {
    state = newState;
  }

  /// 释放资源
  @override
  void dispose() {
    _cancelTimeout();
    super.dispose();
  }
}

/// Provider
final shengjiNotifierProvider =
    StateNotifierProvider.autoDispose<ShengjiNotifier, ShengjiGameState>(
  (ref) => ShengjiNotifier(),
);
