import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';

/// 游戏阶段
enum GamePhase {
  /// 等待开始
  waiting,

  /// 发牌中
  dealing,

  /// 叫地主阶段
  calling,

  /// 出牌阶段
  playing,

  /// 游戏结束
  finished,
}

/// 游戏状态
class GameState {
  /// 游戏阶段
  final GamePhase phase;

  /// 所有玩家
  final List<Player> players;

  /// 当前玩家索引
  final int currentPlayerIndex;

  /// 底牌
  final List<Card> landlordCards;

  /// 上一手牌
  final List<Card>? lastPlayedCards;

  /// 上一手牌玩家索引
  final int? lastPlayerIndex;

  /// 地主索引
  final int? landlordIndex;

  /// 当前叫地主玩家索引
  final int? callingPlayerIndex;

  /// 已叫地主次数（用于判断是否全部不叫）
  final int callCount;

  const GameState({
    required this.phase,
    required this.players,
    required this.currentPlayerIndex,
    required this.landlordCards,
    this.lastPlayedCards,
    this.lastPlayerIndex,
    this.landlordIndex,
    this.callingPlayerIndex,
    this.callCount = 0,
  });

  /// 初始状态
  factory GameState.initial() => const GameState(
        phase: GamePhase.waiting,
        players: [],
        currentPlayerIndex: 0,
        landlordCards: [],
      );

  /// 复制并修改
  GameState copyWith({
    GamePhase? phase,
    List<Player>? players,
    int? currentPlayerIndex,
    List<Card>? landlordCards,
    List<Card>? lastPlayedCards,
    int? lastPlayerIndex,
    int? landlordIndex,
    int? callingPlayerIndex,
    int? callCount,
    bool clearLastPlayedCards = false,
    bool clearLastPlayerIndex = false,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      landlordCards: landlordCards ?? this.landlordCards,
      lastPlayedCards: clearLastPlayedCards ? null : (lastPlayedCards ?? this.lastPlayedCards),
      lastPlayerIndex: clearLastPlayerIndex ? null : (lastPlayerIndex ?? this.lastPlayerIndex),
      landlordIndex: landlordIndex ?? this.landlordIndex,
      callingPlayerIndex: callingPlayerIndex ?? this.callingPlayerIndex,
      callCount: callCount ?? this.callCount,
    );
  }

  /// 获取当前玩家
  Player? get currentPlayer =>
      players.isNotEmpty && currentPlayerIndex < players.length
          ? players[currentPlayerIndex]
          : null;

  /// 获取地主
  Player? get landlord =>
      landlordIndex != null && landlordIndex! < players.length
          ? players[landlordIndex!]
          : null;
}
