import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/doudizhu/ai/ai_player.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_config.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';
import 'package:poke_game/domain/doudizhu/usecases/call_landlord_usecase.dart';
import 'package:poke_game/domain/doudizhu/usecases/check_winner_usecase.dart';
import 'package:poke_game/domain/doudizhu/usecases/deal_cards_usecase.dart';
import 'package:poke_game/domain/doudizhu/usecases/play_cards_usecase.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_state.dart';
import 'package:uuid/uuid.dart';

/// 人类玩家
class HumanPlayer implements Player {
  @override
  final String id;

  @override
  final String name;

  @override
  List<Card> handCards;

  @override
  PlayerRole? role;

  HumanPlayer({
    required this.id,
    required this.name,
    this.handCards = const [],
    this.role,
  });

  @override
  Future<PlayDecision> decidePlay(
    List<Card>? lastPlayedCards,
    int? lastPlayerIndex,
  ) {
    // 人类玩家不使用此方法
    throw UnimplementedError();
  }

  @override
  Future<CallDecision> decideCall() {
    // 人类玩家不使用此方法
    throw UnimplementedError();
  }
}

/// 斗地主状态管理器
class DoudizhuNotifier extends StateNotifier<DoudizhuUiState> {
  final DealCardsUseCase _dealCardsUseCase;
  late CallLandlordUseCase _callLandlordUseCase;
  final PlayCardsUseCase _playCardsUseCase;
  final CheckWinnerUseCase _checkWinnerUseCase;
  final CardValidator _validator;
  final GameConfig _config;

  /// 人类玩家ID（固定为第一个玩家）
  static const String humanPlayerId = 'human';

  /// 暴露验证器供外部使用
  CardValidator get validator => _validator;

  DoudizhuNotifier({
    DealCardsUseCase? dealCardsUseCase,
    CallLandlordUseCase? callLandlordUseCase,
    PlayCardsUseCase? playCardsUseCase,
    CheckWinnerUseCase? checkWinnerUseCase,
    CardValidator? validator,
    GameConfig? config,
  })  : _dealCardsUseCase = dealCardsUseCase ?? DealCardsUseCase(),
        _playCardsUseCase = playCardsUseCase ?? PlayCardsUseCase(),
        _checkWinnerUseCase = checkWinnerUseCase ?? CheckWinnerUseCase(),
        _validator = validator ?? const CardValidator(),
        _config = config ?? GameConfig.defaultConfig,
        super(DoudizhuUiState.initial()) {
    _callLandlordUseCase = callLandlordUseCase ??
        CallLandlordUseCase(isHumanVsAi: _config.isHumanVsAi);
  }

  /// 开始游戏
  Future<void> startGame() async {
    // 防止重复调用
    if (state.isLoading) return;

    await _dealAndStartGame();
  }

  /// 发牌并开始游戏（内部方法）
  Future<void> _dealAndStartGame() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      const uuid = Uuid();
      final players = <Player>[
        HumanPlayer(id: humanPlayerId, name: '你'),
        AiPlayer(id: uuid.v4(), name: 'AI-1'),
        AiPlayer(id: uuid.v4(), name: 'AI-2'),
      ];

      final gameState = _dealCardsUseCase(players);
      state = state.copyWith(
        gameState: gameState,
        isLoading: false,
        selectedCards: {},
        winners: null,
        clearHintCards: true,
      );

