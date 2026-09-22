import 'package:flutter_test/flutter_test.dart';
import 'package:skull_king_scorekeeper/scoring/scoring_engine.dart';

void main() {
  group('ScoringEngine — enchères classiques', () {
    test('enchère exacte non-nulle : +20 × plis', () {
      final r = ScoringEngine.score(bid: 3, tricks: 3, roundCards: 5);
      expect(r.exact, isTrue);
      expect(r.bidScore, 60);
      expect(r.bonusScore, 0);
      expect(r.total, 60);
    });

    test('raté : −10 × |plis−enchère|, pas de bonus', () {
      final r = ScoringEngine.score(
        bid: 4,
        tricks: 2,
        roundCards: 7,
        bonuses: const RoundBonuses(colorFourteens: 2, blackFourteens: 1),
      );
      expect(r.exact, isFalse);
      expect(r.bidScore, -20);
      expect(r.bonusScore, 0);
      expect(r.total, -20);
    });

    test('enchère 0 réussie / ratée', () {
      expect(
        ScoringEngine.score(bid: 0, tricks: 0, roundCards: 8).bidScore,
        80,
      );
      expect(
        ScoringEngine.score(bid: 0, tricks: 2, roundCards: 6).bidScore,
        -60,
      );
    });

    test('bonus Halcyon + butin uniquement si exact', () {
      final bonuses = const RoundBonuses(
        colorFourteens: 2,
        blackFourteens: 1,
        mermaidByPirate: 1,
        pirateBySkullKing: 1,
        skullKingByMermaid: 1,
        lootAlliances: 1,
      );
      // 20+20+20+30+40+20 = 150
      expect(bonuses.totalPoints, 150);

      final exact = ScoringEngine.score(
        bid: 1,
        tricks: 1,
        roundCards: 3,
        bonuses: bonuses,
      );
      expect(exact.total, 20 + 150);

      final miss = ScoringEngine.score(
        bid: 1,
        tricks: 0,
        roundCards: 3,
        bonuses: bonuses,
      );
      expect(miss.bonusScore, 0);
    });
  });

  group('Rascal wager', () {
    test('exact +20', () {
      final r = ScoringEngine.score(
        bid: 2,
        tricks: 2,
        roundCards: 5,
        rascalWager: 20,
      );
      expect(r.rascalWagerScore, 20);
      expect(r.total, 40 + 20);
    });
    test('miss −10', () {
      final r = ScoringEngine.score(
        bid: 2,
        tricks: 1,
        roundCards: 5,
        rascalWager: 10,
      );
      expect(r.rascalWagerScore, -10);
      expect(r.total, -10 + -10);
    });
    test('wager invalide', () {
      expect(
        () => ScoringEngine.score(
          bid: 1,
          tricks: 1,
          roundCards: 2,
          rascalWager: 15,
        ),
        throwsArgumentError,
      );
    });
  });

  group('validation plis + annulés', () {
    test('sans void', () {
      expect(ScoringEngine.validateTricksSum([1, 2, 0, 2], 5), isTrue);
    });
    test('avec Kraken void', () {
      expect(
        ScoringEngine.validateTricksSum([2, 2, 1], 6, voidedTricks: 1),
        isTrue,
      );
      expect(
        ScoringEngine.validateTricksSum([2, 2, 1], 6, voidedTricks: 0),
        isFalse,
      );
    });
  });

  group('Harry le Géant', () {
    test('±1 borné', () {
      expect(ScoringEngine.applyHarryBidAdjust(3, 1, 5), 4);
      expect(ScoringEngine.applyHarryBidAdjust(0, -1, 5), 0);
      expect(ScoringEngine.applyHarryBidAdjust(5, 1, 5), 5);
      expect(ScoringEngine.applyHarryBidAdjust(2, 0, 5), 2);
    });
  });

  group('Kraken / Baleine clash', () {
    test('kraken seul', () {
      expect(
        ScoringEngine.resolveSeaMonsterClash(
          krakenPresent: true,
          whalePresent: false,
        ),
        SeaMonsterOutcome.krakenDestroys,
      );
    });
    test('baleine seule', () {
      expect(
        ScoringEngine.resolveSeaMonsterClash(
          krakenPresent: false,
          whalePresent: true,
        ),
        SeaMonsterOutcome.whaleHighestNumber,
      );
    });
    test('2e = kraken gagne', () {
      expect(
        ScoringEngine.resolveSeaMonsterClash(
          krakenPresent: true,
          whalePresent: true,
          secondPlayed: 'kraken',
        ),
        SeaMonsterOutcome.krakenDestroys,
      );
    });
    test('2e = whale gagne', () {
      expect(
        ScoringEngine.resolveSeaMonsterClash(
          krakenPresent: true,
          whalePresent: true,
          secondPlayed: 'whale',
        ),
        SeaMonsterOutcome.whaleHighestNumber,
      );
    });
  });

  group('séquences de modes', () {
    test('standard', () {
      expect(buildRoundSequence(GameMode.standard),
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });
    test('blitz / attaque éclair', () {
      expect(buildRoundSequence(GameMode.blitz), [5, 5, 5, 5, 5]);
    });
    test('barrage', () {
      expect(buildRoundSequence(GameMode.barrage), List.filled(10, 10));
    });
    test('tourbillon', () {
      expect(buildRoundSequence(GameMode.whirlpool),
          [9, 9, 7, 7, 5, 5, 3, 3, 1, 1]);
    });
    test('dodo', () {
      expect(buildRoundSequence(GameMode.bedtime), [1]);
    });
    test('pas d\'impair', () {
      expect(buildRoundSequence(GameMode.evenKeel),
          [2, 2, 4, 4, 6, 6, 8, 8, 10, 10]);
    });
    test('prêt au combat', () {
      expect(buildRoundSequence(GameMode.skipToBrawl), [6, 7, 8, 9, 10]);
    });
    test('custom', () {
      expect(buildRoundSequence(GameMode.custom, custom: [3, 5, 7]), [3, 5, 7]);
    });
    test('tous playable', () {
      for (final m in GameMode.values) {
        expect(m.playable, isTrue);
      }
    });
  });
}
