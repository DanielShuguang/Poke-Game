import 'package:poke_game/domain/niuniu/entities/niuniu_hand.dart';

/// 玩家角色
enum NiuniuRole {
  banker, // 庄家
  punter, // 闲家
}

/// 玩家操作状态
enum NiuniuPlayerStatus {
  waiting, // 等待下注
  bet, // 已下注
  broke, // 筹码为0，跳过本局
}

/// 牛牛玩家
class NiuniuPlayer {
  final String id;
  final String name;
  final bool isAi;
  final NiuniuRole role;
  final int chips;
  final int betAmount;
  final NiuniuHand? hand;
  final NiuniuPlayerStatus status;

  const NiuniuPlayer({
    required this.id,
    required this.name,
    this.isAi = false,
    required this.role,
    required this.chips,
    this.betAmount = 0,
    this.hand,
    this.status = NiuniuPlayerStatus.waiting,
  });

  bool get isBanker => role == NiuniuRole.banker;
  bool get isPunter => role == NiuniuRole.punter;

  NiuniuPlayer copyWith({
    String? id,
    String? name,
    bool? isAi,
    NiuniuRole? role,
    int? chips,
    int? betAmount,
    NiuniuHand? hand,
    bool clearHand = false,
    NiuniuPlayerStatus? status,
  }) {
    return NiuniuPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isAi: isAi ?? this.isAi,
      role: role ?? this.role,
      chips: chips ?? this.chips,
      betAmount: betAmount ?? this.betAmount,
      hand: clearHand ? null : (hand ?? this.hand),
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson({bool includeHand = true}) {
    return {
      'id': id,
      'name': name,
      'isAi': isAi,
      'role': role.name,
      'chips': chips,
      'betAmount': betAmount,
      'status': status.name,
      'hand': includeHand ? hand?.toJson() : null,
    };
  }

  static NiuniuPlayer fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'punter';
    final statusStr = json['status'] as String? ?? 'waiting';
    final handJson = json['hand'] as List?;
    return NiuniuPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isAi: json['isAi'] as bool? ?? false,
      role: NiuniuRole.values.firstWhere(
        (e) => e.name == roleStr,
        orElse: () => NiuniuRole.punter,
      ),
      chips: (json['chips'] as num?)?.toInt() ?? 0,
      betAmount: (json['betAmount'] as num?)?.toInt() ?? 0,
      status: NiuniuPlayerStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => NiuniuPlayerStatus.waiting,
      ),
      hand: handJson != null ? NiuniuHand.fromJson(handJson) : null,
    );
  }
}
