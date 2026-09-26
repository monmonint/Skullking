import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_king_scorekeeper/main.dart';
import 'package:skull_king_scorekeeper/models/game_models.dart';
import 'package:skull_king_scorekeeper/scoring/scoring_engine.dart';
import 'package:skull_king_scorekeeper/services/game_controller.dart';
import 'package:skull_king_scorekeeper/services/storage_service.dart';
import 'package:skull_king_scorekeeper/stats/career_stats.dart';

class MemoryStorage implements GameStorage {
  List<String> names = [];
  GameState? active;
  GameSetupDefaults? defaults;
  final List<GameState> history = [];

  @override
  Future<void> archiveGame(GameState game) async {
    history.insert(0, game);
    active = null;
  }

  @override
  Future<void> clearActiveGame() async => active = null;

  @override
  Future<GameState?> loadActiveGame() async => active;

  @override
  Future<List<GameState>> loadHistory() async => List<GameState>.from(history);

  @override
  Future<List<String>> loadLastPlayerNames() async => List<String>.from(names);

  @override
  Future<void> saveActiveGame(GameState game) async => active = game;

  @override
  Future<void> saveLastPlayerNames(List<String> value) async {
    names = List<String>.from(value);
  }

  @override
  Future<GameSetupDefaults?> loadSetupDefaults() async => defaults;

  @override
  Future<void> saveSetupDefaults(GameSetupDefaults value) async {
    defaults = value;
  }
}

Future<void> _playMissedRound(GameController c) async {
  c.setBid('p0', 0);
  c.setBid('p1', 1);
  expect(c.confirmBids(), isTrue);
  c.setTricks('p0', 1);
  c.setTricks('p1', 0);
  expect(c.confirmTricks(), isTrue);
  c.setBonuses('p0', const RoundBonuses(colorFourteens: 1));
  expect(c.confirmBonuses(), isTrue);
}

