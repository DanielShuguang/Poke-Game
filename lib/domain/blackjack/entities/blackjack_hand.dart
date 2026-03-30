import 'package:poke_game/domain/blackjack/entities/blackjack_card.dart';

/// 单手牌的行动状态
enum BlackjackHandStatus {
  /// 等待行动
  active,

  /// 已停牌
  stood,

  /// 已爆牌
  bust,

  /// 已投降
  surrendered,

  /// 五小龙（5张牌不超21点）
  fiveCardCharlie,

  /// Blackjack（首两张A+10点牌）
  blackjack,
}

/// 一手牌（21点中 Split 后可有多手）
class BlackjackHand {
  final List<BlackjackCard> cards;
  final BlackjackHandStatus status;

  /// 本手牌的下注额（Double 后翻倍）
  final int bet;

  const BlackjackHand({
    required this.cards,
    this.status = BlackjackHandStatus.active,
    required this.bet,
  });

  /// 计算最优点数（A 自动 1 或 11）
  int get value {
    int total = 0;
    int aces = 0;
    for (final card in cards) {
      if (card.isAce) {
        aces++;
        total += 11;
      } else if (card.rank >= 10) {
        total += 10;
      } else {
        total += card.rank;
      }
    }
    // 超过21时将 A 从11降为1
    while (total > 21 && aces > 0) {
      total -= 10;
      aces--;
    }
    return total;
  }

  /// 是否超过 21（爆牌）
  bool get isBust => value > 21;

  /// 是否是 Blackjack（首两张牌且点数为21）
  bool get isBlackjack =>
      cards.length == 2 && value == 21;

  /// 是否是 Soft hand（含 A 计为11的手牌）
  bool get isSoft {
    int total = 0;
    int aces = 0;
    for (final card in cards) {
      if (card.isAce) {
        aces++;
        total += 11;
      } else if (card.rank >= 10) {
        total += 10;
      } else {
        total += card.rank;
      }
    }
    // 检查是否有 A 在以11计的状态下不爆
    return aces > 0 && total <= 21;
  }

  /// 是否可以 Split（两张同点值牌）
  bool get canSplit =>
      cards.length == 2 &&
      _pointValue(cards[0]) == _pointValue(cards[1]);

  int _pointValue(BlackjackCard card) {
    if (card.rank >= 10) return 10;
    return card.rank;
  }

  /// 是否已完成行动（不再需要操作）
  bool get isDone =>
      status == BlackjackHandStatus.stood ||
      status == BlackjackHandStatus.bust ||
      status == BlackjackHandStatus.surrendered ||
      status == BlackjackHandStatus.fiveCardCharlie ||
      status == BlackjackHandStatus.blackjack;

  BlackjackHand copyWith({
    List<BlackjackCard>? cards,
    BlackjackHandStatus? status,
    int? bet,
  }) {
    return BlackjackHand(
      cards: cards ?? List.of(this.cards),
      status: status ?? this.status,
      bet: bet ?? this.bet,
    );
  }

  Map<String, dynamic> toJson() => {
        'cards': cards.map((c) => c.toJson()).toList(),
        'status': status.name,
        'bet': bet,
      };

  static BlackjackHand fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'active';
    final status = BlackjackHandStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => BlackjackHandStatus.active,
    );
    final cardsJson =
        (json['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return BlackjackHand(
      cards: cardsJson.map(BlackjackCard.fromJson).toList(),
      status: status,
      bet: (json['bet'] as num?)?.toInt() ?? 0,
    );
  }
}
