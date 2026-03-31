import 'dart:math';
import 'package:poke_game/domain/shengji/entities/shengji_card.dart';
import 'package:poke_game/domain/shengji/entities/shengji_player.dart';

/// 发牌用例
class DealCardsUseCase {
  /// 发牌
  /// 返回 (玩家手牌列表, 底牌)
  DealResult deal({
    required List<String> playerIds,
    required List<String> playerNames,
    required List<int> teamIds,
    required List<int> seatIndices,
    int bottomCardsCount = 8,
  }) {
    assert(playerIds.length == 4, '升级需要 4 名玩家');

    final random = Random();
    final deck = ShengjiCard.fullDeck()..shuffle(random);

    // 分配手牌（每人 25 张）
    final playerHands = <String, List<ShengjiCard>>{};
    int cardIndex = 0;
    for (int i = 0; i < 4; i++) {
      final hand = deck.sublist(cardIndex, cardIndex + 25);
      cardIndex += 25;
      playerHands[playerIds[i]] = hand;
    }

    // 底牌（8 张）
    final bottomCards = deck.sublist(cardIndex, cardIndex + bottomCardsCount);

    // 创建玩家列表
    final players = <ShengjiPlayer>[];
    for (int i = 0; i < 4; i++) {
      players.add(ShengjiPlayer(
        id: playerIds[i],
        name: playerNames[i],
        teamId: teamIds[i],
        hand: playerHands[playerIds[i]]!,
        seatIndex: seatIndices[i],
      ));
    }

    // 按座位索引排序
    players.sort((a, b) => a.seatIndex.compareTo(b.seatIndex));

    return DealResult(
      players: players,
      bottomCards: bottomCards,
    );
  }
}

/// 发牌结果
class DealResult {
  final List<ShengjiPlayer> players;
  final List<ShengjiCard> bottomCards;

  const DealResult({
    required this.players,
    required this.bottomCards,
  });
}