      // 如果第一个叫地主的是AI，自动处理
      final callingIndex = gameState.callingPlayerIndex ?? 0;
      if (gameState.players[callingIndex] is AiPlayer) {
        await _handleAiCall();
      } else {
        // 人类先叫，递增 turnKey
        state = state.copyWith(turnKey: state.turnKey + 1);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(e, '开始游戏失败'),
      );
    }
  }

  /// 叫地主
  Future<void> callLandlord(bool call) async {
    // 边界检查
    if (state.isLoading) {
      state = state.copyWith(errorMessage: '请稍候...');
      return;
    }

    // 检查是否是玩家的回合
    if (state.gameState.callingPlayerIndex != 0) {
      state = state.copyWith(errorMessage: '不是你的回合');
      return;
    }

    try {
      final result = _callLandlordUseCase(
        state.gameState,
        humanPlayerId,
        call,
      );

      final newGameState = result.gameState;
      state = state.copyWith(
        gameState: newGameState,
        clearHintCards: true,
        // 非人机模式下，全部不叫时显示提示消息
        infoMessage: result.allPassed ? '全部不叫，重新发牌' : null,
        clearInfoMessage: !result.allPassed,
      );

      // 检查是否进入出牌阶段
      if (newGameState.phase == GamePhase.playing) {
        // 如果地主是AI，开始出牌
        final landlord = newGameState.landlord;
        if (landlord is AiPlayer) {
          await _handleAiPlay();
        } else {
          // 人类是地主，先出牌，递增 turnKey
          state = state.copyWith(turnKey: state.turnKey + 1);
        }
      } else if (newGameState.phase == GamePhase.waiting) {
        // 全部不叫，重新发牌（延迟一下让用户看到提示）
        await Future.delayed(const Duration(milliseconds: 1500));
        await _dealAndStartGame();
      } else if (newGameState.phase == GamePhase.calling) {
        // 继续下一个玩家叫地主
        final nextCallingIndex = newGameState.callingPlayerIndex ?? 0;
        final nextPlayer = newGameState.players[nextCallingIndex];
        if (nextPlayer is AiPlayer) {
          await _handleAiCall();
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: _formatError(e, '叫地主失败'));
    }
  }

  /// 出牌
  Future<void> playCards() async {
    // 边界检查：是否在加载中
    if (state.isLoading) {
      state = state.copyWith(errorMessage: '请稍候...');
      return;
    }

    // 边界检查：是否轮到玩家
    if (state.gameState.currentPlayerIndex != 0) {
      state = state.copyWith(errorMessage: '不是你的回合');
      return;
    }

    // 边界检查：游戏是否已结束
    if (state.gameState.phase == GamePhase.finished) {
      state = state.copyWith(errorMessage: '游戏已结束');
      return;
    }

    if (state.selectedCards.isEmpty) {
      state = state.copyWith(errorMessage: '请选择要出的牌');
      return;
    }

    final cards = state.selectedCards.toList()..sort();

    // 验证牌型
    final combination = _validator.validate(cards);
    if (combination == null) {
      state = state.copyWith(errorMessage: '无效的牌型');
      return;
    }

    // 验证是否能打过上家
    final lastPlayed = state.gameState.lastPlayedCards;
    if (lastPlayed != null) {
      if (!_validator.canBeat(cards, lastPlayed)) {
        state = state.copyWith(errorMessage: '牌型不符合规则或打不过上家');
        return;
      }
    }

    try {
      var gameState = state.gameState;
      gameState = _playCardsUseCase(gameState, humanPlayerId, cards);
      state = state.copyWith(
        gameState: gameState,
        selectedCards: {},
      );

      // 检查胜负
      final winners = _checkWinnerUseCase(gameState);
      if (winners != null) {
        state = state.copyWith(
          gameState: gameState.copyWith(phase: GamePhase.finished),
          winners: winners,
        );
        return;
      }

      // 处理AI出牌
      await _handleAiPlay();
    } catch (e) {
      state = state.copyWith(errorMessage: _formatError(e, '出牌失败'));
    }
  }

  /// 过牌
  Future<void> passTurn() async {
    // 边界检查
    if (state.isLoading) {
      state = state.copyWith(errorMessage: '请稍候...');
      return;
    }

    if (state.gameState.currentPlayerIndex != 0) {
      state = state.copyWith(errorMessage: '不是你的回合');
      return;
    }

    if (state.gameState.phase == GamePhase.finished) {
      state = state.copyWith(errorMessage: '游戏已结束');
      return;
    }

    // 检查是否可以过牌
    final lastPlayed = state.gameState.lastPlayedCards;
    if (lastPlayed == null) {
      state = state.copyWith(errorMessage: '新一轮必须出牌');
      return;
    }

    try {
      var gameState = state.gameState;
      gameState = _playCardsUseCase.pass(gameState, humanPlayerId);
      state = state.copyWith(gameState: gameState, clearHintCards: true);

      // 处理AI出牌
      await _handleAiPlay();
    } catch (e) {
      state = state.copyWith(errorMessage: _formatError(e, '过牌失败'));
    }
  }

  /// 切换卡牌选中状态
  void toggleCardSelection(Card card) {
    final newSelection = Set<Card>.from(state.selectedCards);
    if (newSelection.contains(card)) {
      newSelection.remove(card);
    } else {
      newSelection.add(card);
    }
    state = state.copyWith(selectedCards: newSelection, clearHintCards: true);
  }

  /// 拖拽选牌 - 从划过的牌中智能选择最优牌型
  void selectCardsByDrag(List<Card> draggedCards) {
    if (draggedCards.isEmpty) return;

    final lastPlayedCards = state.gameState.lastPlayedCards;

    List<Card>? selectedCards;

    if (lastPlayedCards == null) {
      // 先手情况：找出最大牌型
      selectedCards = _validator.findBestCombination(draggedCards);
    } else {
      // 非先手情况：找出能打过上家的最小牌型
      selectedCards = _validator.findMinBeatingCombination(draggedCards, lastPlayedCards);
    }

    if (selectedCards != null && selectedCards.isNotEmpty) {
      state = state.copyWith(
        selectedCards: selectedCards.toSet(),
        clearHintCards: true,
      );
    } else {
      // 无法组成有效牌型，清空选择
      state = state.copyWith(selectedCards: {}, clearHintCards: true);
    }
  }

  /// 提示可出的牌
  void showHintCards() {
    final humanPlayer = state.gameState.players.firstWhere(
      (p) => p.id == humanPlayerId,
      orElse: () => throw StateError('玩家不存在'),
    );
    final handCards = humanPlayer.handCards;
    final lastPlayedCards = state.gameState.lastPlayedCards;

    List<Card>? hintCards;

    if (lastPlayedCards == null) {
      // 新一轮，提示最小的单张
      hintCards = [handCards.last];
    } else {
      // 尝试找能打过的牌
      hintCards = _findValidCards(
        handCards: handCards,
        lastPlayedCards: lastPlayedCards,
      );
    }

    if (hintCards != null) {
      state = state.copyWith(
        selectedCards: hintCards.toSet(),
        hintCards: hintCards.toSet(),
      );
    } else {
      // 没有能打的牌，清空选中
      state = state.copyWith(
        selectedCards: {},
        clearHintCards: true,
      );
    }
  }

  /// 找到能打过的牌（复用 AI 策略逻辑）
  List<Card>? _findValidCards({
    required List<Card> handCards,
    required List<Card> lastPlayedCards,
  }) {
    final lastCombination = _validator.validate(lastPlayedCards);
    if (lastCombination == null) return null;

    List<Card>? result;

    switch (lastCombination) {
      case CardCombination.single:
        result = _findSingleToPlay(handCards, lastPlayedCards.first.rank);
      case CardCombination.pair:
        result = _findPairToPlay(handCards, lastPlayedCards.first.rank);
      case CardCombination.triple:
        result = _findTripleToPlay(handCards, lastPlayedCards.first.rank);
      case CardCombination.tripleWithSingle:
        result = _findTripleWithSingleToPlay(handCards, lastPlayedCards);
      case CardCombination.tripleWithPair:
        result = _findTripleWithPairToPlay(handCards, lastPlayedCards);
      case CardCombination.straight:
        result = _findStraightToPlay(handCards, lastPlayedCards);
      case CardCombination.pairStraight:
        result = _findPairStraightToPlay(handCards, lastPlayedCards);
      case CardCombination.plane:
      case CardCombination.planeWithSingles:
      case CardCombination.planeWithPairs:
        result = _findPlaneToPlay(handCards, lastPlayedCards, lastCombination);
      case CardCombination.fourWithTwoSingles:
      case CardCombination.fourWithTwoPairs:
        result = _findFourWithToPlay(handCards, lastPlayedCards, lastCombination);
      case CardCombination.bomb:
        result = _findBombToPlay(handCards, lastPlayedCards);
      case CardCombination.rocket:
        result = null;
    }

    // 如果找不到同类型更大的牌，尝试用炸弹压制
    if (result == null &&
        lastCombination != CardCombination.bomb &&
        lastCombination != CardCombination.rocket) {
      result = _findBombToPlay(handCards, lastPlayedCards);
    }

    return result;
  }

  /// 找单张
  List<Card>? _findSingleToPlay(List<Card> handCards, int lastRank) {
    for (var i = handCards.length - 1; i >= 0; i--) {
      if (handCards[i].rank > lastRank) {
        return [handCards[i]];
      }
    }
    return null;
  }

  /// 找对子
  List<Card>? _findPairToPlay(List<Card> handCards, int lastRank) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 2 && entry.key > lastRank) {
        return entry.value.sublist(0, 2);
      }
    }
    return null;
  }

  /// 找三张
  List<Card>? _findTripleToPlay(List<Card> handCards, int lastRank) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 3 && entry.key > lastRank) {
        return entry.value.sublist(0, 3);
      }
    }
    return null;
  }

  /// 找三带一
  List<Card>? _findTripleWithSingleToPlay(List<Card> handCards, List<Card> lastPlayedCards) {
    final lastRankCounts = <int, int>{};
    for (final card in lastPlayedCards) {
      lastRankCounts[card.rank] = (lastRankCounts[card.rank] ?? 0) + 1;
    }
    int? lastTripleRank;
    for (final entry in lastRankCounts.entries) {
      if (entry.value == 3) {
        lastTripleRank = entry.key;
        break;
      }
    }
    if (lastTripleRank == null) return null;

    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 3 && entry.key > lastTripleRank) {
        final triple = entry.value.sublist(0, 3);
        for (final singleEntry in rankCounts.entries) {
          if (singleEntry.key != entry.key && singleEntry.value.isNotEmpty) {
            return [...triple, singleEntry.value.first];
          }
        }
      }
    }
    return null;
  }

  /// 找三带二
  List<Card>? _findTripleWithPairToPlay(List<Card> handCards, List<Card> lastPlayedCards) {
    final lastRankCounts = <int, int>{};
    for (final card in lastPlayedCards) {
      lastRankCounts[card.rank] = (lastRankCounts[card.rank] ?? 0) + 1;
    }
    int? lastTripleRank;
    for (final entry in lastRankCounts.entries) {
      if (entry.value == 3) {
        lastTripleRank = entry.key;
        break;
      }
    }
    if (lastTripleRank == null) return null;

    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    for (final entry in rankCounts.entries) {
      if (entry.value.length >= 3 && entry.key > lastTripleRank) {
        final triple = entry.value.sublist(0, 3);
        for (final pairEntry in rankCounts.entries) {
          if (pairEntry.key != entry.key && pairEntry.value.length >= 2) {
            return [...triple, ...pairEntry.value.sublist(0, 2)];
          }
        }
      }
    }
    return null;
  }

  /// 找顺子
  List<Card>? _findStraightToPlay(List<Card> handCards, List<Card> lastPlayedCards) {
    final length = lastPlayedCards.length;
    final lastRanks = lastPlayedCards.map((c) => c.rank).toList()..sort();
    final lastMinRank = lastRanks.first;

    final rankCards = <int, Card>{};
    for (final card in handCards) {
      if (card.rank >= 15) continue;
      if (!rankCards.containsKey(card.rank)) {
        rankCards[card.rank] = card;
      }
    }

    final sortedRanks = rankCards.keys.toList()..sort();
    for (var i = 0; i <= sortedRanks.length - length; i++) {
      final startRank = sortedRanks[i];
      var isConsecutive = true;
      for (var j = 1; j < length; j++) {
        if (sortedRanks[i + j] != startRank + j) {
          isConsecutive = false;
          break;
        }
      }
      if (isConsecutive && startRank > lastMinRank) {
        return List.generate(length, (j) => rankCards[startRank + j]!);
      }
    }
    return null;
  }

  /// 找连对
  List<Card>? _findPairStraightToPlay(List<Card> handCards, List<Card> lastPlayedCards) {
    final pairCount = lastPlayedCards.length ~/ 2;
    final lastRanks = lastPlayedCards.map((c) => c.rank).toList()..sort();
    final lastMinRank = lastRanks.first;

    final rankPairs = <int, List<Card>>{};
    for (final card in handCards) {
      if (card.rank >= 15) continue;
      rankPairs.putIfAbsent(card.rank, () => []).add(card);
    }

    final pairRanks = rankPairs.entries
        .where((e) => e.value.length >= 2)
        .map((e) => e.key)
        .toList()
      ..sort();

    for (var i = 0; i <= pairRanks.length - pairCount; i++) {
      final startRank = pairRanks[i];
      var isConsecutive = true;
      for (var j = 1; j < pairCount; j++) {
        if (pairRanks[i + j] != startRank + j) {
          isConsecutive = false;
          break;
        }
      }
      if (isConsecutive && startRank > lastMinRank) {
        final result = <Card>[];
        for (var j = 0; j < pairCount; j++) {
          result.addAll(rankPairs[startRank + j]!.sublist(0, 2));
        }
        return result;
      }
    }
    return null;
  }

  /// 找飞机
  List<Card>? _findPlaneToPlay(List<Card> handCards, List<Card> lastPlayedCards, CardCombination lastCombination) {
    final lastRankCounts = <int, int>{};
    for (final card in lastPlayedCards) {
      lastRankCounts[card.rank] = (lastRankCounts[card.rank] ?? 0) + 1;
    }
    final lastTripleRanks = lastRankCounts.entries
        .where((e) => e.value == 3)
        .map((e) => e.key)
        .toList()
      ..sort();
    final lastMinTripleRank = lastTripleRanks.firstOrNull;
    if (lastMinTripleRank == null) return null;

    final tripleCount = lastTripleRanks.length;

    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    final tripleRanks = rankCounts.entries
        .where((e) => e.value.length >= 3 && e.key < 15)
        .map((e) => e.key)
        .toList()
      ..sort();

    for (var i = 0; i <= tripleRanks.length - tripleCount; i++) {
      final startRank = tripleRanks[i];
      var isConsecutive = true;
      for (var j = 1; j < tripleCount; j++) {
        if (tripleRanks[i + j] != startRank + j) {
          isConsecutive = false;
          break;
        }
      }
      if (isConsecutive && startRank > lastMinTripleRank) {
        final tripleCards = <Card>[];
        for (var j = 0; j < tripleCount; j++) {
          tripleCards.addAll(rankCounts[startRank + j]!.sublist(0, 3));
        }

        if (lastCombination == CardCombination.plane) {
          return tripleCards;
        } else if (lastCombination == CardCombination.planeWithSingles) {
          final singles = <Card>[];
          for (final entry in rankCounts.entries) {
            if (!tripleRanks.sublist(i, i + tripleCount).contains(entry.key)) {
              singles.addAll(entry.value);
              if (singles.length >= tripleCount) break;
            }
          }
          if (singles.length >= tripleCount) {
            return [...tripleCards, ...singles.sublist(0, tripleCount)];
          }
        } else if (lastCombination == CardCombination.planeWithPairs) {
          final pairs = <Card>[];
          for (final entry in rankCounts.entries) {
            if (!tripleRanks.sublist(i, i + tripleCount).contains(entry.key) &&
                entry.value.length >= 2) {
              pairs.addAll(entry.value.sublist(0, 2));
              if (pairs.length >= tripleCount * 2) break;
            }
          }
          if (pairs.length >= tripleCount * 2) {
            return [...tripleCards, ...pairs];
          }
        }
      }
    }
    return null;
  }

  /// 找四带二
  List<Card>? _findFourWithToPlay(List<Card> handCards, List<Card> lastPlayedCards, CardCombination lastCombination) {
    final lastRankCounts = <int, int>{};
    for (final card in lastPlayedCards) {
      lastRankCounts[card.rank] = (lastRankCounts[card.rank] ?? 0) + 1;
    }
    int? lastFourRank;
    for (final entry in lastRankCounts.entries) {
      if (entry.value == 4) {
        lastFourRank = entry.key;
        break;
      }
    }
    if (lastFourRank == null) return null;

    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    for (final entry in rankCounts.entries) {
      if (entry.value.length == 4 && entry.key > lastFourRank) {
        final four = entry.value;
        if (lastCombination == CardCombination.fourWithTwoSingles) {
          final singles = <Card>[];
          for (final singleEntry in rankCounts.entries) {
            if (singleEntry.key != entry.key) {
              singles.addAll(singleEntry.value);
              if (singles.length >= 2) break;
            }
          }
          if (singles.length >= 2) {
            return [...four, ...singles.sublist(0, 2)];
          }
        } else if (lastCombination == CardCombination.fourWithTwoPairs) {
          final pairs = <Card>[];
          for (final pairEntry in rankCounts.entries) {
            if (pairEntry.key != entry.key && pairEntry.value.length >= 2) {
              pairs.addAll(pairEntry.value.sublist(0, 2));
              if (pairs.length >= 4) break;
            }
          }
          if (pairs.length >= 4) {
            return [...four, ...pairs];
          }
        }
      }
    }
    return null;
  }

  /// 找炸弹
  List<Card>? _findBombToPlay(List<Card> handCards, List<Card> lastPlayedCards) {
    final rankCounts = <int, List<Card>>{};
    for (final card in handCards) {
      rankCounts.putIfAbsent(card.rank, () => []).add(card);
    }

    final lastCombination = _validator.validate(lastPlayedCards);
    for (final entry in rankCounts.entries) {
      if (entry.value.length == 4) {
        if (lastCombination == CardCombination.bomb) {
          if (entry.key > lastPlayedCards.first.rank) {
            return entry.value;
          }
        } else {
          return entry.value;
        }
      }
    }

    // 找王炸
    final hasSmallJoker = handCards.any((c) => c.isSmallJoker);
    final hasBigJoker = handCards.any((c) => c.isBigJoker);
    if (hasSmallJoker && hasBigJoker) {
      return handCards.where((c) => c.isJoker).toList();
    }

    return null;
  }

  /// 处理AI叫地主
  Future<void> _handleAiCall() async {
    final callingIndex = state.gameState.callingPlayerIndex ?? 0;
    final currentPlayer = state.gameState.players[callingIndex] as AiPlayer;
    final decision = await currentPlayer.decideCall();

    final result = _callLandlordUseCase(
      state.gameState,
      currentPlayer.id,
      decision.shouldCall,
    );

    final newGameState = result.gameState;
    state = state.copyWith(
      gameState: newGameState,
      // 非人机模式下，全部不叫时显示提示消息
      infoMessage: result.allPassed ? '全部不叫，重新发牌' : null,
      clearInfoMessage: !result.allPassed,
    );

    if (newGameState.phase == GamePhase.playing) {
      // 进入出牌阶段
      final landlord = newGameState.landlord;
      if (landlord is AiPlayer) {
        await _handleAiPlay();
      } else {
        // 人类是地主，递增 turnKey
        state = state.copyWith(turnKey: state.turnKey + 1);
      }
    } else if (newGameState.phase == GamePhase.waiting) {
      // 全部不叫，重新发牌（延迟一下让用户看到提示）
      await Future.delayed(const Duration(milliseconds: 1500));
      await _dealAndStartGame();
    } else if (newGameState.phase == GamePhase.calling) {
      // 继续下一个玩家
      final nextCallingIndex = newGameState.callingPlayerIndex ?? 0;
      final nextPlayer = newGameState.players[nextCallingIndex];
      if (nextPlayer is AiPlayer) {
        await _handleAiCall();
      }
    }
  }

  /// 处理AI出牌
  Future<void> _handleAiPlay() async {
    while (true) {
      final currentPlayer = state.gameState.currentPlayer;
      if (currentPlayer == null || currentPlayer is! AiPlayer) {
        break;
      }

      final decision = await currentPlayer.decidePlay(
        state.gameState.lastPlayedCards,
        state.gameState.lastPlayerIndex,
      );

      try {
        var gameState = state.gameState;
        if (decision.shouldPlay && decision.cards != null) {
          gameState = _playCardsUseCase(gameState, currentPlayer.id, decision.cards!);
        } else {
          gameState = _playCardsUseCase.pass(gameState, currentPlayer.id);
        }

        state = state.copyWith(gameState: gameState);

        // 检查胜负
        final winners = _checkWinnerUseCase(gameState);
        if (winners != null) {
          state = state.copyWith(
            gameState: gameState.copyWith(phase: GamePhase.finished),
            winners: winners,
          );
          return;
        }

        // 检查下一个玩家是否是人类
        final nextPlayer = gameState.players[gameState.currentPlayerIndex];
        if (nextPlayer is! AiPlayer) {
          // 轮到人类，递增 turnKey 驱动倒计时重置
          state = state.copyWith(turnKey: state.turnKey + 1);
          break;
        }
      } catch (e) {
        // AI出牌失败，跳过
        break;
      }
    }
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 格式化错误信息，提供用户友好的提示
  String _formatError(Object error, String defaultMessage) {
    if (error is ArgumentError) {
      return error.message.toString();
    }
    if (error is StateError) {
      return error.message;
    }
    if (error is FormatException) {
      return '数据格式错误';
    }
    if (error is TimeoutException) {
      return '操作超时，请重试';
    }
    return defaultMessage;
  }
}
