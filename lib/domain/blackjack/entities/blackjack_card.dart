import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 21点复用斗地主的 Suit 枚举（spade/heart/club/diamond）
typedef BlackjackSuit = Suit;

/// 21点牌面
/// rank: 1=A, 2-10=数字, 11=J, 12=Q, 13=K
class BlackjackCard {
  final BlackjackSuit suit;

  /// 牌面点数 1–13（1=A, 11=J, 12=Q, 13=K）
  final int rank;

  const BlackjackCard({required this.suit, required this.rank});

  /// 显示文字
  String get displayText {
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return rank.toString();
    }
  }

  String get suitSymbol {
    switch (suit) {
      case BlackjackSuit.spade:
        return '♠';
      case BlackjackSuit.heart:
        return '♥';
      case BlackjackSuit.club:
        return '♣';
      case BlackjackSuit.diamond:
        return '♦';
    }
  }

  bool get isRed => suit == BlackjackSuit.heart || suit == BlackjackSuit.diamond;

  /// 是否为 A
  bool get isAce => rank == 1;

  @override
  String toString() => '$suitSymbol$displayText';

  @override
  bool operator ==(Object other) =>
      other is BlackjackCard && suit == other.suit && rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  Map<String, dynamic> toJson() => {'suit': suit.name, 'rank': rank};

  static BlackjackCard fromJson(Map<String, dynamic> json) {
    final suitName = json['suit'] as String? ?? 'spade';
    final suit = BlackjackSuit.values.firstWhere(
      (e) => e.name == suitName,
      orElse: () => BlackjackSuit.spade,
    );
    return BlackjackCard(
      suit: suit,
      rank: (json['rank'] as num?)?.toInt() ?? 1,
    );
  }

  /// 生成标准52张牌（A=1, 2-K=2-13）
  static List<BlackjackCard> standardDeck() {
    final deck = <BlackjackCard>[];
    for (final suit in BlackjackSuit.values) {
      for (int rank = 1; rank <= 13; rank++) {
        deck.add(BlackjackCard(suit: suit, rank: rank));
      }
    }
    return deck;
  }
}
