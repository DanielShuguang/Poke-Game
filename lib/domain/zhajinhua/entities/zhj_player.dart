import 'package:poke_game/domain/zhajinhua/entities/zhj_card.dart';

/// 炸金花玩家
class ZhjPlayer {
  final String id;
  final String name;
  final bool isAi;

  /// AI 激进度 0.0（保守）~ 1.0（激进），真人玩家忽略此值
  final double aggression;

  List<ZhjCard> cards;
  int chips;

  /// 是否已看牌
  bool hasPeeked;

  /// 是否已弃牌
  bool isFolded;

  /// 本局已投入筹码（用于结算显示）
  int betAmount;

  ZhjPlayer({
    required this.id,
    required this.name,
    required this.isAi,
    this.aggression = 0.5,
    List<ZhjCard>? cards,
    required this.chips,
    this.hasPeeked = false,
    this.isFolded = false,
    this.betAmount = 0,
  }) : cards = cards ?? [];

  /// 是否存活（未弃牌）
  bool get isAlive => !isFolded;

  ZhjPlayer copyWith({
    List<ZhjCard>? cards,
    int? chips,
    bool? hasPeeked,
    bool? isFolded,
    int? betAmount,
  }) {
    return ZhjPlayer(
      id: id,
      name: name,
      isAi: isAi,
      aggression: aggression,
      cards: cards ?? List.of(this.cards),
      chips: chips ?? this.chips,
      hasPeeked: hasPeeked ?? this.hasPeeked,
      isFolded: isFolded ?? this.isFolded,
      betAmount: betAmount ?? this.betAmount,
    );
  }
}
