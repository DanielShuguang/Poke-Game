import 'guandan_card.dart';
import 'guandan_hand.dart';
import 'guandan_player.dart';

/// 游戏阶段
enum GuandanPhase {
  /// 等待开始
  waiting,

  /// 发牌
  dealing,

  /// 贡牌阶段（输方进贡最大牌）
  tribute,

  /// 还贡阶段（赢方返还一张牌）
  returnTribute,

  /// 出牌阶段
  playing,

  /// 结算
  settling,

  /// 游戏结束（某队升到 A 后再次满足升级条件）
  finished,
}

/// 贡牌状态
class TributeState {
  /// 需要进贡的玩家 ID → 应进贡给的赢家玩家 ID
  final Map<String, String> pendingTributes;

  /// 需要还贡的玩家 ID → 应还贡给的输家玩家 ID
  final Map<String, String> pendingReturnTributes;

  /// 已完成的贡牌映射：进贡玩家 ID → 贡出的牌
  final Map<String, GuandanCard> completedTributes;

  /// 已完成的还贡映射：还贡玩家 ID → 还贡的牌
  final Map<String, GuandanCard> completedReturnTributes;

  const TributeState({
    this.pendingTributes = const {},
    this.pendingReturnTributes = const {},
    this.completedTributes = const {},
    this.completedReturnTributes = const {},
  });

  bool get allTributesComplete =>
      pendingTributes.isEmpty && pendingReturnTributes.isEmpty;

  TributeState copyWith({
    Map<String, String>? pendingTributes,
    Map<String, String>? pendingReturnTributes,
    Map<String, GuandanCard>? completedTributes,
    Map<String, GuandanCard>? completedReturnTributes,
  }) {
    return TributeState(
      pendingTributes: pendingTributes ?? this.pendingTributes,
      pendingReturnTributes:
          pendingReturnTributes ?? this.pendingReturnTributes,
      completedTributes: completedTributes ?? this.completedTributes,
      completedReturnTributes:
          completedReturnTributes ?? this.completedReturnTributes,
    );
  }

  Map<String, dynamic> toJson() => {
        'pendingTributes': pendingTributes,
        'pendingReturnTributes': pendingReturnTributes,
        'completedTributes': completedTributes
            .map((k, v) => MapEntry(k, v.toId())),
        'completedReturnTributes': completedReturnTributes
            .map((k, v) => MapEntry(k, v.toId())),
      };

  static TributeState fromJson(Map<String, dynamic> json) {
    Map<String, GuandanCard> parseCards(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, GuandanCard.fromId(v as String)));
    }

    Map<String, String> parseStrMap(dynamic raw) {
      if (raw == null) return {};
      return Map<String, String>.from(raw as Map);
    }

    return TributeState(
      pendingTributes: parseStrMap(json['pendingTributes']),
      pendingReturnTributes: parseStrMap(json['pendingReturnTributes']),
      completedTributes: parseCards(json['completedTributes']),
      completedReturnTributes: parseCards(json['completedReturnTributes']),
    );
  }
}

/// 局结算结果
class RoundResult {
  /// 升级队伍 ID（0 或 1；null 表示平局/不升级方）
  final int? winnerTeamId;

  /// 升降级档数（正数升级，负数降级）
  final int team0LevelDelta;
  final int team1LevelDelta;

  /// 头游/二游/三游/四游玩家 ID
  final List<String> finishOrder;

  const RoundResult({
    this.winnerTeamId,
    required this.team0LevelDelta,
    required this.team1LevelDelta,
    required this.finishOrder,
  });

  Map<String, dynamic> toJson() => {
        'winnerTeamId': winnerTeamId,
        'team0LevelDelta': team0LevelDelta,
        'team1LevelDelta': team1LevelDelta,
        'finishOrder': finishOrder,
      };

  static RoundResult fromJson(Map<String, dynamic> json) => RoundResult(
        winnerTeamId: json['winnerTeamId'] as int?,
        team0LevelDelta: json['team0LevelDelta'] as int,
        team1LevelDelta: json['team1LevelDelta'] as int,
        finishOrder: List<String>.from(json['finishOrder'] as List),
      );
}

/// 掼蛋游戏完整状态
class GuandanGameState {
  final GuandanPhase phase;

  /// 4名玩家，按座位索引 0-3 排列
  final List<GuandanPlayer> players;

  /// 队伍0的当前级牌（2-14），14=A
  final int team0Level;

  /// 队伍1的当前级牌（2-14），14=A
  final int team1Level;

  /// 当前出牌玩家的座位索引
  final int currentPlayerIndex;

  /// 场上最后一手牌（null 表示本轮首出）
  final GuandanHand? lastPlayedHand;

  /// 场上最后一手牌的出牌玩家座位索引
  final int? lastPlayerIndex;

  /// 贡牌状态（仅贡牌/还贡阶段有效）
  final TributeState? tributeState;

  /// 本局结算结果（settling/finished 阶段有效）
  final RoundResult? roundResult;

