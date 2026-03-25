import 'dart:convert';
import 'package:poke_game/domain/texas_holdem/usecases/betting_usecases.dart';

/// 德州扑克网络动作类型
enum HoldemNetworkActionType {
  fold,
  check,
  call,
  raise,
  allIn,
}

/// 德州扑克网络动作消息
class HoldemNetworkAction {
  final String playerId;
  final HoldemNetworkActionType type;
  final int? raiseAmount; // 仅 raise 时使用
  final DateTime timestamp;

  const HoldemNetworkAction({
    required this.playerId,
    required this.type,
    this.raiseAmount,
    required this.timestamp,
  });

  factory HoldemNetworkAction.fromJson(Map<String, dynamic> json) {
    return HoldemNetworkAction(
      playerId: json['playerId'] as String,
      type: HoldemNetworkActionType.values.firstWhere(
        (t) => t.name == json['type'],
      ),
      raiseAmount: json['raiseAmount'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'type': type.name,
        if (raiseAmount != null) 'raiseAmount': raiseAmount,
        'timestamp': timestamp.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  /// 转换为本地 BettingAction
  BettingAction toBettingAction() {
    switch (type) {
      case HoldemNetworkActionType.fold:
        return const FoldAction();
      case HoldemNetworkActionType.check:
        return const CheckAction();
      case HoldemNetworkActionType.call:
        return const CallAction();
      case HoldemNetworkActionType.raise:
        return RaiseAction(raiseAmount!);
      case HoldemNetworkActionType.allIn:
        return const AllInAction();
    }
  }

  static HoldemNetworkAction fromBettingAction(
    String playerId,
    BettingAction action,
  ) {
    return switch (action) {
      FoldAction() => HoldemNetworkAction(
          playerId: playerId,
          type: HoldemNetworkActionType.fold,
          timestamp: DateTime.now(),
        ),
      CheckAction() => HoldemNetworkAction(
          playerId: playerId,
          type: HoldemNetworkActionType.check,
          timestamp: DateTime.now(),
        ),
      CallAction() => HoldemNetworkAction(
          playerId: playerId,
          type: HoldemNetworkActionType.call,
          timestamp: DateTime.now(),
        ),
      RaiseAction(:final totalBet) => HoldemNetworkAction(
          playerId: playerId,
          type: HoldemNetworkActionType.raise,
          raiseAmount: totalBet,
          timestamp: DateTime.now(),
        ),
      AllInAction() => HoldemNetworkAction(
          playerId: playerId,
          type: HoldemNetworkActionType.allIn,
          timestamp: DateTime.now(),
        ),
    };
  }
}

/// 消息类型常量
class HoldemMessageType {
  static const String action = 'holdem_action';
  static const String stateSync = 'holdem_state_sync';
  static const String gameStart = 'holdem_game_start';
  static const String playerTimeout = 'holdem_player_timeout';
}
