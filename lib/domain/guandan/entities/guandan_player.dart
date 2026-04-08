import 'guandan_card.dart';

/// 玩家完成顺序（头游/二游/三游/四游）
enum FinishRank { first, second, third, fourth }

/// 掼蛋玩家
class GuandanPlayer {
  final String id;
  final String name;
  final int avatarIndex;

  /// 队伍 ID：0 或 1（座位 0、2 为队伍 0；座位 1、3 为队伍 1）
  final int teamId;

  /// 手牌
  final List<GuandanCard> cards;

  /// 本局完成顺序（null 表示尚未打完）
  final FinishRank? finishRank;

  /// 是否为 AI 控制
  final bool isAi;

  /// 座位索引 0-3（顺时针：0=底部本地玩家，1=右侧，2=顶部，3=左侧）
  final int seatIndex;

  const GuandanPlayer({
    required this.id,
    required this.name,
    this.avatarIndex = 0,
    required this.teamId,
    this.cards = const [],
    this.finishRank,
    this.isAi = false,
    required this.seatIndex,
  });

  bool get hasFinished => finishRank != null;
  int get cardCount => cards.length;

  GuandanPlayer copyWith({
    String? id,
    String? name,
    int? avatarIndex,
    int? teamId,
    List<GuandanCard>? cards,
    FinishRank? finishRank,
    bool? isAi,
    int? seatIndex,
    bool clearFinishRank = false,
  }) {
    return GuandanPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      teamId: teamId ?? this.teamId,
      cards: cards ?? this.cards,
      finishRank: clearFinishRank ? null : (finishRank ?? this.finishRank),
      isAi: isAi ?? this.isAi,
      seatIndex: seatIndex ?? this.seatIndex,
    );
  }

  Map<String, dynamic> toJson({bool includeCards = true}) => {
        'id': id,
        'name': name,
        'avatarIndex': avatarIndex,
        'teamId': teamId,
        'cards': includeCards
            ? cards.map((c) => c.toId()).toList()
            : <String>[],
        'cardCount': cards.length,
        'finishRank': finishRank?.name,
        'isAi': isAi,
        'seatIndex': seatIndex,
      };

  static GuandanPlayer fromJson(
    Map<String, dynamic> json, {
    bool loadCards = true,
  }) {
    final cardIds = json['cards'] as List<dynamic>? ?? [];
    return GuandanPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarIndex: json['avatarIndex'] as int? ?? 0,
      teamId: json['teamId'] as int,
      cards: loadCards
          ? cardIds.map((id) => GuandanCard.fromId(id as String)).toList()
          : [],
      finishRank: json['finishRank'] == null
          ? null
          : FinishRank.values.firstWhere(
              (e) => e.name == json['finishRank'],
            ),
      isAi: json['isAi'] as bool? ?? false,
      seatIndex: json['seatIndex'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuandanPlayer &&
          id == other.id &&
          seatIndex == other.seatIndex &&
          teamId == other.teamId;

  @override
  int get hashCode => Object.hash(id, seatIndex, teamId);

  @override
  String toString() => 'GuandanPlayer($name, team=$teamId, cards=$cardCount)';
}
