import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/entities/trump_info.dart';
import 'package:poke_game/domain/shengji/validators/call_validator.dart';

/// 叫牌用例
class CallTrumpUseCase {
  /// 执行叫牌
  CallResult call({
    required ShengjiGameState state,
    required String playerId,
    required TrumpCall call,
  }) {
    final player = state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) {
      return CallResult.error('玩家不存在');
    }

    // 验证叫牌
    if (!CallValidator.validate(hand: player.hand, call: call)) {
      return CallResult.error('无效叫牌');
    }

    // 检查是否轮到该玩家叫牌
    if (state.currentSeatIndex != player.seatIndex) {
      return CallResult.error('未轮到该玩家叫牌');
    }

    // 更新叫牌历史
    final newCallHistory = Map<String, String>.from(state.callHistory);
    newCallHistory[playerId] = call.toString();

    // 创建将牌信息
    final trumpInfo = _createTrumpInfo(call, state);

    // 确定庄家（叫牌成功的玩家）
    final dealerId = playerId;

    // 计算下一个叫牌玩家
    final nextSeatIndex = (player.seatIndex + 1) % 4;

    // 检查是否所有玩家都已叫牌或跳过
    final allCalledOrPassed = newCallHistory.length >= 4 ||
        _hasWinningCall(newCallHistory);

    return CallResult.success(
      callHistory: newCallHistory,
      trumpInfo: trumpInfo,
      dealerId: dealerId,
      nextSeatIndex: nextSeatIndex,
      callComplete: allCalledOrPassed,
    );
  }

  /// 跳过叫牌
  CallResult pass({
    required ShengjiGameState state,
    required String playerId,
  }) {
    final player = state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) {
      return CallResult.error('玩家不存在');
    }

    // 更新叫牌历史
    final newCallHistory = Map<String, String>.from(state.callHistory);
    newCallHistory[playerId] = '不叫';

    // 计算下一个叫牌玩家
    final nextSeatIndex = (player.seatIndex + 1) % 4;

    // 检查是否所有玩家都已叫牌或跳过
    final allCalledOrPassed = newCallHistory.length >= 4;

    // 如果所有人都跳过，随机选择庄家
    String? dealerId;
    TrumpInfo? trumpInfo;
    if (allCalledOrPassed && !newCallHistory.values.any(
          (v) => v == '对子' || v == '拖拉机' || v == '无将')) {
      // 所有人都不叫，随机选庄家和将牌
      dealerId = state.players[player.seatIndex].id;
      trumpInfo = TrumpInfo(
        trumpSuit: null, // 无将
        rankLevel: state.teams.firstWhere((t) => t.id == player.teamId).currentLevel,
      );
    }

    return CallResult.success(
      callHistory: newCallHistory,
      trumpInfo: trumpInfo,
      dealerId: dealerId,
      nextSeatIndex: nextSeatIndex,
      callComplete: allCalledOrPassed,
    );
  }

  /// 创建将牌信息
  TrumpInfo _createTrumpInfo(TrumpCall call, ShengjiGameState state) {
    // 获取庄家队的当前级别
    final dealerTeam = state.teams.first; // 简化处理
    final level = dealerTeam.currentLevel;

    return TrumpInfo(
      trumpSuit: call.suit,
      rankLevel: level,
    );
  }

  /// 检查是否有获胜的叫牌
  bool _hasWinningCall(Map<String, String> callHistory) {
    return callHistory.values.any((v) =>
        v.contains('对子') || v.contains('拖拉机') || v.contains('无将'));
  }
}

/// 叫牌结果
class CallResult {
  final bool success;
  final String? errorMessage;
  final Map<String, String>? callHistory;
  final TrumpInfo? trumpInfo;
  final String? dealerId;
  final int? nextSeatIndex;
  final bool callComplete;

  const CallResult.success({
    this.callHistory,
    this.trumpInfo,
    this.dealerId,
    this.nextSeatIndex,
    this.callComplete = false,
  })  : success = true,
        errorMessage = null;

  const CallResult.error(this.errorMessage)
      : success = false,
        callHistory = null,
        trumpInfo = null,
        dealerId = null,
        nextSeatIndex = null,
        callComplete = false;
}