  /// 上一局赢方的首出玩家座位（下一局先手）
  final int? nextLeadSeatIndex;

  const GuandanGameState({
    required this.phase,
    required this.players,
    this.team0Level = 2,
    this.team1Level = 2,
    required this.currentPlayerIndex,
    this.lastPlayedHand,
    this.lastPlayerIndex,
    this.tributeState,
    this.roundResult,
    this.nextLeadSeatIndex,
  });

  // ────────────────────────────────────────────────────────────────
  // 便利 Getter
  // ────────────────────────────────────────────────────────────────

  GuandanPlayer get currentPlayer => players[currentPlayerIndex];

  GuandanPlayer? getPlayerById(String id) {
    try {
      return players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<GuandanPlayer> get team0Players =>
      players.where((p) => p.teamId == 0).toList();

  List<GuandanPlayer> get team1Players =>
      players.where((p) => p.teamId == 1).toList();

  int levelForTeam(int teamId) => teamId == 0 ? team0Level : team1Level;

  /// 根据座位索引，当前玩家所在队的级牌
  int get currentLevel =>
      players.isEmpty ? team0Level : levelForTeam(currentPlayer.teamId);

  bool get isRoundOver =>
      players.where((p) => p.hasFinished).length >= 3;

  // ────────────────────────────────────────────────────────────────
  // copyWith
  // ────────────────────────────────────────────────────────────────

  GuandanGameState copyWith({
    GuandanPhase? phase,
    List<GuandanPlayer>? players,
    int? team0Level,
    int? team1Level,
    int? currentPlayerIndex,
    GuandanHand? lastPlayedHand,
    int? lastPlayerIndex,
    TributeState? tributeState,
    RoundResult? roundResult,
    int? nextLeadSeatIndex,
    bool clearLastPlayedHand = false,
    bool clearLastPlayerIndex = false,
    bool clearTributeState = false,
    bool clearRoundResult = false,
    bool clearNextLeadSeatIndex = false,
  }) {
    return GuandanGameState(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      team0Level: team0Level ?? this.team0Level,
      team1Level: team1Level ?? this.team1Level,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      lastPlayedHand: clearLastPlayedHand
          ? null
          : (lastPlayedHand ?? this.lastPlayedHand),
      lastPlayerIndex: clearLastPlayerIndex
          ? null
          : (lastPlayerIndex ?? this.lastPlayerIndex),
      tributeState: clearTributeState
          ? null
          : (tributeState ?? this.tributeState),
      roundResult: clearRoundResult
          ? null
          : (roundResult ?? this.roundResult),
      nextLeadSeatIndex: clearNextLeadSeatIndex
          ? null
          : (nextLeadSeatIndex ?? this.nextLeadSeatIndex),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // JSON 序列化
  // ────────────────────────────────────────────────────────────────

  /// [includeAllCards] = false 时，仅本地玩家的手牌可见（用于网络广播）
  /// [localPlayerId] 指定本地玩家 ID
  Map<String, dynamic> toJson({
    bool includeAllCards = true,
    String? localPlayerId,
  }) {
    return {
      'phase': phase.name,
      'players': players.map((p) {
        final showCards = includeAllCards || p.id == localPlayerId;
        return p.toJson(includeCards: showCards);
      }).toList(),
      'team0Level': team0Level,
      'team1Level': team1Level,
      'currentPlayerIndex': currentPlayerIndex,
      'lastPlayedHand': lastPlayedHand?.toJson(),
      'lastPlayerIndex': lastPlayerIndex,
      'tributeState': tributeState?.toJson(),
      'roundResult': roundResult?.toJson(),
      'nextLeadSeatIndex': nextLeadSeatIndex,
    };
  }

  static GuandanGameState fromJson(
    Map<String, dynamic> json, {
    String? localPlayerId,
  }) {
    return GuandanGameState(
      phase: GuandanPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => GuandanPhase.waiting,
      ),
      players: (json['players'] as List<dynamic>)
          .map((p) => GuandanPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      team0Level: json['team0Level'] as int? ?? 2,
      team1Level: json['team1Level'] as int? ?? 2,
      currentPlayerIndex: json['currentPlayerIndex'] as int? ?? 0,
      lastPlayedHand: json['lastPlayedHand'] == null
          ? null
          : GuandanHand.fromJson(
              json['lastPlayedHand'] as Map<String, dynamic>),
      lastPlayerIndex: json['lastPlayerIndex'] as int?,
      tributeState: json['tributeState'] == null
          ? null
          : TributeState.fromJson(
              json['tributeState'] as Map<String, dynamic>),
      roundResult: json['roundResult'] == null
          ? null
          : RoundResult.fromJson(
              json['roundResult'] as Map<String, dynamic>),
      nextLeadSeatIndex: json['nextLeadSeatIndex'] as int?,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 初始状态工厂
  // ────────────────────────────────────────────────────────────────

  static GuandanGameState initial() {
    return const GuandanGameState(
      phase: GuandanPhase.waiting,
      players: [],
      currentPlayerIndex: 0,
    );
  }
}
