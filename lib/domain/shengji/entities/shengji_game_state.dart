import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_player.dart';
import 'package:poke_game/domain/shengji/entities/shengji_team.dart';
import 'package:poke_game/domain/shengji/entities/trump_info.dart';

/// 升级游戏阶段
enum ShengjiPhase {
  /// 等待玩家
  waiting,

  /// 发牌中
  dealing,

  /// 叫牌阶段
  calling,

  /// 出牌阶段
  playing,

  /// 结算
  settling,

  /// 游戏结束
  finished,
}

/// 出牌轮次记录
class PlayRound {
  /// 首出玩家座位索引
  final int leadSeatIndex;

  /// 首出的牌
  final List<ShengjiCard> leadCards;

  /// 所有玩家的出牌（座位索引 -> 牌）
  final Map<int, List<ShengjiCard>> plays;

  /// 赢家座位索引（null 表示未结束）
  final int? winnerSeatIndex;

  const PlayRound({
    required this.leadSeatIndex,
    required this.leadCards,
    this.plays = const {},
    this.winnerSeatIndex,
  });

  /// 是否所有人都已出牌
  bool get isComplete => plays.length == 4 && winnerSeatIndex != null;

  /// 复制并修改
  PlayRound copyWith({
    int? leadSeatIndex,
    List<ShengjiCard>? leadCards,
    Map<int, List<ShengjiCard>>? plays,
    int? winnerSeatIndex,
  }) {
    return PlayRound(
      leadSeatIndex: leadSeatIndex ?? this.leadSeatIndex,
      leadCards: leadCards ?? this.leadCards,
      plays: plays ?? this.plays,
      winnerSeatIndex: winnerSeatIndex ?? this.winnerSeatIndex,
    );
  }

  /// 计算本轮得分
  int getRoundScore() {
    int score = 0;
    for (final cards in plays.values) {
      for (final card in cards) {
        if (card.rank == 5) score += 5;
        if (card.rank == 10) score += 10;
        if (card.rank == 13) score += 10; // K = 10分
      }
    }
    return score;
  }
}

/// 升级游戏状态
class ShengjiGameState {
  /// 游戏阶段
  final ShengjiPhase phase;

  /// 玩家列表（按座位索引排序）
  final List<ShengjiPlayer> players;

  /// 队伍列表（2个队伍）
  final List<ShengjiTeam> teams;

  /// 将牌信息（null 表示未确定）
  final TrumpInfo? trumpInfo;

  /// 庄家玩家 ID
  final String? dealerId;

  /// 当前操作玩家座位索引
  final int currentSeatIndex;

  /// 底牌（8张，发牌后给庄家）
  final List<ShengjiCard> bottomCards;

  /// 当前出牌轮
  final PlayRound? currentRound;

  /// 已完成的出牌轮
  final List<PlayRound> completedRounds;

  /// 叫牌历史（玩家ID -> 叫牌内容）
  final Map<String, String> callHistory;

  /// 消息提示
  final String? message;

  const ShengjiGameState({
    this.phase = ShengjiPhase.waiting,
    this.players = const [],
    this.teams = const [],
    this.trumpInfo,
    this.dealerId,
    this.currentSeatIndex = 0,
    this.bottomCards = const [],
    this.currentRound,
    this.completedRounds = const [],
    this.callHistory = const {},
    this.message,
  });

  /// 获取庄家
  ShengjiPlayer? get dealer =>
      players.where((p) => p.id == dealerId).firstOrNull;

  /// 获取庄家队
  ShengjiTeam? get dealerTeam {
    final d = dealer;
    if (d == null) return null;
    return teams.where((t) => t.id == d.teamId).firstOrNull;
  }

  /// 获取防守队
  ShengjiTeam? get opponentTeam {
    final dt = dealerTeam;
    if (dt == null) return null;
    return teams.where((t) => t.id != dt.id).firstOrNull;
  }

  /// 获取当前操作玩家
  ShengjiPlayer? get currentPlayer {
    if (currentSeatIndex < 0 || currentSeatIndex >= players.length) return null;
    return players.where((p) => p.seatIndex == currentSeatIndex).firstOrNull;
  }

  /// 根据座位索引获取玩家
  ShengjiPlayer? getPlayerBySeat(int seatIndex) {
    return players.where((p) => p.seatIndex == seatIndex).firstOrNull;
  }

