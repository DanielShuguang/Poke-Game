import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 卡牌数据模型，用于序列化/反序列化
class CardModel {
  final Suit suit;
  final int rank;

  const CardModel({
    required this.suit,
    required this.rank,
  });

  /// 从领域实体创建
  factory CardModel.fromEntity(Card card) => CardModel(
        suit: card.suit,
        rank: card.rank,
      );

  /// 转换为领域实体
  Card toEntity() => Card(suit: suit, rank: rank);

  /// 从 JSON 创建
  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
        suit: Suit.values[json['suit'] as int],
        rank: json['rank'] as int,
      );

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'suit': suit.index,
        'rank': rank,
      };
}
