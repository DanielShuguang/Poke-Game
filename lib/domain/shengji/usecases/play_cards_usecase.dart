import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/entities/shengji_player.dart';
import 'package:poke_game/domain/shengji/entities/trump_info.dart';
import 'package:poke_game/domain/shengji/validators/play_validator.dart';

/// 出牌用例
class PlayCardsUseCase {
  /// 执行出牌
  PlayResult play({
    required ShengjiGameState state,
    required String playerId,
    required List<ShengjiCard> cards,
  }) {
    final player = state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) {
      return PlayResult.error('玩家不存在');
    }

    if (state.trumpInfo == null) {
      return PlayResult.error('将牌未确定');
    }

    // 检查是否轮到该玩家
    if (state.currentSeatIndex != player.seatIndex) {
      return PlayResult.error('未轮到该玩家出牌');
    }

    // 验证出牌
    final leadCards = state.currentRound?.leadCards ?? [];
    final validation = PlayValidator.validate(
      hand: player.hand,
      playedCards: cards,
      leadCards: leadCards,
      trumpInfo: state.trumpInfo!,
    );

    if (!validation.isValid) {
      return PlayResult.error(validation.errorMessage);
    }

    // 从手牌移除已出的牌
    final newHand = List<ShengjiCard>.from(player.hand);
    for (final card in cards) {
      newHand.remove(card);
    }

    // 更新玩家
    final newPlayers = state.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(hand: newHand);
      }
      return p;
    }).toList();

    // 更新出牌轮
    final newRound = _updateRound(state, player.seatIndex, cards);

    return PlayResult.success(
      players: newPlayers,
      currentRound: newRound,
    );
  }

  /// 更新出牌轮
  PlayRound? _updateRound(
    ShengjiGameState state,
    int seatIndex,
    List<ShengjiCard> cards,
  ) {
    if (state.currentRound == null) {
      // 首出
      return PlayRound(
        leadSeatIndex: seatIndex,
        leadCards: cards,
        plays: {seatIndex: cards},
      );
    }

    // 跟牌
    final newPlays = Map<int, List<ShengjiCard>>.from(state.currentRound!.plays);
    newPlays[seatIndex] = cards;

    // 检查是否所有人都已出牌
    if (newPlays.length == 4) {
      // 确定赢家
      final winnerSeatIndex = _determineWinner(
        state.currentRound!,
        newPlays,
        state.trumpInfo!,
      );
      return state.currentRound!.copyWith(
        plays: newPlays,
        winnerSeatIndex: winnerSeatIndex,
      );
    }

    return state.currentRound!.copyWith(plays: newPlays);
  }

  /// 确定一轮赢家
  int _determineWinner(
    PlayRound round,
    Map<int, List<ShengjiCard>> plays,
    TrumpInfo trumpInfo,
  ) {
    int winnerSeat = round.leadSeatIndex;
    List<ShengjiCard> winningCards = plays[round.leadSeatIndex]!;

    for (final entry in plays.entries) {
      if (entry.key == round.leadSeatIndex) continue;

      final comparison = PlayValidator.compare(
        a: entry.value,
        b: winningCards,
        leadCards: round.leadCards,
        trumpInfo: trumpInfo,
      );

      if (comparison > 0) {
        winnerSeat = entry.key;
        winningCards = entry.value;
      }
    }

    return winnerSeat;
  }

  /// 计算下一个出牌玩家
  int getNextSeatIndex(ShengjiGameState state, PlayRound? newRound) {
    if (newRound == null || newRound.winnerSeatIndex == null) {
      // 继续出牌
      return (state.currentSeatIndex + 1) % 4;
    }
    // 新一轮，赢家首出
    return newRound.winnerSeatIndex!;
  }
}

/// 出牌结果
class PlayResult {
  final bool success;
  final String? errorMessage;
  final List<ShengjiPlayer>? players;
  final PlayRound? currentRound;

  const PlayResult.success({
    this.players,
    this.currentRound,
  })  : success = true,
        errorMessage = null;

  const PlayResult.error(this.errorMessage)
      : success = false,
        players = null,
        currentRound = null;
}
