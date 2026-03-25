import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';
import 'package:poke_game/domain/texas_holdem/entities/pot.dart';

/// 游戏阶段
enum GamePhase {
  /// 准备阶段
  waiting,

  /// 翻牌前（发底牌后，首轮投注）
  preflop,

  /// 翻牌（翻出3张公牌）
  flop,

  /// 转牌（翻出第4张公牌）
  turn,

  /// 河牌（翻出第5张公牌）
  river,

  /// 摊牌结算
  showdown,

  /// 局结束
  finished,
}

/// 德州扑克游戏状态
class HoldemGameState {
  final List<HoldemPlayer> players;
  final List<Card> communityCards;
  final List<Pot> pots;
  final GamePhase phase;

  /// 当前行动玩家的索引
  final int currentPlayerIndex;

  /// 庄家位置索引
  final int dealerIndex;

  /// 小盲注金额
  final int smallBlind;

  /// 大盲注金额
  final int bigBlind;

  /// 本轮最高投注额
  final int currentBet;

  /// 本轮最小加注增量
  final int minRaise;

  /// 底牌（洗好的牌堆）
  final List<Card> deck;

  /// 是否人机模式
  final bool isAiMode;

  /// 人类玩家 ID（人机模式下）
  final String? humanPlayerId;

  const HoldemGameState({
    required this.players,
    this.communityCards = const [],
    this.pots = const [],
    this.phase = GamePhase.waiting,
    this.currentPlayerIndex = 0,
    this.dealerIndex = 0,
    required this.smallBlind,
    required this.bigBlind,
    this.currentBet = 0,
    this.minRaise = 0,
    this.deck = const [],
    this.isAiMode = true,
    this.humanPlayerId,
  });

  /// 初始状态工厂
  factory HoldemGameState.initial({
    required List<HoldemPlayer> players,
    int smallBlind = 10,
    int bigBlind = 20,
    bool isAiMode = true,
    String? humanPlayerId,
  }) {
    return HoldemGameState(
      players: players,
      smallBlind: smallBlind,
      bigBlind: bigBlind,
      isAiMode: isAiMode,
      humanPlayerId: humanPlayerId,
      minRaise: bigBlind,
    );
  }

  /// 活跃玩家列表（未弃牌）
  List<HoldemPlayer> get activePlayers =>
      players.where((p) => p.isActive).toList();

  /// 可行动玩家列表（未弃牌且未 All-in）
  List<HoldemPlayer> get actablePlayers =>
      players.where((p) => p.canAct).toList();

  /// 所有底池总金额
  int get totalPot => pots.fold(0, (sum, p) => sum + p.amount);

  /// 当前行动玩家
  HoldemPlayer? get currentPlayer {
    if (currentPlayerIndex < 0 || currentPlayerIndex >= players.length) {
      return null;
    }
    return players[currentPlayerIndex];
  }

  /// 庄家玩家
  HoldemPlayer get dealer => players[dealerIndex];

  /// 小盲位索引
  int get smallBlindIndex => (dealerIndex + 1) % players.length;

  /// 大盲位索引
  int get bigBlindIndex => (dealerIndex + 2) % players.length;

  HoldemGameState copyWith({
    List<HoldemPlayer>? players,
    List<Card>? communityCards,
    List<Pot>? pots,
    GamePhase? phase,
    int? currentPlayerIndex,
    int? dealerIndex,
    int? smallBlind,
    int? bigBlind,
    int? currentBet,
    int? minRaise,
    List<Card>? deck,
    bool? isAiMode,
    String? humanPlayerId,
  }) {
    return HoldemGameState(
      players: players ?? this.players,
      communityCards: communityCards ?? this.communityCards,
      pots: pots ?? this.pots,
      phase: phase ?? this.phase,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      smallBlind: smallBlind ?? this.smallBlind,
      bigBlind: bigBlind ?? this.bigBlind,
      currentBet: currentBet ?? this.currentBet,
      minRaise: minRaise ?? this.minRaise,
      deck: deck ?? this.deck,
      isAiMode: isAiMode ?? this.isAiMode,
      humanPlayerId: humanPlayerId ?? this.humanPlayerId,
    );
  }

  @override
  String toString() =>
      'HoldemGameState(phase=$phase, players=${players.length}, pot=$totalPot)';

