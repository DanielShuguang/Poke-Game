import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';

/// 将牌信息值对象
///
/// 封装当前局将牌的判断逻辑，包括级牌和将牌花色
class TrumpInfo {
  /// 将牌花色（null 表示无将）
  final Suit? trumpSuit;

  /// 级牌点数（2-14，对应 2-A）
  final int rankLevel;

  const TrumpInfo({
    this.trumpSuit,
    required this.rankLevel,
  }) : assert(rankLevel >= 2 && rankLevel <= 14, '级牌必须在 2-14 之间');

  /// 是否是无将模式
  bool get isNoTrump => trumpSuit == null;

  /// 判断是否是将牌
  bool isTrump(ShengjiCard card) {
    // 大小王始终是将牌
    if (card.isJoker) return true;
    // 级牌是将牌
    if (card.rank == rankLevel) return true;
    // 将牌花色的牌是将牌（无将模式下无将牌花色）
    if (trumpSuit != null && card.suit == trumpSuit) return true;
    return false;
  }

  /// 获取将牌的排序值（越大越强）
  int trumpRank(ShengjiCard card) {
    // 大王：最高
    if (card.isBigJoker) return 1000;
    // 小王
    if (card.isSmallJoker) return 999;

    // 级牌
    if (card.rank == rankLevel) {
      if (trumpSuit != null && card.suit == trumpSuit) {
        // 将牌花色的级牌：最强级牌
        return 900;
      } else {
        // 其他花色的级牌：按花色排序
        return 800 - card.suit!.index;
      }
    }

    // 将牌花色的普通牌
    if (trumpSuit != null && card.suit == trumpSuit) {
      return 100 + card.rank!;
    }

    // 非将牌：返回负数
    return -card.rank!;
  }

  /// 比较两张牌的大小（考虑将牌）
  /// 返回值：>0 表示 a > b，<0 表示 a < b，=0 表示相等
  int compare(ShengjiCard a, ShengjiCard b) {
    final aIsTrump = isTrump(a);
    final bIsTrump = isTrump(b);

    // 将牌大于非将牌
    if (aIsTrump && !bIsTrump) return 1;
    if (!aIsTrump && bIsTrump) return -1;

    // 都是将牌：按将牌等级比较
    if (aIsTrump && bIsTrump) {
      return trumpRank(a).compareTo(trumpRank(b));
    }

    // 都不是将牌：比较花色和点数
    // 先比花色（出牌花色优先）
    if (a.suit != b.suit) {
      // 不同花色无法直接比较，需要上下文
      // 这里按花色索引排序
      return a.suit!.index.compareTo(b.suit!.index);
    }
    // 同花色比点数
    return a.rank!.compareTo(b.rank!);
  }

  /// 比较两张牌在同花色下的大小
  /// 如果花色不同，返回 0 表示无法比较
  int compareSameSuit(ShengjiCard a, ShengjiCard b) {
    if (a.isJoker || b.isJoker) {
      // 大小王不参与花色比较
      return compare(a, b);
    }
    if (a.suit != b.suit) return 0;
    return compare(a, b);
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'trumpSuit': trumpSuit?.name,
      'rankLevel': rankLevel,
    };
  }

  /// 从 JSON 反序列化
  static TrumpInfo fromJson(Map<String, dynamic> json) {
    final suitName = json['trumpSuit'] as String?;
    return TrumpInfo(
      trumpSuit: suitName != null
          ? Suit.values.firstWhere(
              (e) => e.name == suitName,
              orElse: () => Suit.spade,
            )
          : null,
      rankLevel: json['rankLevel'] as int? ?? 2,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrumpInfo && trumpSuit == other.trumpSuit && rankLevel == other.rankLevel;

  @override
  int get hashCode => Object.hash(trumpSuit, rankLevel);

  @override
  String toString() {
    if (isNoTrump) return '无将($rankLevel级)';
    final suitSymbol = trumpSuit == Suit.spade
        ? '♠'
        : trumpSuit == Suit.heart
            ? '♥'
            : trumpSuit == Suit.club
                ? '♣'
                : '♦';
    return '$suitSymbol$rankLevel级';
  }
}
