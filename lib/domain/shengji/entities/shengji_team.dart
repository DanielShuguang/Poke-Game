/// 升级队伍实体
class ShengjiTeam {
  /// 队伍 ID（0 或 1）
  final int id;

  /// 玩家 ID 列表（2名玩家）
  final List<String> playerIds;

  /// 当前级别（2-14，对应 2-A）
  final int currentLevel;

  /// 本局得分
  final int roundScore;

  /// 是否是庄家队
  final bool isDealer;

  const ShengjiTeam({
    required this.id,
    required this.playerIds,
    this.currentLevel = 2,
    this.roundScore = 0,
    this.isDealer = false,
  });

  /// 级别显示名称
  String get levelName {
    switch (currentLevel) {
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      case 14:
        return 'A';
      default:
        return currentLevel.toString();
    }
  }

  /// 是否已完成 A 级
  bool get hasCompletedLevelA => currentLevel > 14;

  /// 复制并修改
  ShengjiTeam copyWith({
    int? id,
    List<String>? playerIds,
    int? currentLevel,
    int? roundScore,
    bool? isDealer,
  }) {
    return ShengjiTeam(
      id: id ?? this.id,
      playerIds: playerIds ?? this.playerIds,
      currentLevel: currentLevel ?? this.currentLevel,
      roundScore: roundScore ?? this.roundScore,
      isDealer: isDealer ?? this.isDealer,
    );
  }

  /// 升级
  ShengjiTeam upgrade(int levels) {
    var newLevel = currentLevel + levels;
    // A 级后循环回 2
    if (newLevel > 14) {
      newLevel = 2 + (newLevel - 15);
    }
    return copyWith(currentLevel: newLevel);
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerIds': playerIds,
      'currentLevel': currentLevel,
      'roundScore': roundScore,
      'isDealer': isDealer,
    };
  }

  /// 从 JSON 反序列化
  static ShengjiTeam fromJson(Map<String, dynamic> json) {
    return ShengjiTeam(
      id: json['id'] as int? ?? 0,
      playerIds: (json['playerIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      currentLevel: json['currentLevel'] as int? ?? 2,
      roundScore: json['roundScore'] as int? ?? 0,
      isDealer: json['isDealer'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShengjiTeam &&
          id == other.id &&
          currentLevel == other.currentLevel &&
          roundScore == other.roundScore &&
          isDealer == other.isDealer;

  @override
  int get hashCode => Object.hash(id, currentLevel, roundScore, isDealer);

  @override
  String toString() => 'ShengjiTeam($id, 级别$levelName, 得分$roundScore, ${isDealer ? "庄家" : "防守"} )';
}
