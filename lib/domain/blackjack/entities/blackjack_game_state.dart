import 'package:poke_game/domain/blackjack/entities/blackjack_card.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_player.dart';

/// 21点游戏阶段
enum BlackjackPhase {
  /// 等待下注
  betting,

  /// 发牌中
  dealing,

  /// 玩家行动阶段
  playerTurn,

  /// 庄家行动阶段
  dealerTurn,

  /// 结算阶段
  settlement,
}

/// 21点游戏全局状态
class BlackjackGameState {
  /// 当前牌堆（剩余牌）
  final List<BlackjackCard> deck;

  /// 庄家（index 0 的 hand 为明牌，index 1 为暗牌）
  final BlackjackPlayer dealer;

  /// 玩家列表（不含庄家）
  final List<BlackjackPlayer> players;

  /// 当前行动玩家在 players 中的索引
  final int currentPlayerIndex;

  /// 游戏阶段
  final BlackjackPhase phase;

  /// 提示消息（UI 用）
  final String? message;

  const BlackjackGameState({
    required this.deck,
    required this.dealer,
    required this.players,
    this.currentPlayerIndex = 0,
    required this.phase,
    this.message,
  });

  factory BlackjackGameState.initial() => BlackjackGameState(
        deck: const [],
        dealer: const BlackjackPlayer(
          id: 'dealer',
          name: '庄家',
          isAi: true,
          isDealer: true,
          chips: 0,
        ),
        players: const [],
        phase: BlackjackPhase.betting,
      );

  /// 当前行动玩家（null 表示庄家阶段或无玩家）
  BlackjackPlayer? get currentPlayer =>
      players.isNotEmpty && currentPlayerIndex < players.length
          ? players[currentPlayerIndex]
          : null;

  BlackjackGameState copyWith({
    List<BlackjackCard>? deck,
    BlackjackPlayer? dealer,
    List<BlackjackPlayer>? players,
    int? currentPlayerIndex,
    BlackjackPhase? phase,
    String? message,
    bool clearMessage = false,
  }) {
    return BlackjackGameState(
      deck: deck ?? List.of(this.deck),
      dealer: dealer ?? this.dealer,
      players: players ?? List.of(this.players),
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  /// 序列化为 JSON
  /// [includeAllCards] = true：包含庄家暗牌和所有玩家手牌（Host 广播用）
  /// [localPlayerId]：仅用于 fromJson，此处无效
  Map<String, dynamic> toJson({bool includeAllCards = false}) {
    return {
      'phase': phase.name,
      'currentPlayerIndex': currentPlayerIndex,
      'message': message,
      // 庄家：隐藏暗牌时将第二张手牌置 null
      'dealer': _dealerToJson(includeAllCards: includeAllCards),
      'players': players.map((p) => p.toJson(includeCards: includeAllCards)).toList(),
      // 牌堆不传输（节省带宽，Host 独立维护）
    };
  }

  Map<String, dynamic> _dealerToJson({required bool includeAllCards}) {
    final dealerHands = dealer.hands;
    if (dealerHands.isEmpty) {
      return dealer.toJson(includeCards: true);
    }
    if (includeAllCards || phase == BlackjackPhase.dealerTurn || phase == BlackjackPhase.settlement) {
      return dealer.toJson(includeCards: true);
    }
    // 玩家行动阶段：隐藏庄家第二张牌（暗牌）
    final firstHand = dealerHands[0];
    final visibleCards = firstHand.cards.length > 1
        ? [firstHand.cards[0]] // 仅显示第一张
        : firstHand.cards;
    final maskedHand = firstHand.copyWith(cards: visibleCards);
    final maskedDealer = dealer.copyWith(hands: [maskedHand]);
    return maskedDealer.toJson(includeCards: true);
  }

  /// 从 JSON 反序列化
  /// [localPlayerId] 指定本地玩家 ID，其余玩家手牌置空
  static BlackjackGameState fromJson(
    Map<String, dynamic> json, {
    String? localPlayerId,
  }) {
    BlackjackPhase parsePhase(String? name) {
      return BlackjackPhase.values.firstWhere(
        (e) => e.name == name,
        orElse: () => BlackjackPhase.betting,
      );
    }

    final dealerJson = json['dealer'] as Map<String, dynamic>? ?? {};
    final dealer = BlackjackPlayer.fromJson(dealerJson);

    final playersJson =
        (json['players'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final players = playersJson.map((pJson) {
      final player = BlackjackPlayer.fromJson(pJson);
      // 非本地玩家：清除手牌内容（手牌数量和状态保留用于 UI 显示）
      if (localPlayerId != null && player.id != localPlayerId) {
        final maskedHands = player.hands
            .map((h) => BlackjackHand(
                  cards: const [],
                  status: h.status,
                  bet: h.bet,
                ))
            .toList();
        return player.copyWith(hands: maskedHands);
      }
      return player;
    }).toList();

    return BlackjackGameState(
      deck: const [], // 客户端不维护牌堆
      dealer: dealer,
      players: players,
      currentPlayerIndex: (json['currentPlayerIndex'] as num?)?.toInt() ?? 0,
      phase: parsePhase(json['phase'] as String?),
      message: json['message'] as String?,
    );
  }
}
