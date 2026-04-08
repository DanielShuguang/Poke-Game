import '../entities/guandan_card.dart';
import '../entities/guandan_game_state.dart';
import '../entities/guandan_hand.dart';
import '../entities/guandan_player.dart';
import '../usecases/hint_usecase.dart';
import '../usecases/validate_hand_usecase.dart';

/// AI 行动结果
sealed class GuandanAction {
  const GuandanAction();
}

class PlayCardsAction extends GuandanAction {
  final List<GuandanCard> cards;
  const PlayCardsAction(this.cards);
}

class PassAction extends GuandanAction {
  const PassAction();
}

class TributeAction extends GuandanAction {
  final GuandanCard card;
  const TributeAction(this.card);
}

class ReturnTributeAction extends GuandanAction {
  final GuandanCard card;
  const ReturnTributeAction(this.card);
}

/// 规则+优先级 AI 策略
class GuandanAiStrategy {
  const GuandanAiStrategy();

  GuandanAction decideAction(GuandanGameState state, String playerId) {
    final player = state.getPlayerById(playerId);
    if (player == null) return const PassAction();

    final level = state.levelForTeam(player.teamId);

    // 贡牌阶段
    if (state.phase == GuandanPhase.tribute) {
      return _decideTribute(player);
    }

    // 还贡阶段
    if (state.phase == GuandanPhase.returnTribute) {
      return _decideReturnTribute(player);
    }

    // 出牌阶段
    return _decidePlay(state, player, level);
  }

  // ──────────────────────────────────────────────────────────────
  // 贡牌逻辑
  // ──────────────────────────────────────────────────────────────

  GuandanAction _decideTribute(GuandanPlayer player) {
    // 自动选手牌中最大的单张进贡
    final normalCards = player.cards
        .where((c) => !c.isJoker)
        .toList()
      ..sort((a, b) => b.rank!.compareTo(a.rank!));

    if (normalCards.isEmpty) return TributeAction(player.cards.first);
    return TributeAction(normalCards.first);
  }

  GuandanAction _decideReturnTribute(GuandanPlayer player) {
    // 自动选手牌中最小的单张作为还贡
    final normalCards = player.cards
        .where((c) => !c.isJoker)
        .toList()
      ..sort((a, b) => a.rank!.compareTo(b.rank!));

    if (normalCards.isEmpty) return ReturnTributeAction(player.cards.first);
    return ReturnTributeAction(normalCards.first);
  }

  // ──────────────────────────────────────────────────────────────
  // 出牌逻辑
  // ──────────────────────────────────────────────────────────────

  GuandanAction _decidePlay(
    GuandanGameState state,
    GuandanPlayer player,
    int level,
  ) {
    final hand = player.cards;
    final lastPlayed = state.lastPlayedHand;

    // 队友正在领先 → pass（保留炸弹）
    if (lastPlayed != null && _isTeammateLeading(state, player)) {
      return const PassAction();
    }

    // 获取所有可出的组合
    final hints = HintUsecase.hint(hand, lastPlayed, level);

    if (hints.isEmpty) {
      // 首出时不能 pass，兜底出第一张牌
      if (lastPlayed == null && hand.isNotEmpty) {
        return PlayCardsAction([hand.first]);
      }
      return const PassAction();
    }

    if (lastPlayed == null) {
      // 首出：优先出最小单张（保留连牌和炸弹）
      return _decideLeadPlay(hand, hints, level);
    }

    // 跟牌：选能压制且消耗最小的非炸弹组合
    return _decideFollowPlay(hints, level, lastPlayed);
  }

  /// 首出策略：优先出最小单张，手牌全为连牌时出最长组合
  GuandanAction _decideLeadPlay(
    List<GuandanCard> hand,
    List<List<GuandanCard>> hints,
    int level,
  ) {
    // 优先找最小单张（非王、非级牌）
    final singleHints = hints.where((h) {
      if (h.length != 1) return false;
      final c = h[0];
      if (c.isJoker) return false;
      return true;
    }).toList();

    if (singleHints.isNotEmpty) {
      // 按点数升序，出最小单张
      singleHints.sort((a, b) => a[0].rank!.compareTo(b[0].rank!));
      return PlayCardsAction(singleHints.first);
    }

    // 没有单张 → 出最长的非炸弹组合
    final nonBombHints = hints.where((h) {
      final validated = ValidateHandUsecase.validate(h, level);
      return validated != null && !validated.isBomb;
    }).toList();

    if (nonBombHints.isNotEmpty) {
      nonBombHints.sort((a, b) => b.length.compareTo(a.length));
      return PlayCardsAction(nonBombHints.first);
    }

    // 只有炸弹 → 出最小的炸弹
    return PlayCardsAction(hints.first);
  }

  /// 跟牌策略：选消耗最小的能压制组合
  GuandanAction _decideFollowPlay(
    List<List<GuandanCard>> hints,
    int level,
    GuandanHand lastPlayed,
  ) {
    // 优先尝试非炸弹组合
    final nonBombHints = hints.where((h) {
      final validated = ValidateHandUsecase.validate(h, level);
      return validated != null && !validated.isBomb;
    }).toList();

    if (nonBombHints.isNotEmpty) {
      // hints 已按"消耗最小"排序（HintUsecase 保证）
      return PlayCardsAction(nonBombHints.first);
    }

    // 只有炸弹可以跟牌 → 保守策略：使用最小炸弹
    if (hints.isNotEmpty) {
      return PlayCardsAction(hints.first);
    }

    return const PassAction();
  }

  // ──────────────────────────────────────────────────────────────
  // 队友检测
  // ──────────────────────────────────────────────────────────────

  bool _isTeammateLeading(GuandanGameState state, GuandanPlayer player) {
    final lastPlayerIndex = state.lastPlayerIndex;
    if (lastPlayerIndex == null) return false;
    if (lastPlayerIndex == player.seatIndex) return false;

    final lastPlayer = state.players[lastPlayerIndex];
    return lastPlayer.teamId == player.teamId;
  }
}
