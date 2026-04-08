import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';

/// 叫牌类型
enum CallType {
  /// 对子
  pair,

  /// 拖拉机
  tractor,

  /// 无将（大小王对子）
  noTrump,
}

/// 叫牌内容
class TrumpCall {
  final CallType type;
  final Suit? suit; // null 表示无将
  final int? rank; // 对子/拖拉机的点数
  final JokerType? jokerType; // 无将时的大小王类型

  const TrumpCall({
    required this.type,
    this.suit,
    this.rank,
    this.jokerType,
  });

  /// 创建对子叫牌
  const TrumpCall.pair(this.suit, this.rank) : type = CallType.pair, jokerType = null;

  /// 创建拖拉机叫牌
  const TrumpCall.tractor(this.suit, this.rank) : type = CallType.tractor, jokerType = null;

  /// 创建无将叫牌
  const TrumpCall.noTrump(this.jokerType) : type = CallType.noTrump, suit = null, rank = null;

  @override
  String toString() {
    switch (type) {
      case CallType.pair:
        return '${_suitSymbol(suit!)}$rank 对子';
      case CallType.tractor:
        return '${_suitSymbol(suit!)}$rank 拖拉机';
      case CallType.noTrump:
        return jokerType == JokerType.big ? '大王无将' : '小王无将';
    }
  }

  static String _suitSymbol(Suit suit) {
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
}

/// 叫牌验证器
class CallValidator {
  CallValidator._();

  /// 验证叫牌是否合法
  static bool validate({
    required List<ShengjiCard> hand,
    required TrumpCall call,
  }) {
    switch (call.type) {
      case CallType.pair:
        return _validatePair(hand, call.suit!, call.rank!);
      case CallType.tractor:
        return _validateTractor(hand, call.suit!, call.rank!);
      case CallType.noTrump:
        return _validateNoTrump(hand, call.jokerType!);
    }
  }

  /// 验证对子叫牌
  static bool _validatePair(List<ShengjiCard> hand, Suit suit, int rank) {
    final suitCards = hand.where((c) => c.suit == suit && c.rank == rank);
    return suitCards.length >= 2;
  }

  /// 验证拖拉机叫牌
  static bool _validateTractor(List<ShengjiCard> hand, Suit suit, int rank) {
    // 需要至少两对连续对子
    final suitCards = hand.where((c) => c.suit == suit).toList();
    final rankCounts = <int, int>{};
    for (final card in suitCards) {
      if (card.rank != null) {
        rankCounts[card.rank!] = (rankCounts[card.rank!] ?? 0) + 1;
      }
    }

    // 检查从 rank 开始是否有连续对子
    if ((rankCounts[rank] ?? 0) < 2) return false;
    if ((rankCounts[rank + 1] ?? 0) < 2) return false;

    return true;
  }

  /// 验证无将叫牌
  static bool _validateNoTrump(List<ShengjiCard> hand, JokerType jokerType) {
    final jokers = hand.where((c) => c.isJoker && c.jokerType == jokerType);
    // 单张大王即可叫无将；小王需要两张
    if (jokerType == JokerType.big) return jokers.isNotEmpty;
    return jokers.length >= 2;
  }

  /// 比较两个叫牌的大小
  /// 返回 1 表示 a > b，-1 表示 a < b，0 表示相等
  static int compare(TrumpCall a, TrumpCall b) {
    // 拖拉机 > 对子 > 无将
    final aPriority = _getPriority(a.type);
    final bPriority = _getPriority(b.type);

    if (aPriority != bPriority) {
      return aPriority > bPriority ? 1 : -1;
    }

    // 同类型比较点数或大小王类型
    switch (a.type) {
      case CallType.pair:
      case CallType.tractor:
        // 点数大的优先
        return a.rank!.compareTo(b.rank!);
      case CallType.noTrump:
        // 大王 > 小王
        return a.jokerType == JokerType.big ? 1 : -1;
    }
  }

  static int _getPriority(CallType type) {
    switch (type) {
      case CallType.tractor:
        return 3;
      case CallType.pair:
        return 2;
      case CallType.noTrump:
        return 1;
    }
  }

  /// 从手牌中找出所有可能的叫牌
  static List<TrumpCall> findPossibleCalls(
    List<ShengjiCard> hand,
    int currentLevel,
  ) {
    final calls = <TrumpCall>[];

    // 检查大小王对子（无将）
    for (final jokerType in JokerType.values) {
      if (_validateNoTrump(hand, jokerType)) {
        calls.add(TrumpCall.noTrump(jokerType));
      }
    }

    // 检查级牌对子和拖拉机
    for (final suit in Suit.values) {
      // 对子
      if (_validatePair(hand, suit, currentLevel)) {
        calls.add(TrumpCall.pair(suit, currentLevel));
      }
      // 拖拉机（需要下一级牌也存在）
      if (currentLevel < 14 &&
          _validateTractor(hand, suit, currentLevel)) {
        calls.add(TrumpCall.tractor(suit, currentLevel));
      }
    }

    return calls;
  }
}
