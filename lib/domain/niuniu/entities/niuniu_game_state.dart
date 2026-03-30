import 'package:poke_game/domain/niuniu/entities/niuniu_card.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_player.dart';

/// 斗牛游戏阶段
enum NiuniuPhase {
  /// 下注阶段
  betting,

  /// 发牌中
  dealing,

  /// 翻牌比较阶段
  showdown,

  /// 结算阶段
  settlement,
}

/// 斗牛游戏全局状态
class NiuniuGameState {
  /// 当前牌堆（剩余牌，Host 维护）
  final List<NiuniuCard> deck;

  /// 庄家玩家ID
  final String bankerId;

  /// 所有玩家（含庄家和闲家）
  final List<NiuniuPlayer> players;

  /// 当前等待下注的玩家索引（betting 阶段使用）
  final int currentBettingIndex;

  /// 游戏阶段
  final NiuniuPhase phase;

  /// 提示消息（UI 用）
  final String? message;

  const NiuniuGameState({
    required this.deck,
    required this.bankerId,
    required this.players,
    this.currentBettingIndex = 0,
    required this.phase,
    this.message,
  });

  factory NiuniuGameState.initial() => const NiuniuGameState(
        deck: [],
        bankerId: '',
        players: [],
        phase: NiuniuPhase.betting,
      );

  NiuniuPlayer? get banker =>
      players.where((p) => p.id == bankerId).firstOrNull;

  List<NiuniuPlayer> get punters =>
      players.where((p) => p.isPunter).toList();

  /// 当前等待下注的闲家（betting 阶段）
  NiuniuPlayer? get currentBettingPlayer {
    final pList = punters.where((p) => p.status == NiuniuPlayerStatus.waiting).toList();
    return pList.isEmpty ? null : pList.first;
  }

  /// 所有闲家已完成下注
  bool get allPuntersBet =>
      punters.every((p) => p.status == NiuniuPlayerStatus.bet || p.status == NiuniuPlayerStatus.broke);

  NiuniuGameState copyWith({
    List<NiuniuCard>? deck,
    String? bankerId,
    List<NiuniuPlayer>? players,
    int? currentBettingIndex,
    NiuniuPhase? phase,
    String? message,
    bool clearMessage = false,
  }) {
    return NiuniuGameState(
      deck: deck ?? List.of(this.deck),
      bankerId: bankerId ?? this.bankerId,
      players: players ?? List.of(this.players),
      currentBettingIndex:
          currentBettingIndex ?? this.currentBettingIndex,
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  /// 序列化
  /// [includeAllCards] = true：包含全部手牌（showdown/settlement 广播用）
  Map<String, dynamic> toJson({bool includeAllCards = false}) {
    final showHands = includeAllCards ||
        phase == NiuniuPhase.showdown ||
        phase == NiuniuPhase.settlement;
    return {
      'phase': phase.name,
      'bankerId': bankerId,
      'currentBettingIndex': currentBettingIndex,
      'message': message,
      'players': players.map((p) => p.toJson(includeHand: showHands)).toList(),
    };
  }

  /// 反序列化
  /// [localPlayerId] 指定本地玩家，其余玩家手牌在 showdown 前置空
  static NiuniuGameState fromJson(
    Map<String, dynamic> json, {
    String? localPlayerId,
  }) {
    final phaseStr = json['phase'] as String? ?? 'betting';
    final phase = NiuniuPhase.values.firstWhere(
      (e) => e.name == phaseStr,
      orElse: () => NiuniuPhase.betting,
    );
    final showHands =
        phase == NiuniuPhase.showdown || phase == NiuniuPhase.settlement;

    final playersJson =
        (json['players'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final players = playersJson.map((pJson) {
      final player = NiuniuPlayer.fromJson(pJson);
      // 非本地玩家，在 showdown 前清除手牌
      if (!showHands && localPlayerId != null && player.id != localPlayerId) {
        return player.copyWith(clearHand: true);
      }
      return player;
    }).toList();

    return NiuniuGameState(
      deck: const [], // 客户端不维护牌堆
      bankerId: json['bankerId'] as String? ?? '',
      players: players,
      currentBettingIndex:
          (json['currentBettingIndex'] as num?)?.toInt() ?? 0,
      phase: phase,
      message: json['message'] as String?,
    );
  }
}