  /// 序列化为 JSON（用于网络传输）
  Map<String, dynamic> toJson() {
    return {
      'phase': phase.name,
      'currentPlayerIndex': currentPlayerIndex,
      'dealerIndex': dealerIndex,
      'smallBlind': smallBlind,
      'bigBlind': bigBlind,
      'currentBet': currentBet,
      'minRaise': minRaise,
      'isAiMode': isAiMode,
      'humanPlayerId': humanPlayerId,
      'players': players
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'chips': p.chips,
                'currentBet': p.currentBet,
                'isFolded': p.isFolded,
                'isAllIn': p.isAllIn,
                'holeCards': p.holeCards
                    .map((c) => {'suit': c.suit.name, 'rank': c.rank})
                    .toList(),
              })
          .toList(),
      'communityCards': communityCards
          .map((c) => {'suit': c.suit.name, 'rank': c.rank})
          .toList(),
      'pots': pots
          .map((p) => {
                'amount': p.amount,
                'eligiblePlayerIds': p.eligiblePlayerIds,
              })
          .toList(),
    };
  }

  /// 从 JSON 反序列化（用于网络接收）
  static HoldemGameState fromJson(
    Map<String, dynamic> json, {
    String? localPlayerId,
  }) {
    GamePhase parsePhase(String? name) {
      return GamePhase.values.firstWhere(
        (e) => e.name == name,
        orElse: () => GamePhase.waiting,
      );
    }

    Suit parseSuit(String? name) {
      return Suit.values.firstWhere(
        (e) => e.name == name,
        orElse: () => Suit.spade,
      );
    }

    Card parseCard(Map<String, dynamic> c) {
      return Card(
        suit: parseSuit(c['suit'] as String?),
        rank: (c['rank'] as num?)?.toInt() ?? 2,
      );
    }

    final playersJson = (json['players'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final players = playersJson.map((p) {
      final pid = p['id'] as String? ?? '';
      final isLocal = localPlayerId != null && pid == localPlayerId;
      final holeCardsJson = (p['holeCards'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      // 客户端只显示自己的手牌
      final holeCards = isLocal || localPlayerId == null
          ? holeCardsJson.map(parseCard).toList()
          : <Card>[];
      return HoldemPlayer(
        id: pid,
        name: p['name'] as String? ?? '',
        chips: (p['chips'] as num?)?.toInt() ?? 0,
        currentBet: (p['currentBet'] as num?)?.toInt() ?? 0,
        isFolded: p['isFolded'] as bool? ?? false,
        isAllIn: p['isAllIn'] as bool? ?? false,
        holeCards: holeCards,
      );
    }).toList();

    final communityJson = (json['communityCards'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final potsJson = (json['pots'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return HoldemGameState(
      players: players,
      communityCards: communityJson.map(parseCard).toList(),
      pots: potsJson
          .map((p) => Pot(
                amount: (p['amount'] as num?)?.toInt() ?? 0,
                eligiblePlayerIds: (p['eligiblePlayerIds'] as List?)
                        ?.cast<String>() ??
                    [],
              ))
          .toList(),
      phase: parsePhase(json['phase'] as String?),
      currentPlayerIndex: (json['currentPlayerIndex'] as num?)?.toInt() ?? 0,
      dealerIndex: (json['dealerIndex'] as num?)?.toInt() ?? 0,
      smallBlind: (json['smallBlind'] as num?)?.toInt() ?? 10,
      bigBlind: (json['bigBlind'] as num?)?.toInt() ?? 20,
      currentBet: (json['currentBet'] as num?)?.toInt() ?? 0,
      minRaise: (json['minRaise'] as num?)?.toInt() ?? 20,
      isAiMode: json['isAiMode'] as bool? ?? false,
      humanPlayerId: json['humanPlayerId'] as String?,
    );
  }
}

/// 创建德州扑克标准牌组（52张，无王，rank 2-14）
List<Card> createHoldemDeck() {
  final deck = <Card>[];
  for (final suit in Suit.values) {
    // rank 2-14: 2=2, 3-10=3-10, 11=J, 12=Q, 13=K, 14=A
    for (var rank = 2; rank <= 14; rank++) {
      deck.add(Card(suit: suit, rank: rank));
    }
  }
  return deck;
}
