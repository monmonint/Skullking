import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_king_scorekeeper/main.dart';
import 'package:skull_king_scorekeeper/models/game_models.dart';
import 'package:skull_king_scorekeeper/screens/phases/bonus_phase.dart';
import 'package:skull_king_scorekeeper/services/storage_service.dart';

class MemoryStorage implements GameStorage {
  List<String> names = [];
  GameState? active;
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
}

void main() {
  testWidgets('extensions et bonus sur mise ratée, du menu jusqu\'au score',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SkullKingApp(storage: MemoryStorage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-new')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setup-next')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('mode-bedtime')),
      300,
    );
    await tester.tap(find.byKey(const Key('mode-bedtime')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('setup-next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('preset-journal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preset-extension')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('setup-start')));
    await tester.pumpAndSettle();

    expect(find.text('Enchères'), findsWidgets);
    await tester.tap(find.byKey(const Key('bid-p0-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('play-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kraken'), findsWidgets);
    expect(find.textContaining('Baleine'), findsWidgets);
    expect(find.textContaining('Raie'), findsWidgets);
    expect(find.textContaining('Rosie'), findsWidgets);

    await tester.tap(find.byKey(const Key('voided-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('play-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Harry le Géant'), findsWidgets);
    await tester.tap(find.byKey(const Key('play-next')));
    await tester.pumpAndSettle();

    expect(find.text('Pari Rascal'), findsOneWidget);
    final bonusScroll = find.descendant(
      of: find.byType(BonusPhase),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Alliances Butin'),
      400,
      scrollable: bonusScroll,
    );
    expect(find.textContaining('Alliances Butin'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('bonus-p0-color-plus')),
      500,
      scrollable: bonusScroll,
    );
    expect(find.textContaining('Davy Jones'), findsWidgets);
    expect(find.textContaining('14 couleur'), findsWidgets);
    await tester.tap(find.byKey(const Key('bonus-p0-color-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('play-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Manche 1 terminée'), findsOneWidget);
    expect(find.textContaining('Bonus +10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
