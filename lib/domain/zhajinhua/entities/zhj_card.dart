import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 炸金花使用标准52张牌（无大小王），复用斗地主的 Suit 枚举
/// rank: 3-14 (3-10为数字, 11=J, 12=Q, 13=K, 14=A)
/// 注意：炸金花中 A 点数最大，2 不参与游戏
typedef ZhjSuit = Suit;

class ZhjCard implements Comparable<ZhjCard> {
  final ZhjSuit suit;

  /// 点数: 3-14 (11=J, 12=Q, 13=K, 14=A)
  /// 特例：在A-2-3顺子中，A作为1处理（由validator负责）
  final int rank;

  const ZhjCard({required this.suit, required this.rank});

  /// 显示文本
  String get displayText {
    switch (rank) {
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      case 14:
        return 'A';
      default:
        return rank.toString();
    }
  }

  /// 花色显示符号
  String get suitSymbol {
    switch (suit) {
      case ZhjSuit.spade:
        return '♠';
      case ZhjSuit.heart:
        return '♥';
      case ZhjSuit.club:
        return '♣';
      case ZhjSuit.diamond:
        return '♦';
    }
  }

  /// 是否是红色牌
  bool get isRed => suit == ZhjSuit.heart || suit == ZhjSuit.diamond;

  @override
  int compareTo(ZhjCard other) => rank.compareTo(other.rank);

  @override
  bool operator ==(Object other) =>
      other is ZhjCard && suit == other.suit && rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  @override
  String toString() => '$suitSymbol$displayText';

  /// 生成标准52张牌（无大小王，无2）
  static List<ZhjCard> standardDeck() {
    final deck = <ZhjCard>[];
    for (final suit in ZhjSuit.values) {
      for (int rank = 3; rank <= 14; rank++) {
        deck.add(ZhjCard(suit: suit, rank: rank));
      }
    }
    return deck;
  }
}
