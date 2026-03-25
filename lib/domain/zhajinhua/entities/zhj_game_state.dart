import 'package:poke_game/domain/zhajinhua/entities/zhj_card.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';

/// 炸金花游戏阶段
enum ZhjGamePhase {
  /// 等待开始
  waiting,

  /// 发牌中
  dealing,

  /// 下注轮
  betting,

  /// 结算
  settlement,

  /// 游戏结束
  finished,
}

/// 炸金花游戏状态（手动 copyWith，不使用 freezed 避免代码生成依赖）
class ZhjGameState {
  final ZhjGamePhase phase;
  final List<ZhjPlayer> players;

  /// 底池
  final int pot;

  /// 当前底注（可被加注翻倍）
  final int currentBet;

  /// 当前操作玩家索引
  final int currentPlayerIndex;

  /// 胜者玩家ID（null表示游戏未结束）
  final String? winnerId;

  /// 错误消息（用于UI提示）
  final String? message;

  const ZhjGameState({
    required this.phase,
    required this.players,
    required this.pot,
    required this.currentBet,
    required this.currentPlayerIndex,
    this.winnerId,
    this.message,
  });

  factory ZhjGameState.initial() => const ZhjGameState(
        phase: ZhjGamePhase.waiting,
        players: [],
        pot: 0,
        currentBet: 10,
        currentPlayerIndex: 0,
      );

  /// 存活玩家列表
  List<ZhjPlayer> get alivePlayers =>
      players.where((p) => p.isAlive).toList();

  /// 当前操作玩家
  ZhjPlayer get currentPlayer => players[currentPlayerIndex];

  /// 是否只剩一名玩家存活
  bool get hasOnlyOnePlayerAlive => alivePlayers.length == 1;

  ZhjGameState copyWith({
    ZhjGamePhase? phase,
    List<ZhjPlayer>? players,
    int? pot,
    int? currentBet,
    int? currentPlayerIndex,
    String? winnerId,
    String? message,
    bool clearWinner = false,
    bool clearMessage = false,
  }) {
    return ZhjGameState(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      pot: pot ?? this.pot,
      currentBet: currentBet ?? this.currentBet,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      winnerId: clearWinner ? null : (winnerId ?? this.winnerId),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  /// 序列化为 JSON（用于网络传输）
  /// [includeAllCards] = true 时包含全量手牌（Host 广播用），否则仅包含本地玩家手牌
  Map<String, dynamic> toJson({bool includeAllCards = false}) {
    return {
      'phase': phase.name,
      'pot': pot,
      'currentBet': currentBet,
      'currentPlayerIndex': currentPlayerIndex,
      'winnerId': winnerId,
      'players': players
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'isAi': p.isAi,
                'chips': p.chips,
                'hasPeeked': p.hasPeeked,
                'isFolded': p.isFolded,
                'betAmount': p.betAmount,
                // 手牌：仅 includeAllCards 时广播全量（Host 用）
                'cards': includeAllCards
                    ? p.cards
                        .map((c) => {'suit': c.suit.name, 'rank': c.rank})
                        .toList()
                    : null,
              })
          .toList(),
    };
  }

  /// 从 JSON 反序列化（用于网络接收）
  /// [localPlayerId] 指定本地玩家 ID，其他玩家手牌置空
  static ZhjGameState fromJson(
    Map<String, dynamic> json, {
    String? localPlayerId,
  }) {
    ZhjGamePhase parsePhase(String? name) {
      return ZhjGamePhase.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ZhjGamePhase.waiting,
      );
    }

    ZhjSuit parseSuit(String? name) {
      return ZhjSuit.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ZhjSuit.spade,
      );
    }

    final playersJson =
        (json['players'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final players = playersJson.map((p) {
      final pid = p['id'] as String? ?? '';
      final isLocal = localPlayerId != null && pid == localPlayerId;
      final cardsJson =
          (p['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      // 客户端仅保留自己的手牌
      final cards = (isLocal || localPlayerId == null) && cardsJson.isNotEmpty
          ? cardsJson
              .map((c) => ZhjCard(
                    suit: parseSuit(c['suit'] as String?),
                    rank: (c['rank'] as num?)?.toInt() ?? 3,
                  ))
              .toList()
          : <ZhjCard>[];

      return ZhjPlayer(
        id: pid,
        name: p['name'] as String? ?? '',
        isAi: p['isAi'] as bool? ?? false,
        chips: (p['chips'] as num?)?.toInt() ?? 0,
        hasPeeked: p['hasPeeked'] as bool? ?? false,
        isFolded: p['isFolded'] as bool? ?? false,
        betAmount: (p['betAmount'] as num?)?.toInt() ?? 0,
        cards: cards,
      );
    }).toList();

    return ZhjGameState(
      phase: parsePhase(json['phase'] as String?),
      players: players,
      pot: (json['pot'] as num?)?.toInt() ?? 0,
      currentBet: (json['currentBet'] as num?)?.toInt() ?? 10,
      currentPlayerIndex: (json['currentPlayerIndex'] as num?)?.toInt() ?? 0,
      winnerId: json['winnerId'] as String?,
    );
  }
}
