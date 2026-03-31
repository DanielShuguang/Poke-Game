import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/trump_info.dart';
import 'package:poke_game/domain/shengji/validators/card_validator.dart';

/// 出牌验证结果
class PlayValidationResult {
  final bool isValid;
  final String? errorMessage;

  const PlayValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const PlayValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// 出牌验证器
class PlayValidator {
  PlayValidator._();

  /// 验证出牌是否合法
  static PlayValidationResult validate({
    required List<ShengjiCard> hand,
    required List<ShengjiCard> playedCards,
    required List<ShengjiCard> leadCards,
    required TrumpInfo trumpInfo,
  }) {
    // 1. 检查是否有这些牌
    if (!_hasCards(hand, playedCards)) {
      return const PlayValidationResult.invalid('你没有这些牌');
    }

    // 2. 检查牌型是否有效
    final playShape = CardValidator.identify(playedCards, trumpInfo: trumpInfo);
    if (playShape == null) {
      return const PlayValidationResult.invalid('无效牌型');
    }

    // 3. 如果是首出，任意合法牌型都可以
    if (leadCards.isEmpty) {
      return const PlayValidationResult.valid();
    }

    // 4. 获取首出花色和牌型
    final leadShape = CardValidator.identify(leadCards, trumpInfo: trumpInfo);
    if (leadShape == null) {
      return const PlayValidationResult.invalid('首出牌型无效');
    }

    // 5. 检查牌数是否匹配
    if (playedCards.length != leadCards.length) {
      return const PlayValidationResult.invalid('出牌数量不匹配');
    }

    // 6. 获取首出花色
    final leadSuit = _getLeadSuit(leadCards, trumpInfo);

    // 7. 检查是否需要跟花色
    if (leadSuit != null) {
      final suitCardsInHand = hand.where((c) =>
          !trumpInfo.isTrump(c) && c.suit == leadSuit).toList();

      if (suitCardsInHand.isNotEmpty) {
        // 有该花色，必须跟
        final allSameSuit = playedCards.every((c) =>
            trumpInfo.isTrump(c) || c.suit == leadSuit);
        if (!allSameSuit) {
          return PlayValidationResult.invalid('必须跟${_suitName(leadSuit)}花色');
        }

        // 检查跟的花色牌数量是否足够
        final suitCardsPlayed = playedCards.where((c) =>
            !trumpInfo.isTrump(c) && c.suit == leadSuit).length;
        if (suitCardsPlayed < suitCardsInHand.length &&
            suitCardsPlayed < playedCards.length) {
          // 有足够的花色牌但没全跟
          if (suitCardsInHand.length >= playedCards.length) {
            return PlayValidationResult.invalid('必须跟出所有${_suitName(leadSuit)}花色牌');
          }
        }
      }
    }

    return const PlayValidationResult.valid();
  }

  /// 比较出牌大小
  /// 返回 1 表示 a > b，-1 表示 a < b，0 表示相等
  static int compare({
    required List<ShengjiCard> a,
    required List<ShengjiCard> b,
    required List<ShengjiCard> leadCards,
    required TrumpInfo trumpInfo,
  }) {
    final aHasTrump = a.any((c) => trumpInfo.isTrump(c));
    final bHasTrump = b.any((c) => trumpInfo.isTrump(c));

    // 将牌大于非将牌
    if (aHasTrump && !bHasTrump) return 1;
    if (!aHasTrump && bHasTrump) return -1;

    // 都是将牌
    if (aHasTrump && bHasTrump) {
      return _compareTrumpCards(a, b, trumpInfo);
    }

    // 都不是将牌，比较同花色
    final aSuit = CardValidator.getMainSuit(a);
    final bSuit = CardValidator.getMainSuit(b);
    final leadSuit = _getLeadSuit(leadCards, trumpInfo);

    // 首出花色优先
    if (aSuit == leadSuit && bSuit != leadSuit) return 1;
    if (aSuit != leadSuit && bSuit == leadSuit) return -1;

    // 同花色比点数
    if (aSuit == bSuit) {
      return _compareSameSuit(a, b);
    }

    // 不同花色，先出的优先（垫牌）
    return 0;
  }

  /// 检查手牌是否包含出牌
  static bool _hasCards(List<ShengjiCard> hand, List<ShengjiCard> played) {
    final handCopy = List<ShengjiCard>.from(hand);
    for (final card in played) {
      final index = handCopy.indexWhere((c) => c == card);
      if (index == -1) return false;
      handCopy.removeAt(index);
    }
    return true;
  }

  /// 获取首出花色
  static Suit? _getLeadSuit(List<ShengjiCard> cards, TrumpInfo trumpInfo) {
    // 如果首出是将牌，返回 null（需要跟将牌）
    if (cards.any((c) => trumpInfo.isTrump(c))) {
      return null;
    }
    return CardValidator.getMainSuit(cards);
  }

  /// 比较将牌
  static int _compareTrumpCards(
    List<ShengjiCard> a,
    List<ShengjiCard> b,
    TrumpInfo trumpInfo,
  ) {
    // 找出最大的将牌比较
    final aMax = a.reduce((x, y) =>
        trumpInfo.trumpRank(x) > trumpInfo.trumpRank(y) ? x : y);
    final bMax = b.reduce((x, y) =>
        trumpInfo.trumpRank(x) > trumpInfo.trumpRank(y) ? x : y);
    return trumpInfo.trumpRank(aMax).compareTo(trumpInfo.trumpRank(bMax));
  }

  /// 比较同花色牌
  static int _compareSameSuit(List<ShengjiCard> a, List<ShengjiCard> b) {
    final aMax = a.reduce((x, y) => x.compareTo(y) > 0 ? x : y);
    final bMax = b.reduce((x, y) => x.compareTo(y) > 0 ? x : y);
    return aMax.compareTo(bMax);
  }

  /// 花色名称
  static String _suitName(Suit suit) {
    switch (suit) {
      case Suit.spade:
        return '黑桃';
      case Suit.heart:
        return '红桃';
      case Suit.club:
        return '梅花';
      case Suit.diamond:
        return '方块';
    }
  }
}
