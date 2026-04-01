import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_card.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_game_state.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_hand_type.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_player.dart';
import 'package:poke_game/domain/paodekai/notifiers/pdk_notifier.dart';
import 'package:poke_game/domain/paodekai/usecases/validate_play_usecase.dart';
import 'package:poke_game/domain/paodekai/validators/card_validator.dart';
import 'package:poke_game/domain/paodekai/validators/consecutive_validator.dart';
import 'package:poke_game/domain/paodekai/validators/straight_validator.dart';

// 快捷牌构造（默认黑桃）
PdkCard c(PdkRank r, [PdkSuit s = PdkSuit.spade]) => PdkCard(rank: r, suit: s);

// 快捷构建单张 PdkPlayedHand
PdkPlayedHand singleHand(PdkRank rank, [PdkSuit suit = PdkSuit.spade]) {
  final card = PdkCard(rank: rank, suit: suit);
  return PdkPlayedHand(type: PdkHandType.single, cards: [card], keyCard: card);
}

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  group('CardValidator', () {
    const validator = CardValidator();

    test('single card is valid', () {
      final h = validator.validate([c(PdkRank.five)]);
      expect(h?.type, PdkHandType.single);
      expect(h?.keyCard.rank, PdkRank.five);
    });

    test('pair with same rank is valid', () {
      final h = validator.validate([
        c(PdkRank.king, PdkSuit.spade),
        c(PdkRank.king, PdkSuit.heart),
      ]);
      expect(h?.type, PdkHandType.pair);
    });

    test('pair with different ranks returns null', () {
      expect(validator.validate([c(PdkRank.three), c(PdkRank.four)]), isNull);
    });

    test('triple is valid', () {
      final h = validator.validate([
        c(PdkRank.ace, PdkSuit.spade),
        c(PdkRank.ace, PdkSuit.heart),
        c(PdkRank.ace, PdkSuit.club),
      ]);
      expect(h?.type, PdkHandType.triple);
    });

    test('bomb (four same rank) is valid', () {
      final h = validator.validate([
        c(PdkRank.seven, PdkSuit.spade),
        c(PdkRank.seven, PdkSuit.heart),
        c(PdkRank.seven, PdkSuit.club),
        c(PdkRank.seven, PdkSuit.diamond),
      ]);
      expect(h?.type, PdkHandType.bomb);
    });

    test('four cards with different ranks is not a bomb', () {
      expect(
        validator.validate([
          c(PdkRank.three),
          c(PdkRank.four),
          c(PdkRank.five),
          c(PdkRank.six),
        ]),
        isNull,
      );
    });

    test('rocket (小王+大王) is valid', () {
      const jokerSmall = PdkCard(rank: PdkRank.jokerSmall, suit: PdkSuit.none);
      const jokerBig = PdkCard(rank: PdkRank.jokerBig, suit: PdkSuit.none);
      final h = validator.validate([jokerSmall, jokerBig]);
      expect(h?.type, PdkHandType.rocket);
    });

    test('empty list returns null', () {
      expect(validator.validate([]), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('StraightValidator', () {
    const validator = StraightValidator();

    test('5-card straight 3-7 is valid', () {
      final h = validator.validate([
        c(PdkRank.three, PdkSuit.spade),
        c(PdkRank.four, PdkSuit.heart),
        c(PdkRank.five, PdkSuit.club),
        c(PdkRank.six, PdkSuit.diamond),
        c(PdkRank.seven, PdkSuit.spade),
      ]);
      expect(h?.type, PdkHandType.straight);
      expect(h?.keyCard.rank, PdkRank.seven); // 最大牌为 key
    });

    test('12-card straight 3-A is valid', () {
      final cards = [
        PdkRank.three, PdkRank.four, PdkRank.five, PdkRank.six,
        PdkRank.seven, PdkRank.eight, PdkRank.nine, PdkRank.ten,
        PdkRank.jack, PdkRank.queen, PdkRank.king, PdkRank.ace,
      ].map((r) => c(r)).toList();
      expect(validator.validate(cards)?.type, PdkHandType.straight);
    });

    test('straight containing 2 returns null', () {
      expect(
        validator.validate([
          c(PdkRank.ten),
          c(PdkRank.jack),
          c(PdkRank.queen),
          c(PdkRank.king),
          c(PdkRank.two),
        ]),
        isNull,
      );
    });

    test('straight containing joker returns null', () {
      const jokerSmall = PdkCard(rank: PdkRank.jokerSmall, suit: PdkSuit.none);
      expect(
        validator.validate([
          c(PdkRank.three),
          c(PdkRank.four),
          c(PdkRank.five),
          c(PdkRank.six),
          jokerSmall,
        ]),
        isNull,
      );
    });

    test('non-consecutive cards return null', () {
      expect(
        validator.validate([
          c(PdkRank.three),
          c(PdkRank.four),
          c(PdkRank.six), // 跳过 5
          c(PdkRank.seven),
          c(PdkRank.eight),
        ]),
        isNull,
      );
    });

    test('fewer than 5 cards return null', () {
      expect(
        validator.validate([
          c(PdkRank.three),
          c(PdkRank.four),
          c(PdkRank.five),
          c(PdkRank.six),
        ]),
        isNull,
      );
    });

    test('duplicate ranks in sequence return null', () {
      expect(
        validator.validate([
          c(PdkRank.three, PdkSuit.spade),
          c(PdkRank.three, PdkSuit.heart),
          c(PdkRank.four),
          c(PdkRank.five),
          c(PdkRank.six),
        ]),
        isNull,
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('ConsecutiveValidator', () {
    const validator = ConsecutiveValidator();

    test('3 consecutive pairs 334455 is valid', () {
      final h = validator.validate([
        c(PdkRank.three, PdkSuit.spade),
        c(PdkRank.three, PdkSuit.heart),
        c(PdkRank.four, PdkSuit.spade),
        c(PdkRank.four, PdkSuit.heart),
        c(PdkRank.five, PdkSuit.spade),
        c(PdkRank.five, PdkSuit.heart),
      ]);
      expect(h?.type, PdkHandType.consecutivePairs);
    });

    test('consecutive pairs containing 2 return null', () {
      expect(
        validator.validate([
          c(PdkRank.ace, PdkSuit.spade),
          c(PdkRank.ace, PdkSuit.heart),
          c(PdkRank.two, PdkSuit.spade),
          c(PdkRank.two, PdkSuit.heart),
          c(PdkRank.king, PdkSuit.spade),
          c(PdkRank.king, PdkSuit.heart),
        ]),
        isNull,
      );
    });

    test('only 2 pairs (below minimum 3) return null', () {
      expect(
        validator.validate([
          c(PdkRank.three, PdkSuit.spade),
          c(PdkRank.three, PdkSuit.heart),
          c(PdkRank.four, PdkSuit.spade),
          c(PdkRank.four, PdkSuit.heart),
        ]),
        isNull,
      );
    });

    test('airplane with 2 consecutive triples 333444 is valid', () {
      final h = validator.validate([
        c(PdkRank.three, PdkSuit.spade),
        c(PdkRank.three, PdkSuit.heart),
        c(PdkRank.three, PdkSuit.club),
        c(PdkRank.four, PdkSuit.spade),
        c(PdkRank.four, PdkSuit.heart),
        c(PdkRank.four, PdkSuit.club),
      ]);
      expect(h?.type, PdkHandType.airplane);
    });

    test('non-consecutive triples return null', () {
      expect(
        validator.validate([
          c(PdkRank.three, PdkSuit.spade),
          c(PdkRank.three, PdkSuit.heart),
          c(PdkRank.three, PdkSuit.club),
          c(PdkRank.five, PdkSuit.spade), // 跳过 4
          c(PdkRank.five, PdkSuit.heart),
          c(PdkRank.five, PdkSuit.club),
        ]),
        isNull,
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('PdkPlayedHand.beats()', () {
    PdkPlayedHand pair(PdkRank rank) {
      final cards = [
        PdkCard(rank: rank, suit: PdkSuit.spade),
        PdkCard(rank: rank, suit: PdkSuit.heart),
      ];
      return PdkPlayedHand(
          type: PdkHandType.pair, cards: cards, keyCard: cards[0]);
    }

    PdkPlayedHand bomb(PdkRank rank) {
      final cards = [
        PdkCard(rank: rank, suit: PdkSuit.spade),
        PdkCard(rank: rank, suit: PdkSuit.heart),
        PdkCard(rank: rank, suit: PdkSuit.club),
        PdkCard(rank: rank, suit: PdkSuit.diamond),
      ];
      return PdkPlayedHand(
          type: PdkHandType.bomb, cards: cards, keyCard: cards[3]);
    }

    const jokerSmall = PdkCard(rank: PdkRank.jokerSmall, suit: PdkSuit.none);
    const jokerBig = PdkCard(rank: PdkRank.jokerBig, suit: PdkSuit.none);
    final rocket = PdkPlayedHand(
      type: PdkHandType.rocket,
      cards: [jokerSmall, jokerBig],
      keyCard: jokerBig,
    );

    test('higher single beats lower single', () {
      expect(singleHand(PdkRank.ace).beats(singleHand(PdkRank.king)), isTrue);
      expect(singleHand(PdkRank.three).beats(singleHand(PdkRank.ace)), isFalse);
    });

    test('same rank: higher suit beats lower suit (♠ > ♥ > ♣ > ♦)', () {
      final spadeSeven = singleHand(PdkRank.seven, PdkSuit.spade);
      final diamondSeven = singleHand(PdkRank.seven, PdkSuit.diamond);
      expect(spadeSeven.beats(diamondSeven), isTrue);
      expect(diamondSeven.beats(spadeSeven), isFalse);
    });

    test('higher pair beats lower pair', () {
      expect(pair(PdkRank.ace).beats(pair(PdkRank.king)), isTrue);
      expect(pair(PdkRank.three).beats(pair(PdkRank.ace)), isFalse);
    });

    test('bomb beats any non-bomb', () {
      expect(bomb(PdkRank.three).beats(singleHand(PdkRank.two)), isTrue);
      expect(bomb(PdkRank.three).beats(pair(PdkRank.ace)), isTrue);
    });

    test('higher bomb beats lower bomb', () {
      expect(bomb(PdkRank.ace).beats(bomb(PdkRank.three)), isTrue);
      expect(bomb(PdkRank.three).beats(bomb(PdkRank.ace)), isFalse);
    });

    test('non-bomb cannot beat bomb', () {
      expect(singleHand(PdkRank.two).beats(bomb(PdkRank.three)), isFalse);
    });

    test('rocket beats everything', () {
      expect(rocket.beats(bomb(PdkRank.ace)), isTrue);
      expect(rocket.beats(singleHand(PdkRank.two)), isTrue);
    });

    test('nothing beats rocket', () {
      expect(bomb(PdkRank.ace).beats(rocket), isFalse);
      expect(singleHand(PdkRank.two).beats(rocket), isFalse);
    });

    test('different types (non-bomb) cannot beat each other', () {
      expect(singleHand(PdkRank.two).beats(pair(PdkRank.three)), isFalse);
      expect(pair(PdkRank.three).beats(singleHand(PdkRank.two)), isFalse);
    });

    test('same type but different lengths cannot beat', () {
      final straight5 = PdkPlayedHand(
        type: PdkHandType.straight,
        cards: [c(PdkRank.three), c(PdkRank.four), c(PdkRank.five),
                c(PdkRank.six), c(PdkRank.seven)],
        keyCard: c(PdkRank.seven),
      );
      final straight6 = PdkPlayedHand(
        type: PdkHandType.straight,
        cards: [c(PdkRank.four), c(PdkRank.five), c(PdkRank.six),
                c(PdkRank.seven), c(PdkRank.eight), c(PdkRank.nine)],
        keyCard: c(PdkRank.nine),
      );
      expect(straight6.beats(straight5), isFalse);
      expect(straight5.beats(straight6), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('ValidatePlayUseCase', () {
    const validate = ValidatePlayUseCase();

    const spadeThree = PdkCard(rank: PdkRank.three, suit: PdkSuit.spade);
    const heartThree = PdkCard(rank: PdkRank.three, suit: PdkSuit.heart);

    PdkGameState makeState({
      required List<PdkPlayer> players,
      PdkPlayedHand? lastPlayedHand,
      bool isFirstPlay = false,
      int currentPlayerIndex = 0,
    }) {
      return PdkGameState(
        players: players,
        currentPlayerIndex: currentPlayerIndex,
        lastPlayedHand: lastPlayedHand,
        phase: PdkGamePhase.playing,
        isFirstPlay: isFirstPlay,
      );
    }

    final basicPlayers = [
      const PdkPlayer(
          id: 'p0',
          name: 'P0',
          hand: [spadeThree, PdkCard(rank: PdkRank.five, suit: PdkSuit.spade)],
          isAi: false),
    ];

    test('first play must contain ♠3', () {
      final state = makeState(players: basicPlayers, isFirstPlay: true);
      expect(validate(selectedCards: [spadeThree], state: state), isNotNull);
      expect(validate(selectedCards: [c(PdkRank.five)], state: state), isNull);
    });

    test('first play with ♠3 returns correct hand type', () {
      final state = makeState(players: basicPlayers, isFirstPlay: true);
      expect(
          validate(selectedCards: [spadeThree], state: state)?.type,
          PdkHandType.single);
    });

    test('free round (no lastPlayedHand): any valid combo allowed', () {
      final state =
          makeState(players: basicPlayers, lastPlayedHand: null, isFirstPlay: false);
      expect(validate(selectedCards: [c(PdkRank.five)], state: state), isNotNull);
    });

    test('must beat lastPlayedHand', () {
      final upHand = singleHand(PdkRank.ace);
      final state = makeState(players: basicPlayers, lastPlayedHand: upHand);
      // ♥3 < ♠A → cannot beat
      expect(validate(selectedCards: [heartThree], state: state), isNull);
    });

    test('bomb beats any non-bomb lastPlayedHand', () {
      final upHand = singleHand(PdkRank.two);
      final bombCards = [
        c(PdkRank.five, PdkSuit.spade),
        c(PdkRank.five, PdkSuit.heart),
        c(PdkRank.five, PdkSuit.club),
        c(PdkRank.five, PdkSuit.diamond),
      ];
      final bombPlayer = PdkPlayer(
          id: 'p0', name: 'P0', hand: bombCards, isAi: false);
      final state = makeState(players: [bombPlayer], lastPlayedHand: upHand);
      expect(
          validate(selectedCards: bombCards, state: state)?.type,
          PdkHandType.bomb);
    });

    test('invalid combo (3 cards, different ranks) returns null', () {
      final state = makeState(players: basicPlayers, lastPlayedHand: null);
      expect(
        validate(
            selectedCards: [c(PdkRank.three), c(PdkRank.four), c(PdkRank.five)],
            state: state),
        isNull,
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('PdkGameNotifier — pass logic', () {
    PdkGameState buildState({
      required String currentId,
      PdkPlayedHand? lastPlayedHand,
      int passCount = 0,
    }) {
      final ids = ['p0', 'p1', 'p2'];
      return PdkGameState(
        players: ids
            .map((id) => PdkPlayer(
                  id: id,
                  name: id,
                  hand: [c(PdkRank.ace, PdkSuit.spade), c(PdkRank.king)],
                  isAi: false,
                ))
            .toList(),
        currentPlayerIndex: ids.indexOf(currentId),
        lastPlayedHand: lastPlayedHand,
        passCount: passCount,
        phase: PdkGamePhase.playing,
        isFirstPlay: false,
      );
    }

    test('passCount < 2: increments and moves to next player', () {
      final notifier = PdkGameNotifier();
      notifier.syncState(buildState(
          currentId: 'p1', lastPlayedHand: singleHand(PdkRank.five)));
      notifier.pass('p1');
      expect(notifier.state.passCount, 1);
      expect(notifier.state.currentPlayerIndex, 2); // p2
    });

    test('passCount reaches 2: new round starts, lastHand cleared', () {
      final notifier = PdkGameNotifier();
      notifier.syncState(buildState(
          currentId: 'p2',
          lastPlayedHand: singleHand(PdkRank.five),
          passCount: 1));
      notifier.pass('p2');
      expect(notifier.state.passCount, 0);
      expect(notifier.state.lastPlayedHand, isNull);
    });

    // 回归测试：_findLastPlayedIndex 修复验证
    test('p0 plays, p1+p2 pass → free hand returns to p0 (index 0)', () {
      // 初始：p0 已出牌，当前轮到 p1（index=1）
      final notifier = PdkGameNotifier();
      notifier.syncState(buildState(
          currentId: 'p1', lastPlayedHand: singleHand(PdkRank.five)));
      notifier.pass('p1'); // passCount=1, → p2
      notifier.pass('p2'); // passCount=2 → 新轮
      expect(notifier.state.currentPlayerIndex, 0); // 先手回到 p0
      expect(notifier.state.lastPlayedHand, isNull);
    });

    test('p1 plays, p2+p0 pass → free hand returns to p1 (index 1)', () {
      // 初始：p1 已出牌，当前轮到 p2（index=2）
      final notifier = PdkGameNotifier();
      notifier.syncState(buildState(
          currentId: 'p2', lastPlayedHand: singleHand(PdkRank.five)));
      notifier.pass('p2'); // passCount=1, → p0
      notifier.pass('p0'); // passCount=2 → 新轮
      // _findLastPlayedIndex(0) = (0-2+3)%3 = 1 → p1
      expect(notifier.state.currentPlayerIndex, 1);
      expect(notifier.state.lastPlayedHand, isNull);
    });

    test('p2 plays, p0+p1 pass → free hand returns to p2 (index 2)', () {
      // 初始：p2 已出牌，当前轮到 p0（index=0）
      final notifier = PdkGameNotifier();
      notifier.syncState(buildState(
          currentId: 'p0', lastPlayedHand: singleHand(PdkRank.five)));
      notifier.pass('p0'); // passCount=1, → p1
      notifier.pass('p1'); // passCount=2 → 新轮
      // _findLastPlayedIndex(1) = (1-2+3)%3 = 2 → p2
      expect(notifier.state.currentPlayerIndex, 2);
      expect(notifier.state.lastPlayedHand, isNull);
    });

    test('wrong player calling pass is ignored', () {
      final notifier = PdkGameNotifier();
      notifier.syncState(buildState(
          currentId: 'p0', lastPlayedHand: singleHand(PdkRank.five)));
      final before = notifier.state.currentPlayerIndex;
      notifier.pass('p1'); // 不是当前玩家
      expect(notifier.state.currentPlayerIndex, before); // 状态不变
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('PdkGameNotifier — playCards logic', () {
    const spadeAce = PdkCard(rank: PdkRank.ace, suit: PdkSuit.spade);
    const spadeTwo = PdkCard(rank: PdkRank.two, suit: PdkSuit.spade);

    PdkGameState buildPlayState({
      List<PdkCard> p0Hand = const [spadeAce],
      List<PdkCard> p1Hand = const [spadeTwo],
      List<PdkCard> p2Hand = const [],
      int currentPlayerIndex = 0,
      PdkPlayedHand? lastPlayedHand,
    }) {
      return PdkGameState(
        players: [
          PdkPlayer(id: 'p0', name: 'P0', hand: p0Hand, isAi: false),
          PdkPlayer(id: 'p1', name: 'P1', hand: p1Hand, isAi: false),
          PdkPlayer(
              id: 'p2',
              name: 'P2',
              hand: p2Hand.isEmpty
                  ? [c(PdkRank.three), c(PdkRank.four), c(PdkRank.five)]
                  : p2Hand,
              isAi: false),
        ],
        currentPlayerIndex: currentPlayerIndex,
        lastPlayedHand: lastPlayedHand,
        phase: PdkGamePhase.playing,
        isFirstPlay: false,
      );
    }

    test('successful play removes card from hand', () {
      final notifier = PdkGameNotifier();
      notifier.syncState(buildPlayState(
          p0Hand: [spadeAce, c(PdkRank.king)]));
      final ok = notifier.playCards('p0', [spadeAce]);
      expect(ok, isTrue);
      expect(notifier.state.players[0].hand.length, 1);
    });

    test('play by non-current player returns false', () {
      final notifier = PdkGameNotifier();
      notifier.syncState(buildPlayState());
      final ok = notifier.playCards('p1', [spadeTwo]); // 当前是 p0
      expect(ok, isFalse);
    });

    test('play that cannot beat lastPlayedHand returns false', () {
      final notifier = PdkGameNotifier();
      // p1 的 ♠2 已出，轮到 p0 但 ♠A < ♠2
      notifier.syncState(buildPlayState(
        currentPlayerIndex: 0,
        lastPlayedHand: singleHand(PdkRank.two),
      ));
      final ok = notifier.playCards('p0', [spadeAce]);
      expect(ok, isFalse);
    });

    test('playing all cards adds player to rankings', () {
      final notifier = PdkGameNotifier();
      notifier.syncState(buildPlayState(p0Hand: [spadeAce]));
      notifier.playCards('p0', [spadeAce]);
      expect(notifier.state.rankings.contains('p0'), isTrue);
    });

    test('passCount resets to 0 after a play', () {
      final notifier = PdkGameNotifier();
      notifier.syncState(buildPlayState(
        p0Hand: [spadeAce, c(PdkRank.king)],
        lastPlayedHand: null,
      ));
      // 先模拟 passCount 非零
      final stateWithPass = notifier.state.copyWith(passCount: 1);
      notifier.syncState(stateWithPass);
      notifier.playCards('p0', [spadeAce]);
      expect(notifier.state.passCount, 0);
    });

    test('when 2 players finish, game ends and all 3 players in rankings', () {
      // p0 出 ♠A → rankings=[p0]，轮到 p1
      // p1 出 ♠2（压过 ♠A）→ rankings=[p0,p1]，isOver=true
      // _finalizeRankings 补上 p2 → rankings 长度 3
      final notifier = PdkGameNotifier();
      notifier.syncState(buildPlayState(
        p0Hand: [spadeAce],
        p1Hand: [spadeTwo],
        p2Hand: [c(PdkRank.three), c(PdkRank.four), c(PdkRank.five)],
      ));
      notifier.playCards('p0', [spadeAce]); // p0 出完，轮到 p1
      notifier.playCards('p1', [spadeTwo]); // p1 出完，isOver=true
      expect(notifier.state.phase, PdkGamePhase.gameOver);
      expect(notifier.state.rankings.length, 3);
      expect(notifier.state.rankings[0], 'p0');
      expect(notifier.state.rankings[1], 'p1');
    });
  });
}
