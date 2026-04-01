import 'pdk_card.dart';

enum PdkHandType {
  single,
  pair,
  triple,
  straight,        // 顺子 ≥5张
  consecutivePairs, // 连对 ≥3对
  airplane,        // 飞机 ≥2组连续三张
  bomb,
  rocket,
}

/// 代表一手出牌，含牌型和用于比较的关键牌
class PdkPlayedHand {
  final PdkHandType type;
  final List<PdkCard> cards;

  /// 决定大小的关键牌（单张/对/三张/炸弹取最大牌，顺子/连对/飞机取最小组的最大牌）
  final PdkCard keyCard;

  const PdkPlayedHand({
    required this.type,
    required this.cards,
    required this.keyCard,
  });

  int get length => cards.length;

  /// 是否可以压过 [other]（同型等长比关键牌，炸弹/王炸特殊处理）
  bool beats(PdkPlayedHand other) {
    if (type == PdkHandType.rocket) return true;
    if (other.type == PdkHandType.rocket) return false;
    if (type == PdkHandType.bomb && other.type != PdkHandType.bomb) return true;
    if (other.type == PdkHandType.bomb && type != PdkHandType.bomb) return false;
    if (type != other.type) return false;
    if (length != other.length) return false;
    return keyCard.compareTo(other.keyCard) > 0;
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'cards': cards.map((c) => c.toJson()).toList(),
        'keyCard': keyCard.toJson(),
      };

  static PdkPlayedHand fromJson(Map<String, dynamic> json) {
    final type = PdkHandType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => PdkHandType.single,
    );
    final cards = (json['cards'] as List)
        .cast<Map<String, dynamic>>()
        .map(PdkCard.fromJson)
        .toList();
    final keyCard = PdkCard.fromJson(json['keyCard'] as Map<String, dynamic>);
    return PdkPlayedHand(type: type, cards: cards, keyCard: keyCard);
  }
}
