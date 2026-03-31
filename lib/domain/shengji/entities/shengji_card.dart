import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 升级扑克牌实体
///
/// 复用斗地主的 Suit 枚举，支持两副牌（108张）
/// rank: 2-14 (2=2, ..., 10=10, 11=J, 12=Q, 13=K, 14=A)
/// 大小王使用 jokerType 区分
class ShengjiCard implements Comparable<ShengjiCard> {
  /// 花色（null 表示大小王）
  final Suit? suit;

  /// 点数: 2-14 (2-10为数字, 11=J, 12=Q, 13=K, 14=A)
  final int? rank;

  /// 大小王类型（null 表示普通牌）
  final JokerType? jokerType;

  const ShengjiCard({
    this.suit,
    this.rank,
    this.jokerType,
  }) : assert(
         (suit != null && rank != null && jokerType == null) ||
         (suit == null && rank == null && jokerType != null),
         '必须是普通牌或大小王之一',
       );

  /// 创建大王
  const ShengjiCard.bigJoker() : suit = null, rank = null, jokerType = JokerType.big;

  /// 创建小王
  const ShengjiCard.smallJoker() : suit = null, rank = null, jokerType = JokerType.small;

  /// 是否是大小王
  bool get isJoker => jokerType != null;

  /// 是否是大王
  bool get isBigJoker => jokerType == JokerType.big;

  /// 是否是小王
  bool get isSmallJoker => jokerType == JokerType.small;

  /// 显示文本
  String get displayText {
    if (isBigJoker) return '大王';
    if (isSmallJoker) return '小王';
    switch (rank!) {
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
    if (isJoker) return '🃏';
    switch (suit!) {
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
  bool get isRed {
    if (isBigJoker) return true;
    if (isJoker) return false;
    return suit == Suit.heart || suit == Suit.diamond;
  }

  /// 获取用于比较的基础点数（不考虑将牌）
  int get baseRank {
    if (isBigJoker) return 100;
    if (isSmallJoker) return 99;
    return rank!;
  }

  @override
  int compareTo(ShengjiCard other) {
    // 大小王最大
    if (isJoker && !other.isJoker) return 1;
    if (!isJoker && other.isJoker) return -1;
    if (isJoker && other.isJoker) {
      return isBigJoker ? 1 : -1;
    }
    // 普通牌：先按点数，再按花色
    final rankCmp = rank!.compareTo(other.rank!);
    if (rankCmp != 0) return rankCmp;
    return suit!.index.compareTo(other.suit!.index);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShengjiCard &&
          suit == other.suit &&
          rank == other.rank &&
          jokerType == other.jokerType;

  @override
  int get hashCode => Object.hash(suit, rank, jokerType);

  @override
  String toString() => '$suitSymbol$displayText';

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'suit': suit?.name,
      'rank': rank,
      'jokerType': jokerType?.name,
    };
  }

  /// 从 JSON 反序列化
  static ShengjiCard fromJson(Map<String, dynamic> json) {
    final jokerTypeName = json['jokerType'] as String?;
    if (jokerTypeName != null) {
      return ShengjiCard(
        jokerType: JokerType.values.firstWhere(
          (e) => e.name == jokerTypeName,
          orElse: () => JokerType.small,
        ),
      );
    }
    return ShengjiCard(
      suit: Suit.values.firstWhere(
        (e) => e.name == json['suit'],
        orElse: () => Suit.spade,
      ),
      rank: json['rank'] as int,
    );
  }

  /// 创建标准52张牌（不含大小王）
  static List<ShengjiCard> standardDeck() {
    final deck = <ShengjiCard>[];
    for (final suit in Suit.values) {
      for (int rank = 2; rank <= 14; rank++) {
        deck.add(ShengjiCard(suit: suit, rank: rank));
      }
    }
    return deck;
  }

  /// 创建升级用牌组（两副牌 + 4张大小王 = 108张）
  static List<ShengjiCard> fullDeck() {
    final deck = <ShengjiCard>[];
    // 两副标准牌
    deck.addAll(standardDeck());
    deck.addAll(standardDeck());
    // 4张大小王（2张大王 + 2张小王）
    deck.add(const ShengjiCard.bigJoker());
    deck.add(const ShengjiCard.bigJoker());
    deck.add(const ShengjiCard.smallJoker());
    deck.add(const ShengjiCard.smallJoker());
    return deck;
  }
}

/// 大小王类型
enum JokerType {
  /// 小王
  small,

  /// 大王
  big,
}
