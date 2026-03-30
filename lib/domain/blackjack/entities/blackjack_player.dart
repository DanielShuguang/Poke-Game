import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';

/// 21点玩家
class BlackjackPlayer {
  final String id;
  final String name;
  final bool isAi;
  final bool isDealer;

  /// 筹码余额
  final int chips;

  /// 当前局的手牌列表（通常1手，Split后最多2手）
  final List<BlackjackHand> hands;

  /// 当前操作的手牌索引
  final int activeHandIndex;

  const BlackjackPlayer({
    required this.id,
    required this.name,
    required this.isAi,
    this.isDealer = false,
    required this.chips,
    List<BlackjackHand>? hands,
    this.activeHandIndex = 0,
  }) : hands = hands ?? const [];

  /// 当前活动手牌
  BlackjackHand? get activeHand =>
      hands.isNotEmpty && activeHandIndex < hands.length
          ? hands[activeHandIndex]
          : null;

  /// 所有手牌是否都已完成操作
  bool get allHandsDone => hands.isNotEmpty && hands.every((h) => h.isDone);

  /// 本局下注总额（所有手牌之和）
  int get totalBet => hands.fold(0, (sum, h) => sum + h.bet);

  BlackjackPlayer copyWith({
    int? chips,
    List<BlackjackHand>? hands,
    int? activeHandIndex,
  }) {
    return BlackjackPlayer(
      id: id,
      name: name,
      isAi: isAi,
      isDealer: isDealer,
      chips: chips ?? this.chips,
      hands: hands ?? List.of(this.hands),
      activeHandIndex: activeHandIndex ?? this.activeHandIndex,
    );
  }

  Map<String, dynamic> toJson({bool includeCards = true}) => {
        'id': id,
        'name': name,
        'isAi': isAi,
        'isDealer': isDealer,
        'chips': chips,
        'activeHandIndex': activeHandIndex,
        'hands': includeCards
            ? hands.map((h) => h.toJson()).toList()
            : hands.map((h) => {
                  'cards': [],
                  'status': h.status.name,
                  'bet': h.bet,
                }).toList(),
      };

  static BlackjackPlayer fromJson(Map<String, dynamic> json) {
    final handsJson =
        (json['hands'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return BlackjackPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isAi: json['isAi'] as bool? ?? false,
      isDealer: json['isDealer'] as bool? ?? false,
      chips: (json['chips'] as num?)?.toInt() ?? 0,
      hands: handsJson.map(BlackjackHand.fromJson).toList(),
      activeHandIndex: (json['activeHandIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
