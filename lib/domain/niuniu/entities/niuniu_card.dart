import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 斗牛复用斗地主的 Suit 枚举（spade/heart/club/diamond）
typedef NiuniuSuit = Suit;

/// 斗牛牌面
/// rank: 1=A, 2-10=数字, 11=J, 12=Q, 13=K
class NiuniuCard {
  final NiuniuSuit suit;

  /// 牌面点数 1–13
  final int rank;

  const NiuniuCard({required this.suit, required this.rank});

  /// 斗牛计算点值：J/Q/K/10 均为 10，其余为 rank
  int get pointValue {
    if (rank >= 10) return 10;
    return rank;
  }

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
      case NiuniuSuit.spade:
        return '♠';
      case NiuniuSuit.heart:
        return '♥';
      case NiuniuSuit.club:
        return '♣';
      case NiuniuSuit.diamond:
        return '♦';
    }
  }

  bool get isRed => suit == NiuniuSuit.heart || suit == NiuniuSuit.diamond;

  @override
  String toString() => '$suitSymbol$displayText';

  @override
  bool operator ==(Object other) =>
      other is NiuniuCard && suit == other.suit && rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  Map<String, dynamic> toJson() => {'suit': suit.name, 'rank': rank};

  static NiuniuCard fromJson(Map<String, dynamic> json) {
    final suitName = json['suit'] as String? ?? 'spade';
    final suit = NiuniuSuit.values.firstWhere(
      (e) => e.name == suitName,
      orElse: () => NiuniuSuit.spade,
    );
    return NiuniuCard(suit: suit, rank: (json['rank'] as num?)?.toInt() ?? 1);
  }

  /// 生成标准 52 张牌
  static List<NiuniuCard> standardDeck() {
    final deck = <NiuniuCard>[];
    for (final suit in NiuniuSuit.values) {
      for (int rank = 1; rank <= 13; rank++) {
        deck.add(NiuniuCard(suit: suit, rank: rank));
      }
    }
    return deck;
  }
}
