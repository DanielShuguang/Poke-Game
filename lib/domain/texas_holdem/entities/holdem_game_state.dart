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