  /// 根据玩家 ID 获取队伍
  ShengjiTeam? getTeamByPlayerId(String playerId) {
    final player = players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) return null;
    return teams.where((t) => t.id == player.teamId).firstOrNull;
  }

  /// 复制并修改
  ShengjiGameState copyWith({
    ShengjiPhase? phase,
    List<ShengjiPlayer>? players,
    List<ShengjiTeam>? teams,
    TrumpInfo? trumpInfo,
    String? dealerId,
    int? currentSeatIndex,
    List<ShengjiCard>? bottomCards,
    PlayRound? currentRound,
    List<PlayRound>? completedRounds,
    Map<String, String>? callHistory,
    String? message,
    bool clearTrumpInfo = false,
    bool clearDealerId = false,
    bool clearCurrentRound = false,
    bool clearMessage = false,
  }) {
    return ShengjiGameState(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      teams: teams ?? this.teams,
      trumpInfo: clearTrumpInfo ? null : (trumpInfo ?? this.trumpInfo),
      dealerId: clearDealerId ? null : (dealerId ?? this.dealerId),
      currentSeatIndex: currentSeatIndex ?? this.currentSeatIndex,
      bottomCards: bottomCards ?? this.bottomCards,
      currentRound: clearCurrentRound ? null : (currentRound ?? this.currentRound),
      completedRounds: completedRounds ?? this.completedRounds,
      callHistory: callHistory ?? this.callHistory,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson({bool includeAllCards = true, String? localPlayerId}) {
    return {
      'phase': phase.name,
      'players': players
          .map((p) => p.toJson(
                includeHand: includeAllCards || p.id == localPlayerId,
              ))
          .toList(),
      'teams': teams.map((t) => t.toJson()).toList(),
      'trumpInfo': trumpInfo?.toJson(),
      'dealerId': dealerId,
      'currentSeatIndex': currentSeatIndex,
      'bottomCards': includeAllCards
          ? bottomCards.map((c) => c.toJson()).toList()
          : [],
      'currentRound': currentRound != null
          ? {
              'leadSeatIndex': currentRound!.leadSeatIndex,
              'leadCards': currentRound!.leadCards.map((c) => c.toJson()).toList(),
              'plays': currentRound!.plays.map(
                (key, value) => MapEntry(key.toString(), value.map((c) => c.toJson()).toList()),
              ),
              'winnerSeatIndex': currentRound!.winnerSeatIndex,
            }
          : null,
      'completedRounds': completedRounds
          .map((r) => {
                'leadSeatIndex': r.leadSeatIndex,
                'leadCards': r.leadCards.map((c) => c.toJson()).toList(),
                'plays': r.plays.map(
                  (key, value) => MapEntry(key.toString(), value.map((c) => c.toJson()).toList()),
                ),
                'winnerSeatIndex': r.winnerSeatIndex,
              })
          .toList(),
      'callHistory': callHistory,
      'message': message,
    };
  }

  /// 从 JSON 反序列化
  static ShengjiGameState fromJson(Map<String, dynamic> json, {String? localPlayerId}) {
    return ShengjiGameState(
      phase: ShengjiPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => ShengjiPhase.waiting,
      ),
      players: (json['players'] as List<dynamic>?)
          ?.map((p) {
            final pm = p as Map<String, dynamic>;
            return ShengjiPlayer.fromJson(
              pm,
              loadHand: localPlayerId == null || pm['id'] == localPlayerId,
            );
          })
          .toList() ?? [],
      teams: (json['teams'] as List<dynamic>?)
          ?.map((t) => ShengjiTeam.fromJson(t as Map<String, dynamic>))
          .toList() ?? [],
      trumpInfo: json['trumpInfo'] != null
          ? TrumpInfo.fromJson(json['trumpInfo'] as Map<String, dynamic>)
          : null,
      dealerId: json['dealerId'] as String?,
      currentSeatIndex: json['currentSeatIndex'] as int? ?? 0,
      bottomCards: (json['bottomCards'] as List<dynamic>?)
          ?.map((c) => ShengjiCard.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      currentRound: json['currentRound'] != null
          ? _parsePlayRound(json['currentRound'] as Map<String, dynamic>)
          : null,
      completedRounds: (json['completedRounds'] as List<dynamic>?)
          ?.map((r) => _parsePlayRound(r as Map<String, dynamic>))
          .toList() ?? [],
      callHistory: Map<String, String>.from(json['callHistory'] as Map? ?? {}),
      message: json['message'] as String?,
    );
  }

  static PlayRound _parsePlayRound(Map<String, dynamic> json) {
    final playsMap = <int, List<ShengjiCard>>{};
    final plays = json['plays'] as Map<String, dynamic>?;
    if (plays != null) {
      plays.forEach((key, value) {
        final seatIndex = int.parse(key);
        final cards = (value as List<dynamic>)
            .map((c) => ShengjiCard.fromJson(c as Map<String, dynamic>))
            .toList();
        playsMap[seatIndex] = cards;
      });
    }
    return PlayRound(
      leadSeatIndex: json['leadSeatIndex'] as int? ?? 0,
      leadCards: (json['leadCards'] as List<dynamic>?)
          ?.map((c) => ShengjiCard.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      plays: playsMap,
      winnerSeatIndex: json['winnerSeatIndex'] as int?,
    );
  }

  @override
  String toString() => 'ShengjiGameState(${phase.name}, ${players.length}人)';
}
