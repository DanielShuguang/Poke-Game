/// 游戏模式
enum GameMode {
  /// 单机人机对战
  singlePlayer,

  /// 局域网多人对战
  lanMultiplayer,
}

/// 游戏配置
class GameConfig {
  /// 玩家数量
  final int playerCount;

  /// 底牌数量
  final int landlordCardCount;

  /// 每人初始手牌数量
  final int initialCardCount;

  /// AI 思考延迟（毫秒）
  final int aiThinkDelayMs;

  /// 是否为人机对战模式
  /// - 人机模式：玩家选择"不叫"后，最后一个AI必须叫地主
  /// - 非人机模式：所有玩家都可以选择"不叫"，全部不叫时重新发牌
  final bool isHumanVsAi;

  /// 游戏模式
  final GameMode gameMode;

  /// 房间ID（局域网模式）
  final String? roomId;

  /// 当前玩家ID（局域网模式）
  final String? currentPlayerId;

  const GameConfig({
    this.playerCount = 3,
    this.landlordCardCount = 3,
    this.initialCardCount = 17,
    this.aiThinkDelayMs = 1500,
    this.isHumanVsAi = true,
    this.gameMode = GameMode.singlePlayer,
    this.roomId,
    this.currentPlayerId,
  });

  /// 默认配置（人机对战模式）
  static const GameConfig defaultConfig = GameConfig();

  /// 局域网多人模式配置
  static GameConfig lanMode({
    required String roomId,
    required String currentPlayerId,
  }) {
    return GameConfig(
      playerCount: 3,
      isHumanVsAi: false,
      gameMode: GameMode.lanMultiplayer,
      roomId: roomId,
      currentPlayerId: currentPlayerId,
    );
  }

  /// 是否是局域网模式
  bool get isLanMode => gameMode == GameMode.lanMultiplayer;

  /// 是否是单机模式
  bool get isSinglePlayer => gameMode == GameMode.singlePlayer;

  GameConfig copyWith({
    int? playerCount,
    int? landlordCardCount,
    int? initialCardCount,
    int? aiThinkDelayMs,
    bool? isHumanVsAi,
    GameMode? gameMode,
    String? roomId,
    String? currentPlayerId,
  }) {
    return GameConfig(
      playerCount: playerCount ?? this.playerCount,
      landlordCardCount: landlordCardCount ?? this.landlordCardCount,
      initialCardCount: initialCardCount ?? this.initialCardCount,
      aiThinkDelayMs: aiThinkDelayMs ?? this.aiThinkDelayMs,
      isHumanVsAi: isHumanVsAi ?? this.isHumanVsAi,
      gameMode: gameMode ?? this.gameMode,
      roomId: roomId ?? this.roomId,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
    );
  }
}
