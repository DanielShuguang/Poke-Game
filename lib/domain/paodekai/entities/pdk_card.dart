import 'dart:math';

enum PdkSuit { spade, heart, club, diamond, none }

/// rank 序数即比较大小：3=0, 4=1, ..., A=11, 2=12, jokerSmall=13, jokerBig=14
enum PdkRank {
  three, four, five, six, seven, eight, nine, ten,
  jack, queen, king, ace, two, jokerSmall, jokerBig,
}

class PdkCard implements Comparable<PdkCard> {
  final PdkRank rank;
  final PdkSuit suit;

  const PdkCard({required this.rank, required this.suit});

  bool get isJoker => rank == PdkRank.jokerSmall || rank == PdkRank.jokerBig;

  // 花色比较权重（高→低：spade=3,heart=2,club=1,diamond=0,none=-1）
  int get _suitWeight {
    switch (suit) {
      case PdkSuit.spade: return 3;
      case PdkSuit.heart: return 2;
      case PdkSuit.club: return 1;
      case PdkSuit.diamond: return 0;
      case PdkSuit.none: return -1;
    }
  }

  @override
  int compareTo(PdkCard other) {
    final rc = rank.index.compareTo(other.rank.index);
    if (rc != 0) return rc;
    return _suitWeight.compareTo(other._suitWeight);
  }

  bool get isSpadeThree => rank == PdkRank.three && suit == PdkSuit.spade;

  String get rankDisplay {
    const map = {
      PdkRank.three: '3', PdkRank.four: '4', PdkRank.five: '5',
      PdkRank.six: '6', PdkRank.seven: '7', PdkRank.eight: '8',
      PdkRank.nine: '9', PdkRank.ten: '10', PdkRank.jack: 'J',
      PdkRank.queen: 'Q', PdkRank.king: 'K', PdkRank.ace: 'A',
      PdkRank.two: '2', PdkRank.jokerSmall: '小王', PdkRank.jokerBig: '大王',
    };
    return map[rank]!;
  }

  String get suitSymbol {
    switch (suit) {
      case PdkSuit.spade: return '♠';
      case PdkSuit.heart: return '♥';
      case PdkSuit.club: return '♣';
      case PdkSuit.diamond: return '♦';
      case PdkSuit.none: return '';
    }
  }

  bool get isRed => suit == PdkSuit.heart || suit == PdkSuit.diamond;

  @override
  String toString() => '$suitSymbol$rankDisplay';

  @override
  bool operator ==(Object other) =>
      other is PdkCard && rank == other.rank && suit == other.suit;

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;

  Map<String, dynamic> toJson() => {'rank': rank.name, 'suit': suit.name};

  static PdkCard fromJson(Map<String, dynamic> json) {
    final rank = PdkRank.values.firstWhere(
      (e) => e.name == json['rank'],
      orElse: () => PdkRank.three,
    );
    final suit = PdkSuit.values.firstWhere(
      (e) => e.name == json['suit'],
      orElse: () => PdkSuit.none,
    );
    return PdkCard(rank: rank, suit: suit);
  }

  /// 生成 54 张完整牌组（含大小王）
  static List<PdkCard> fullDeck() {
    final deck = <PdkCard>[];
    for (final suit in [PdkSuit.spade, PdkSuit.heart, PdkSuit.club, PdkSuit.diamond]) {
      for (final rank in PdkRank.values) {
        if (rank == PdkRank.jokerSmall || rank == PdkRank.jokerBig) continue;
        deck.add(PdkCard(rank: rank, suit: suit));
      }
    }
    deck.add(const PdkCard(rank: PdkRank.jokerSmall, suit: PdkSuit.none));
    deck.add(const PdkCard(rank: PdkRank.jokerBig, suit: PdkSuit.none));
    deck.shuffle(Random());
    return deck;
  }
}