void main() {
  test('recompute after editing a past round\'s bonuses', () async {
    final storage = MemoryStorage();
    final c = GameController(storage);
    await c.startNewGame(
      names: ['Anne', 'Luc'],
      mode: GameMode.custom,
      customSequence: [1, 1],
      bonusesEnabled: true,
      classicBonusGate: false,
    );

    await _playMissedRound(c);
    // Mise 0 ratée (−10) + un 14 (+10).
    expect(c.game!.totalFor('p0'), 0);
    expect(c.game!.completedRounds, hasLength(1));
    expect(c.game!.currentRoundIndex, 1);
    expect(c.phase, RoundPhase.review);

    // Manche qui vient d'être validée.
    c.beginEditRound(0);
    expect(c.isEditingRound, isTrue);
    expect(c.game!.pendingBids['p0'], 0);
    c.setBonuses('p0', const RoundBonuses(colorFourteens: 2));
    expect(c.confirmBonuses(), isTrue);
    expect(c.isEditingRound, isFalse);
    expect(c.game!.totalFor('p0'), 10);
    expect(c.game!.completedRounds, hasLength(1));
    expect(c.game!.currentRoundIndex, 1);
    expect(c.phase, RoundPhase.review);

    // Manche précédente, pendant la saisie de la suivante.
    c.nextRoundOrFinish();
    c.setBid('p0', 1);
    c.beginEditRound(0);
    c.setBonuses('p0', const RoundBonuses(colorFourteens: 3));
    expect(c.confirmBonuses(), isTrue);

    expect(c.game!.totalFor('p0'), 20);
    expect(c.game!.completedRounds.single.results.first.bonusScore, 30);
    expect(c.game!.completedRounds.single.results.first.bonuses.colorFourteens, 3);
    expect(c.game!.completedRounds, hasLength(1));
    expect(c.game!.currentRoundIndex, 1);
    expect(c.phase, RoundPhase.bidding);
    expect(c.game!.pendingBids['p0'], 1);

    final saved = GameState.fromJson(c.game!.toJson());
    expect(saved.totalFor('p0'), 20);
    expect(saved.completedRounds.single.results.first.bonuses.colorFourteens, 3);
    expect(saved.completedRounds.single.results.first.declaredBid, 0);

    final loaded = await storage.loadActiveGame();
    expect(loaded!.totalFor('p0'), 20);

    await c.finishAndArchive();
    final career = buildCareer(storage.history);
    final anne = career.players.firstWhere((p) => p.name == 'Anne');
    expect(anne.colorFourteens, 3);
    expect(anne.bonusPoints, 30);
  });

  test('edit restores the declared bid when Harry adjusted it', () async {
    final c = GameController(MemoryStorage());
    await c.startNewGame(
      names: ['Anne', 'Luc'],
      mode: GameMode.bedtime,
      expansions: const ExpansionOptions(harryTheGiant: true),
    );
    c.setBid('p0', 0);
    c.setBid('p1', 0);
    c.confirmBids();
    c.setTricks('p0', 1);
    c.setTricks('p1', 0);
    c.confirmTricks();
    c.setHarryDelta('p0', 1);
    c.confirmHarry();
    c.confirmBonuses();

    expect(c.game!.completedRounds.single.results.first.bid, 1);
    expect(c.game!.completedRounds.single.results.first.declaredBid, 0);

    c.beginEditRound(0);
    expect(c.game!.pendingBids['p0'], 0);
    expect(c.game!.pendingHarryDeltas['p0'], 1);
    expect(c.game!.effectiveBid('p0'), 1);
    c.cancelEdit();
    expect(c.isEditingRound, isFalse);
    expect(c.phase, RoundPhase.review);
  });

  testWidgets('defaults restored from last game', (tester) async {
    tester.view.physicalSize = const Size(400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = MemoryStorage();
    final c = GameController(storage);
    await c.startNewGame(
      names: ['Zoé', 'Luc'],
      mode: GameMode.whirlpool,
      bonusesEnabled: true,
      classicBonusGate: true,
      scoring: ScoringSystem.rascal,
      cannonballAllowed: true,
      expansions: const ExpansionOptions(
        kraken: true,
        whiteWhale: true,
        harryTheGiant: true,
        loot: true,
        rascalWager: true,
        tigressNotes: true,
      ),
    );
    await c.abandonGame();

    final restored = await storage.loadSetupDefaults();
    expect(restored, isNotNull);
    expect(restored!.playerNames, ['Zoé', 'Luc']);
    expect(restored.mode, GameMode.whirlpool);
    expect(restored.classicBonusGate, isTrue);
    expect(restored.scoring, ScoringSystem.rascal);
    expect(restored.cannonballAllowed, isTrue);
    expect(restored.bonusesEnabled, isTrue);
    expect(restored.expansions.kraken, isTrue);
    expect(restored.expansions.whiteWhale, isTrue);
    expect(restored.expansions.harryTheGiant, isTrue);
    expect(restored.expansions.loot, isTrue);
    expect(restored.expansions.rascalWager, isTrue);
    expect(restored.expansions.tigressNotes, isTrue);
    final again = GameSetupDefaults.fromJson(restored.toJson());
    expect(again.playerNames, ['Zoé', 'Luc']);
    expect(again.mode, GameMode.whirlpool);

    await tester.pumpWidget(SkullKingApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-new')));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(tester.widget<TextField>(fields.at(0)).controller!.text, 'Zoé');
    expect(tester.widget<TextField>(fields.at(1)).controller!.text, 'Luc');

    await tester.tap(find.byKey(const Key('setup-next')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('mode-whirlpool')),
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('setup-next')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(
              SwitchListTile,
              'Bonus seulement si enchère exacte',
            ),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Kraken'))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Baleine blanche'),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Harry le Géant'),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Rascal le Flambeur'),
          )
          .value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
