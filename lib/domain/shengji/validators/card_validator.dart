import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/trump_info.dart';

/// 牌型类型
enum PlayType {
  /// 单张
  single,

  /// 对子
  pair,

  /// 拖拉机（连续对子）
  tractor,
}

/// 牌型识别结果
class CardShape {
  final PlayType type;
  final int length; // 单张=1，对子=2，拖拉机=对数*2
  final int? mainRank; // 主牌点数

  const CardShape({
    required this.type,
    required this.length,
    this.mainRank,
  });
}

/// 牌型验证器
class CardValidator {
  CardValidator._();

  /// 识别牌型
  ///
  /// [trumpInfo] 可选，提供后将额外检测将牌拖拉机（王炸、跨花色级牌拖拉机）
  static CardShape? identify(List<ShengjiCard> cards, {TrumpInfo? trumpInfo}) {
    if (cards.isEmpty) return null;

    final sorted = _sortByRank(cards);

    // 单张
    if (cards.length == 1) {
      return CardShape(type: PlayType.single, length: 1, mainRank: cards.first.rank);
    }

    // 对子
    if (_isPair(sorted)) {
      return CardShape(type: PlayType.pair, length: 2, mainRank: sorted.first.rank);
    }

    // 将牌拖拉机（王炸、跨花色级牌、将牌花色跨级牌连续对子）
    if (trumpInfo != null && _isTrumpTractor(sorted, trumpInfo)) {
      return CardShape(
        type: PlayType.tractor,
        length: sorted.length,
        mainRank: sorted.first.rank,
      );
    }

    // 普通拖拉机（同花色连续对子）
    if (_isTractor(sorted)) {
      return CardShape(
        type: PlayType.tractor,
        length: sorted.length,
        mainRank: sorted.first.rank,
      );
    }

    return null;
  }

  /// 检查是否是有效牌型
  static bool isValidPlay(List<ShengjiCard> cards, {TrumpInfo? trumpInfo}) {
    return identify(cards, trumpInfo: trumpInfo) != null;
  }

  /// 检查是否是对子
  static bool _isPair(List<ShengjiCard> cards) {
    if (cards.length != 2) return false;
    // 两张牌点数相同，且都是普通牌
    if (cards[0].isJoker || cards[1].isJoker) {
      // 大小王：必须都是王且类型相同
      return cards[0].jokerType == cards[1].jokerType;
    }
    return cards[0].rank == cards[1].rank;
  }

  /// 检查是否是拖拉机（同花色连续对子，不含大小王）
  static bool _isTractor(List<ShengjiCard> cards) {
    if (cards.length < 4 || cards.length % 2 != 0) return false;

    // 不能包含大小王
    if (cards.any((c) => c.isJoker)) return false;

    // 按点数分组
    final rankGroups = <int, int>{};
    for (final card in cards) {
      if (card.rank == null) return false;
      rankGroups[card.rank!] = (rankGroups[card.rank!] ?? 0) + 1;
    }

    // 每个点数必须恰好有 2 张
    if (!rankGroups.values.every((count) => count == 2)) return false;

    // 点数必须连续
    final ranks = rankGroups.keys.toList()..sort();
    for (int i = 1; i < ranks.length; i++) {
      if (ranks[i] - ranks[i - 1] != 1) return false;
    }

    // 检查花色一致性（升级中拖拉机必须同花色）
    final suits = cards.map((c) => c.suit).toSet();
    return suits.length == 1;
  }

  /// 检查是否是将牌拖拉机（需要 TrumpInfo 上下文）
  ///
  /// 支持三种情形：
  /// 1. 王炸：大王×2 + 小王×2
  /// 2. 将牌花色跨级牌连续对子：e.g. 6♠×2 + 8♠×2（将牌是7♠时）
  /// 3. 相邻花色级牌对子：e.g. 2♦×2 + 2♣×2
  static bool _isTrumpTractor(List<ShengjiCard> cards, TrumpInfo trumpInfo) {
    if (cards.length < 4 || cards.length % 2 != 0) return false;

    // 所有牌必须是将牌
    if (!cards.every((c) => trumpInfo.isTrump(c))) return false;

    // 按将牌拖拉机位置分组
    final posGroups = <int, int>{};
    for (final card in cards) {
      final pos = _getTrumpTractorPos(card, trumpInfo);
      if (pos == null) return false;
      posGroups[pos] = (posGroups[pos] ?? 0) + 1;
    }

    // 每个位置恰好有 2 张
    if (!posGroups.values.every((count) => count == 2)) return false;

    // 位置必须连续（相邻差为 1）
    final positions = posGroups.keys.toList()..sort();
    for (int i = 1; i < positions.length; i++) {
      if (positions[i] - positions[i - 1] != 1) return false;
    }

    return true;
  }

  /// 获取将牌在拖拉机序列中的位置值
  ///
  /// 位置分区（各区之间有大间距，确保不会跨区组成拖拉机）：
  /// - 将牌花色普通牌：2..14（按点数连续，跳过级牌点数，max≈13）
  /// - 其他花色级牌：200..203（按花色索引，相邻花色可组成拖拉机）
  /// - 将牌花色级牌：400
  /// - 小王：499；大王：500（相邻，可组成王炸拖拉机）
  static int? _getTrumpTractorPos(ShengjiCard card, TrumpInfo trumpInfo) {
    if (!trumpInfo.isTrump(card)) return null;

    final rankLevel = trumpInfo.rankLevel;
    final trumpSuit = trumpInfo.trumpSuit;

    // 大王：位置 500
    if (card.isBigJoker) return 500;
    // 小王：位置 499（与大王相邻，可组成王炸拖拉机）
    if (card.isSmallJoker) return 499;

    // 将牌花色的级牌：位置 400
    if (trumpSuit != null && card.suit == trumpSuit && card.rank == rankLevel) {
      return 400;
    }

    // 其他花色的级牌：200 + (3 - suit.index)
    // spade(0)→203, heart(1)→202, club(2)→201, diamond(3)→200
    // 相邻花色（索引差=1）的级牌对子可以组成拖拉机
    if (card.rank == rankLevel) {
      return 200 + (3 - card.suit!.index);
    }

    // 将牌花色的普通牌：按点数连续排列，跳过级牌点数
    // rank < rankLevel 保持原值；rank > rankLevel 减 1 填补级牌留下的空位
    if (trumpSuit != null && card.suit == trumpSuit) {
      final rank = card.rank!;
      return rank < rankLevel ? rank : rank - 1;
    }

    return null;
  }

  /// 获取牌的花色（考虑大小王）
  static Suit? getSuit(ShengjiCard card) {
    return card.suit;
  }

  /// 获取牌组的主花色（首张牌的花色）
  static Suit? getMainSuit(List<ShengjiCard> cards) {
    if (cards.isEmpty) return null;
    final first = cards.first;
    if (first.isJoker) return null;
    return first.suit;
  }

  /// 按点数排序（降序）
  static List<ShengjiCard> _sortByRank(List<ShengjiCard> cards) {
    final sorted = List<ShengjiCard>.from(cards);
    sorted.sort((a, b) => b.baseRank.compareTo(a.baseRank));
    return sorted;
  }

  /// 检查手牌中是否有足够的花色牌
  static bool hasSuit(List<ShengjiCard> hand, Suit suit, int count) {
    final suitCards = hand.where((c) => c.suit == suit).length;
    return suitCards >= count;
  }

  /// 获取手牌中指定花色的牌
  static List<ShengjiCard> getSuitCards(List<ShengjiCard> hand, Suit suit) {
    return hand.where((c) => c.suit == suit).toList();
  }
}
