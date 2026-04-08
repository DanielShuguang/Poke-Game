import 'package:poke_game/domain/doudizhu/entities/card.dart' show Suit;

export 'package:poke_game/domain/doudizhu/entities/card.dart' show Suit;

enum JokerType { small, big }

/// 掼蛋扑克牌
/// 108张（两副牌，含4张王）
/// rank: 2-14 对应 2~A；大小王用 jokerType 区分
class GuandanCard implements Comparable<GuandanCard> {
  final Suit? suit;
  final int? rank;
  final JokerType? jokerType;

  /// 是否为级牌百搭（由外部根据当前 level 标记）
  final bool isWild;

  const GuandanCard({
    this.suit,
    this.rank,
    this.jokerType,
    this.isWild = false,
  }) : assert(
          (suit != null && rank != null && jokerType == null) ||
              (suit == null && rank == null && jokerType != null),
          'GuandanCard must be either a regular card or a joker',
        );

  const GuandanCard.bigJoker()
      : suit = null,
        rank = null,
        jokerType = JokerType.big,
        isWild = false;

  const GuandanCard.smallJoker()
      : suit = null,
        rank = null,
        jokerType = JokerType.small,
        isWild = false;

  bool get isJoker => jokerType != null;
  bool get isBigJoker => jokerType == JokerType.big;
  bool get isSmallJoker => jokerType == JokerType.small;
  bool get isRed =>
      suit == Suit.heart || suit == Suit.diamond || isBigJoker;

  String get displayText {
    if (isBigJoker) return '大王';
    if (isSmallJoker) return '小王';
    return switch (rank!) {
      11 => 'J',
      12 => 'Q',
      13 => 'K',
      14 => 'A',
      _ => rank.toString(),
    };
  }

  String get suitSymbol {
    if (isJoker) return '';
    return switch (suit!) {
      Suit.spade => '♠',
      Suit.heart => '♥',
      Suit.club => '♣',
      Suit.diamond => '♦',
    };
  }

  /// 不含百搭标记的副本（用于 JSON 序列化）
  GuandanCard withWild(bool wild) {
    return GuandanCard(
      suit: suit,
      rank: rank,
      jokerType: jokerType,
      isWild: wild,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 序列化
  // ────────────────────────────────────────────────────────────────

  /// 序列化为字符串 ID，例如 "AH"、"JokerBig"
  String toId() {
    if (isBigJoker) return 'JokerBig';
    if (isSmallJoker) return 'JokerSmall';
    final rankStr = switch (rank!) {
      11 => 'J',
      12 => 'Q',
      13 => 'K',
      14 => 'A',
      _ => rank.toString(),
    };
    final suitStr = switch (suit!) {
      Suit.spade => 'S',
      Suit.heart => 'H',
      Suit.club => 'C',
      Suit.diamond => 'D',
    };
    return '$rankStr$suitStr';
  }

  static GuandanCard fromId(String id) {
    if (id == 'JokerBig') return const GuandanCard.bigJoker();
    if (id == 'JokerSmall') return const GuandanCard.smallJoker();

    final suitChar = id[id.length - 1];
    final rankStr = id.substring(0, id.length - 1);

    final suit = switch (suitChar) {
      'S' => Suit.spade,
      'H' => Suit.heart,
      'C' => Suit.club,
      'D' => Suit.diamond,
      _ => throw ArgumentError('Unknown suit: $suitChar'),
    };

    final rank = switch (rankStr) {
      'J' => 11,
      'Q' => 12,
      'K' => 13,
      'A' => 14,
      _ => int.parse(rankStr),
    };

    return GuandanCard(suit: suit, rank: rank);
  }

  Map<String, dynamic> toJson() => {'id': toId()};
  static GuandanCard fromJson(Map<String, dynamic> json) =>
      fromId(json['id'] as String);

  // ────────────────────────────────────────────────────────────────
  // 比较 / 相等
  // ────────────────────────────────────────────────────────────────

  /// 手牌排序：按点数升序，同点按花色 ♦ < ♣ < ♥ < ♠ 排列
  /// 最终手牌顺序：2♦ 2♣ 2♥ 2♠ … A♦ A♣ A♥ A♠ 小王 大王
  @override
  int compareTo(GuandanCard other) {
    final rankCmp = _naturalRank.compareTo(other._naturalRank);
    if (rankCmp != 0) return rankCmp;
    return _suitOrder.compareTo(other._suitOrder);
  }

  int get _naturalRank {
    if (isBigJoker) return 1000;
    if (isSmallJoker) return 999;
    return rank!;
  }

  int get _suitOrder {
    if (isJoker) return 0;
    return switch (suit!) {
      Suit.spade => 3,
      Suit.heart => 2,
      Suit.club => 1,
      Suit.diamond => 0,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuandanCard &&
          suit == other.suit &&
          rank == other.rank &&
          jokerType == other.jokerType;

  @override
  int get hashCode => Object.hash(suit, rank, jokerType);

  @override
  String toString() {
    if (isWild) return '$displayText$suitSymbol(wild)';
    return '$displayText$suitSymbol';
  }

  // ────────────────────────────────────────────────────────────────
  // 静态工厂
  // ────────────────────────────────────────────────────────────────

  /// 生成标准52张牌
  static List<GuandanCard> standardDeck() {
    final cards = <GuandanCard>[];
    for (final suit in Suit.values) {
      for (int rank = 2; rank <= 14; rank++) {
        cards.add(GuandanCard(suit: suit, rank: rank));
      }
    }
    return cards;
  }

  /// 生成掼蛋用108张牌（两副52张 + 4张王）
  static List<GuandanCard> fullDeck() {
    return [
      ...standardDeck(),
      ...standardDeck(),
      const GuandanCard.smallJoker(),
      const GuandanCard.smallJoker(),
      const GuandanCard.bigJoker(),
      const GuandanCard.bigJoker(),
    ];
  }

  /// 根据当前 level 将牌组中的级牌标记为 isWild=true
  static List<GuandanCard> markWild(List<GuandanCard> cards, int level) {
    return cards.map((c) {
      if (!c.isJoker && c.rank == level) return c.withWild(true);
      return c;
    }).toList();
  }
}
