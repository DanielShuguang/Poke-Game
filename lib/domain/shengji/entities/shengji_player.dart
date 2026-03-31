import 'package:poke_game/domain/shengji/entities/shengji_card.dart';

/// 升级玩家实体
class ShengjiPlayer {
  /// 玩家 ID
  final String id;

  /// 玩家名称
  final String name;

  /// 队伍 ID（0 或 1）
  final int teamId;

  /// 手牌
  final List<ShengjiCard> hand;

  /// 是否是 AI
  final bool isAi;

  /// 座位索引（0-3，决定出牌顺序）
  final int seatIndex;

  /// 是否已准备
  final bool isReady;

  const ShengjiPlayer({
    required this.id,
    required this.name,
    required this.teamId,
    required this.hand,
    this.isAi = false,
    required this.seatIndex,
    this.isReady = false,
  });

  /// 是否是对家的队友（座位索引相差 2）
  bool isTeammateOf(int otherSeatIndex) {
    return (seatIndex + 2) % 4 == otherSeatIndex;
  }

  /// 复制并修改
  ShengjiPlayer copyWith({
    String? id,
    String? name,
    int? teamId,
    List<ShengjiCard>? hand,
    bool? isAi,
    int? seatIndex,
    bool? isReady,
  }) {
    return ShengjiPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      hand: hand ?? this.hand,
      isAi: isAi ?? this.isAi,
      seatIndex: seatIndex ?? this.seatIndex,
      isReady: isReady ?? this.isReady,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson({bool includeHand = true}) {
    return {
      'id': id,
      'name': name,
      'teamId': teamId,
      'hand': includeHand ? hand.map((c) => c.toJson()).toList() : [],
      'isAi': isAi,
      'seatIndex': seatIndex,
      'isReady': isReady,
    };
  }

  /// 从 JSON 反序列化
  static ShengjiPlayer fromJson(Map<String, dynamic> json, {bool loadHand = true}) {
    final handJson = json['hand'] as List<dynamic>? ?? [];
    return ShengjiPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      teamId: json['teamId'] as int? ?? 0,
      hand: loadHand
          ? handJson.map((c) => ShengjiCard.fromJson(c as Map<String, dynamic>)).toList()
          : [],
      isAi: json['isAi'] as bool? ?? false,
      seatIndex: json['seatIndex'] as int? ?? 0,
      isReady: json['isReady'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShengjiPlayer &&
          id == other.id &&
          teamId == other.teamId &&
          seatIndex == other.seatIndex;

  @override
  int get hashCode => Object.hash(id, teamId, seatIndex);

  @override
  String toString() => 'ShengjiPlayer($name, 队伍$teamId, 座位$seatIndex)';
}
