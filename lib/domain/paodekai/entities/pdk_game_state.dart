import 'pdk_hand_type.dart';
import 'pdk_player.dart';

enum PdkGamePhase { waiting, dealing, playing, roundEnd, gameOver }

class PdkGameState {
  final List<PdkPlayer> players;
  final int currentPlayerIndex;
  final PdkPlayedHand? lastPlayedHand;
  final int passCount;
  final PdkGamePhase phase;

  /// 出完顺序，game_over 时填充
  final List<String> rankings;

  /// 是否是游戏第一手（用于 ♠3 校验）
  final bool isFirstPlay;

  /// 最后出牌的玩家下标（null 表示新一轮尚未有人出牌）
  final int? lastPlayedPlayerIndex;

  const PdkGameState({
    required this.players,
    this.currentPlayerIndex = 0,
    this.lastPlayedHand,
    this.passCount = 0,
    required this.phase,
    this.rankings = const [],
    this.isFirstPlay = true,
    this.lastPlayedPlayerIndex,
  });

  factory PdkGameState.initial() => const PdkGameState(
        players: [],
        phase: PdkGamePhase.waiting,
      );

  PdkPlayer get currentPlayer => players[currentPlayerIndex];

  PdkGameState copyWith({
    List<PdkPlayer>? players,
    int? currentPlayerIndex,
    PdkPlayedHand? lastPlayedHand,
    bool clearLastHand = false,
    int? passCount,
    PdkGamePhase? phase,
    List<String>? rankings,
    bool? isFirstPlay,
    int? lastPlayedPlayerIndex,
  }) {
    return PdkGameState(
      players: players ?? List.of(this.players),
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      lastPlayedHand:
          clearLastHand ? null : (lastPlayedHand ?? this.lastPlayedHand),
      passCount: passCount ?? this.passCount,
      phase: phase ?? this.phase,
      rankings: rankings ?? List.of(this.rankings),
      isFirstPlay: isFirstPlay ?? this.isFirstPlay,
      lastPlayedPlayerIndex:
          clearLastHand ? null : (lastPlayedPlayerIndex ?? this.lastPlayedPlayerIndex),
    );
  }

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'currentPlayerIndex': currentPlayerIndex,
        'passCount': passCount,
        'isFirstPlay': isFirstPlay,
        'rankings': rankings,
        'lastPlayedHand': lastPlayedHand?.toJson(),
        'lastPlayedPlayerIndex': lastPlayedPlayerIndex,
        'players': players.map((p) => p.toJson()).toList(),
      };

  static PdkGameState fromJson(Map<String, dynamic> json) {
    final phase = PdkGamePhase.values.firstWhere(
      (e) => e.name == json['phase'],
      orElse: () => PdkGamePhase.waiting,
    );
    final lastHandJson = json['lastPlayedHand'] as Map<String, dynamic>?;
    return PdkGameState(
      phase: phase,
      currentPlayerIndex:
          (json['currentPlayerIndex'] as num?)?.toInt() ?? 0,
      passCount: (json['passCount'] as num?)?.toInt() ?? 0,
      isFirstPlay: json['isFirstPlay'] as bool? ?? true,
      rankings: (json['rankings'] as List? ?? []).cast<String>(),
      lastPlayedHand:
          lastHandJson != null ? PdkPlayedHand.fromJson(lastHandJson) : null,
      lastPlayedPlayerIndex:
          (json['lastPlayedPlayerIndex'] as num?)?.toInt(),
      players: (json['players'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PdkPlayer.fromJson)
          .toList(),
    );
  }
}
