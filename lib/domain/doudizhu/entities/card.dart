/// 花色枚举
enum Suit {
  /// 黑桃
  spade,

  /// 红心
  heart,

  /// 梅花
  club,

  /// 方块
  diamond,
}

/// 扑克牌实体
class Card implements Comparable<Card> {
  /// 花色
  final Suit suit;

  /// 点数 (3-15, 3-10为数字, 11=J, 12=Q, 13=K, 14=A, 15=2, 16=小王, 17=大王)
  final int rank;

  const Card({
    required this.suit,
    required this.rank,
  });

  /// 创建小王
  const Card.smallJoker()
      : suit = Suit.spade,
        rank = 16;

  /// 创建大王
  const Card.bigJoker()
      : suit = Suit.heart,
        rank = 17;

  /// 是否是王
  bool get isJoker => rank >= 16;

  /// 是否是小王
  bool get isSmallJoker => rank == 16;

  /// 是否是大王
  bool get isBigJoker => rank == 17;

  /// 获取显示文本
  String get displayText {
    if (isSmallJoker) return '小王';
    if (isBigJoker) return '大王';
    switch (rank) {
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      case 14:
        return 'A';
      case 15:
        return '2';
      default:
        return rank.toString();
    }
  }

  /// 获取花色符号
  String get suitSymbol {
    if (isJoker) {
      return isSmallJoker ? '🃏' : '🃏';
    }
    switch (suit) {
      case Suit.spade:
        return '♠';
      case Suit.heart:
        return '♥';
      case Suit.club:
        return '♣';
      case Suit.diamond:
        return '♦';
    }
  }

  /// 是否是红色花色
  bool get isRed => suit == Suit.heart || suit == Suit.diamond || isBigJoker;

  @override
  int compareTo(Card other) {
    // 王最大，然后按点数从大到小排序
    if (isJoker && !other.isJoker) return -1;
    if (!isJoker && other.isJoker) return 1;
    if (isJoker && other.isJoker) {
      return other.rank.compareTo(rank); // 大王 > 小王
    }
    // 普通牌：先按点数排序（点数大的在前），再按花色排序
    final rankCompare = other.rank.compareTo(rank);
    if (rankCompare != 0) return rankCompare;
    return suit.index.compareTo(other.suit.index);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card && runtimeType == other.runtimeType && suit == other.suit && rank == other.rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '$suitSymbol$displayText';
}

/// 创建标准扑克牌组（不含王）
List<Card> createStandardDeck() {
  final deck = <Card>[];
  for (final suit in Suit.values) {
    for (var rank = 3; rank <= 15; rank++) {
      deck.add(Card(suit: suit, rank: rank));
    }
  }
  return deck;
}

/// 创建完整扑克牌组（54张）
List<Card> createFullDeck() {
  final deck = createStandardDeck();
  deck.add(const Card.smallJoker());
  deck.add(const Card.bigJoker());
  return deck;
}
