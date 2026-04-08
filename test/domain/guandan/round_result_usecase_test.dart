import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/guandan/entities/guandan_game_state.dart';
import 'package:poke_game/domain/guandan/entities/guandan_player.dart';
import 'package:poke_game/domain/guandan/usecases/round_result_usecase.dart';

GuandanPlayer player(String id, int teamId, int seat, FinishRank? rank) =>
    GuandanPlayer(
      id: id,
      name: id,
      teamId: teamId,
      seatIndex: seat,
      finishRank: rank,
    );

GuandanGameState stateWith(
  List<GuandanPlayer> players, {
  int t0Level = 2,
  int t1Level = 2,
}) {
  return GuandanGameState(
    phase: GuandanPhase.playing,
    players: players,
    team0Level: t0Level,
    team1Level: t1Level,
    currentPlayerIndex: 0,
  );
}

void main() {
  group('己方包揽头游二游，升2级', () {
    test('队伍0包揽 → 队伍0升2，队伍1降2', () {
      final state = stateWith([
        player('p0', 0, 0, FinishRank.first),
        player('p1', 0, 2, FinishRank.second),
        player('p2', 1, 1, FinishRank.third),
        player('p3', 1, 3, FinishRank.fourth),
      ]);
      final result = RoundResultUsecase.calculate(state);
      expect(result.team0Level, 4); // 2 + 2
      expect(result.team1Level, 2); // 2 - 2 = 0 → clamped to 2
      expect(result.roundResult?.team0LevelDelta, 2);
      expect(result.roundResult?.team1LevelDelta, -2);
      expect(result.roundResult?.winnerTeamId, 0);
    });

    test('队伍1包揽 → 队伍1升2，队伍0降2', () {
      final state = stateWith([
        player('p0', 1, 1, FinishRank.first),
        player('p1', 1, 3, FinishRank.second),
        player('p2', 0, 0, FinishRank.third),
        player('p3', 0, 2, FinishRank.fourth),
      ]);
      final result = RoundResultUsecase.calculate(state);
      expect(result.team1Level, 4);
      expect(result.team0Level, 2); // clamped
    });
  });

  group('己方头游、对方二游，升1级', () {
    test('队伍0头游，队伍1二游 → 队伍0升1', () {
      final state = stateWith([
        player('p0', 0, 0, FinishRank.first),
        player('p1', 1, 1, FinishRank.second),
        player('p2', 0, 2, FinishRank.third),
        player('p3', 1, 3, FinishRank.fourth),
      ]);
      final result = RoundResultUsecase.calculate(state);
      expect(result.team0Level, 3); // 2 + 1
      expect(result.team1Level, 2); // 不变
      expect(result.roundResult?.team0LevelDelta, 1);
      expect(result.roundResult?.team1LevelDelta, 0);
    });
  });

  group('对方头游、己方二游，头游队升1级', () {
    test('队伍1头游，队伍0二游 → 队伍1升1，队伍0不变', () {
      final state = stateWith([
        player('p0', 1, 1, FinishRank.first),
        player('p1', 0, 0, FinishRank.second),
        player('p2', 1, 3, FinishRank.third),
        player('p3', 0, 2, FinishRank.fourth),
      ]);
      final result = RoundResultUsecase.calculate(state);
      expect(result.team1Level, 3); // 2 + 1（头游队升1）
      expect(result.team0Level, 2); // 不变
      expect(result.roundResult?.team1LevelDelta, 1);
      expect(result.roundResult?.team0LevelDelta, 0);
    });
  });

  group('升到A后继续赢，游戏结束', () {
    test('已在A级，再次包揽 → finished', () {
      final state = stateWith(
        [
          player('p0', 0, 0, FinishRank.first),
          player('p1', 0, 2, FinishRank.second),
          player('p2', 1, 1, FinishRank.third),
          player('p3', 1, 3, FinishRank.fourth),
        ],
        t0Level: 14, // 已在A级
      );
      final result = RoundResultUsecase.calculate(state);
      expect(result.phase, GuandanPhase.finished);
    });

    test('未到A级，不触发结束', () {
      final state = stateWith([
        player('p0', 0, 0, FinishRank.first),
        player('p1', 0, 2, FinishRank.second),
        player('p2', 1, 1, FinishRank.third),
        player('p3', 1, 3, FinishRank.fourth),
      ]);
      final result = RoundResultUsecase.calculate(state);
      expect(result.phase, GuandanPhase.settling);
    });
  });

  group('级牌边界', () {
    test('level 最低为2（不会降到2以下）', () {
      final state = stateWith(
        [
          player('p0', 0, 0, FinishRank.first),
          player('p1', 0, 2, FinishRank.second),
          player('p2', 1, 1, FinishRank.third),
          player('p3', 1, 3, FinishRank.fourth),
        ],
        t1Level: 2, // 已在最低级
      );
      final result = RoundResultUsecase.calculate(state);
      expect(result.team1Level, 2); // clamp(2-2, 2, 14) = 2
    });

    test('level 最高为A(14)（不会超过14）', () {
      final state = stateWith(
        [
          player('p0', 0, 0, FinishRank.first),
          player('p1', 0, 2, FinishRank.second),
          player('p2', 1, 1, FinishRank.third),
          player('p3', 1, 3, FinishRank.fourth),
        ],
        t0Level: 13, // K级，再升2级 → 应 clamp 到14
      );
      final result = RoundResultUsecase.calculate(state);
      expect(result.team0Level, 14); // clamp(13+2, 2, 14) = 14
    });
  });

  group('贡牌判断', () {
    test('包揽时需要贡牌', () {
      final state = stateWith([
        player('p0', 0, 0, FinishRank.first),
        player('p1', 0, 2, FinishRank.second),
        player('p2', 1, 1, FinishRank.third),
        player('p3', 1, 3, FinishRank.fourth),
      ]);
      final result = RoundResultUsecase.calculate(state);
      expect(RoundResultUsecase.needsTribute(result), isTrue);
    });

    test('头二游分属两队时不需要贡牌', () {
      final state = stateWith([
        player('p0', 0, 0, FinishRank.first),
        player('p1', 1, 1, FinishRank.second),
        player('p2', 0, 2, FinishRank.third),
        player('p3', 1, 3, FinishRank.fourth),
      ]);
      final result = RoundResultUsecase.calculate(state);
      expect(RoundResultUsecase.needsTribute(result), isFalse);
    });
  });
}
