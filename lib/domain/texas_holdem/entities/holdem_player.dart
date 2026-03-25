import 'package:poke_game/domain/doudizhu/entities/card.dart';

/// 玩家行动类型
enum PlayerAction {
  fold,
  check,
  call,
  raise,
  allIn,
}

/// 德州扑克玩家实体
class HoldemPlayer {
  final String id;
  final String name;
  final int chips;
  final List<Card> holeCards;
  final int currentBet;
  final bool isFolded;
  final bool isAllIn;

  const HoldemPlayer({
    required this.id,
    required this.name,
    required this.chips,
    this.holeCards = const [],
    this.currentBet = 0,
    this.isFolded = false,
    this.isAllIn = false,
  });

  /// 是否还在局中（未弃牌）
  bool get isActive => !isFolded;

  /// 是否可以行动（未弃牌且未 All-in）
  bool get canAct => !isFolded && !isAllIn;

  HoldemPlayer copyWith({
    String? id,
    String? name,
    int? chips,
    List<Card>? holeCards,
    int? currentBet,
    bool? isFolded,
    bool? isAllIn,
  }) {
    return HoldemPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      chips: chips ?? this.chips,
      holeCards: holeCards ?? this.holeCards,
      currentBet: currentBet ?? this.currentBet,
      isFolded: isFolded ?? this.isFolded,
      isAllIn: isAllIn ?? this.isAllIn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HoldemPlayer && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HoldemPlayer($name, chips=$chips, bet=$currentBet)';
}
