import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';

/// 出牌用例
class PlayCardsUseCase {
  final CardValidator _validator;

  PlayCardsUseCase({CardValidator? validator})
      : _validator = validator ?? const CardValidator();

  /// 执行出牌
  GameState call(GameState state, String playerId, List<Card> cards) {
    final playerIndex = state.players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) {
      throw ArgumentError('玩家不存在');
    }

    if (playerIndex != state.currentPlayerIndex) {
      throw StateError('不是当前玩家的回合');
    }

    final player = state.players[playerIndex];

    // 验证手牌
    for (final card in cards) {
      if (!player.handCards.contains(card)) {
        throw ArgumentError('玩家手中没有这张牌: $card');
      }
    }

    // 验证牌型
    final combination = _validator.validate(cards);
    if (combination == null) {
      throw ArgumentError('无效的牌型');
    }

    // 验证是否打得过上家
    if (state.lastPlayedCards != null && state.lastPlayerIndex != playerIndex) {
      if (!_validator.canBeat(cards, state.lastPlayedCards!)) {
        throw ArgumentError('牌型不符合规则或打不过上家');
      }
    }

    // 移除手牌
    final newHandCards = player.handCards.where((c) => !cards.contains(c)).toList();
    player.handCards = newHandCards;

    // 更新状态
    final nextPlayerIndex = (playerIndex + 1) % state.players.length;

    return state.copyWith(
      lastPlayedCards: cards,
      lastPlayerIndex: playerIndex,
      currentPlayerIndex: nextPlayerIndex,
    );
  }

  /// 过牌
  GameState pass(GameState state, String playerId) {
    final playerIndex = state.players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) {
      throw ArgumentError('玩家不存在');
    }

    if (playerIndex != state.currentPlayerIndex) {
      throw StateError('不是当前玩家的回合');
    }

    // 如果是新一轮（上家就是自己），不能过牌
    if (state.lastPlayerIndex == playerIndex || state.lastPlayedCards == null) {
      throw StateError('新一轮必须出牌');
    }

    // 下一个玩家
    final nextPlayerIndex = (playerIndex + 1) % state.players.length;

    // 如果转了一圈回到上一个出牌者，清空桌面
    if (nextPlayerIndex == state.lastPlayerIndex) {
      return state.copyWith(
        currentPlayerIndex: nextPlayerIndex,
        clearLastPlayedCards: true,
        clearLastPlayerIndex: true,
      );
    }

    return state.copyWith(
      currentPlayerIndex: nextPlayerIndex,
    );
  }
}
