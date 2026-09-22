import 'package:flutter/foundation.dart';
import '../models/game_models.dart';
import '../scoring/scoring_engine.dart';
import 'storage_service.dart';

enum RoundPhase { bidding, tricks, harry, bonuses, review }

List<RoundPhase> visiblePhases(GameState g) => [
      RoundPhase.bidding,
      RoundPhase.tricks,
      if (g.expansions.harryTheGiant) RoundPhase.harry,
      if (g.hasBonusStep) RoundPhase.bonuses,
      RoundPhase.review,
    ];

String phaseLabelFr(RoundPhase phase) {
  switch (phase) {
    case RoundPhase.bidding:
      return 'Enchères';
    case RoundPhase.tricks:
      return 'Plis';
    case RoundPhase.harry:
      return 'Harry';
    case RoundPhase.bonuses:
      return 'Bonus';
    case RoundPhase.review:
      return 'Scores';
  }
}

class GameController extends ChangeNotifier {
  final GameStorage storage;
  GameState? game;
  RoundPhase phase = RoundPhase.bidding;
  String? errorMessage;

  GameController(this.storage);

  Future<void> init() async {
    game = await storage.loadActiveGame();
    if (game != null && !game!.isFinished) {
      phase = RoundPhase.bidding;
      _ensurePendingMaps();
    }
    notifyListeners();
  }

  void _ensurePendingMaps() {
    final g = game!;
    for (final p in g.players) {
      g.pendingBids.putIfAbsent(p.id, () => 0);
      g.pendingTricks.putIfAbsent(p.id, () => 0);
      g.pendingBonuses.putIfAbsent(p.id, () => const RoundBonuses());
      g.pendingRascalWagers.putIfAbsent(p.id, () => 0);
      g.pendingHarryDeltas.putIfAbsent(p.id, () => 0);
      g.harryUsedThisRound.putIfAbsent(p.id, () => false);
      g.pendingCannonball.putIfAbsent(p.id, () => false);
    }
  }

  void _resetPending() {
    final g = game!;
    g.pendingBids = {for (final p in g.players) p.id: 0};
    g.pendingTricks = {for (final p in g.players) p.id: 0};
    g.pendingBonuses = {for (final p in g.players) p.id: const RoundBonuses()};
    g.pendingRascalWagers = {for (final p in g.players) p.id: 0};
    g.pendingHarryDeltas = {for (final p in g.players) p.id: 0};
    g.harryUsedThisRound = {for (final p in g.players) p.id: false};
    g.pendingCannonball = {for (final p in g.players) p.id: false};
    g.pendingLootAlliances = [];
    g.pendingVoidedTricks = 0;
    g.pendingGhostTricks = 0;
  }

  Future<void> startNewGame({
    required List<String> names,
    required GameMode mode,
    List<int>? customSequence,
    bool bonusesEnabled = true,
    bool classicBonusGate = false,
    ScoringSystem scoring = ScoringSystem.skullKing,
    bool cannonballAllowed = false,
    ExpansionOptions expansions = const ExpansionOptions(),
  }) async {
    if (names.length < 2 || names.length > 8) {
      throw ArgumentError('Il faut entre 2 et 8 joueurs');
    }
    final seq = buildRoundSequence(mode, custom: customSequence);
    final now = DateTime.now();
    final players = <Player>[];
    for (var i = 0; i < names.length; i++) {
      final n = names[i].trim().isEmpty ? 'Joueur ${i + 1}' : names[i].trim();
      players.add(Player(id: 'p$i', name: n));
    }
    game = GameState(
      id: 'g_${now.millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
      players: players,
      mode: mode,
      roundSequence: seq,
      bonusesEnabled: bonusesEnabled,
      classicBonusGate: classicBonusGate,
      scoring: scoring,
      cannonballAllowed: cannonballAllowed && scoring == ScoringSystem.rascal,
      expansions: expansions,
    );
    _ensurePendingMaps();
    phase = RoundPhase.bidding;
    errorMessage = null;
    await storage.saveLastPlayerNames(players.map((p) => p.name).toList());
    await storage.saveActiveGame(game!);
    notifyListeners();
  }

  /// Revanche : mêmes joueurs / options.
  Future<void> rematch() async {
    final g = game;
    if (g == null) return;
    await startNewGame(
      names: g.players.map((p) => p.name).toList(),
      mode: g.mode,
      customSequence: g.mode == GameMode.custom ? g.roundSequence : null,
      bonusesEnabled: g.bonusesEnabled,
      classicBonusGate: g.classicBonusGate,
      scoring: g.scoring,
      cannonballAllowed: g.cannonballAllowed,
      expansions: g.expansions,
    );
  }

  void setBid(String playerId, int bid) {
    final g = game!;
    g.pendingBids[playerId] = bid.clamp(0, g.currentCards);
    g.pendingHarryDeltas[playerId] = 0;
    g.harryUsedThisRound[playerId] = false;
    notifyListeners();
  }

  void setCannonball(String playerId, bool value) {
    final g = game!;
    if (!g.cannonballAllowed) return;
    g.pendingCannonball[playerId] = value;
    notifyListeners();
  }

  void setHarryDelta(String playerId, int delta) {
    final g = game!;
    if (!g.expansions.harryTheGiant) return;
    g.pendingHarryDeltas[playerId] = delta.clamp(-1, 1);
    g.harryUsedThisRound[playerId] = delta != 0;
    notifyListeners();
  }

  void setTricks(String playerId, int tricks) {
    final g = game!;
    g.pendingTricks[playerId] = tricks.clamp(0, g.currentCards);
    errorMessage = null;
    notifyListeners();
  }

  void setVoidedTricks(int n) {
    final g = game!;
    g.pendingVoidedTricks = n.clamp(0, g.currentCards);
    errorMessage = null;
    notifyListeners();
  }

  void setGhostTricks(int n) {
    final g = game!;
    g.pendingGhostTricks = n.clamp(0, g.currentCards);
    errorMessage = null;
    notifyListeners();
  }

  void setBonuses(String playerId, RoundBonuses b) {
    game!.pendingBonuses[playerId] = b;
    notifyListeners();
  }

  void setRascalWager(String playerId, int wager) {
    if (wager != 0 && wager != 10 && wager != 20) return;
    game!.pendingRascalWagers[playerId] = wager;
    notifyListeners();
  }

  void addLootAlliance(String a, String b) {
    final g = game!;
    if (!g.expansions.loot) return;
    if (a == b) return;
    if (g.pendingLootAlliances.length >= 2) return;
    g.pendingLootAlliances.add(LootAlliance(playerA: a, playerB: b));
    notifyListeners();
  }

  void removeLootAlliance(int index) {
    final g = game!;
    if (index < 0 || index >= g.pendingLootAlliances.length) return;
    g.pendingLootAlliances.removeAt(index);
    notifyListeners();
  }

  bool confirmBids() {
    phase = RoundPhase.tricks;
    errorMessage = null;
    notifyListeners();
    return true;
  }

  bool confirmTricks() {
    final g = game!;
    if (!_tricksAreValid(g)) return false;
    errorMessage = null;
    if (g.expansions.harryTheGiant) {
      phase = RoundPhase.harry;
      notifyListeners();
      return true;
    }
    return _leaveTricks();
  }

  bool confirmHarry() {
    return _leaveTricks();
  }

  bool _tricksAreValid(GameState g) {
    final tricks = g.players.map((p) => g.pendingTricks[p.id] ?? 0).toList();
    final voided = g.expansions.anySeaMonster ? g.pendingVoidedTricks : 0;
    final ghost = g.expansions.graybeard ? g.pendingGhostTricks : 0;
    if (!ScoringEngine.validateTricksSum(
      tricks,
      g.currentCards,
      voidedTricks: voided,
      ghostTricks: ghost,
    )) {
      final sum = tricks.fold<int>(0, (a, b) => a + b);
      final parts = <String>['Plis ($sum)'];
      if (g.expansions.anySeaMonster) parts.add('annulés ($voided)');
      if (g.expansions.graybeard) parts.add('Barbe Grise ($ghost)');
      errorMessage = '${parts.join(' + ')} doit égaler ${g.currentCards}.';
      notifyListeners();
      return false;
    }
    return true;
  }

  bool _leaveTricks() {
    final g = game!;
    if (g.hasBonusStep) {
      phase = RoundPhase.bonuses;
      errorMessage = null;
      notifyListeners();
      return true;
    }
    _finalizeRound();
    return true;
  }

  bool confirmBonuses() {
    final g = game!;
    if (!_tricksAreValid(g)) return false;
    _finalizeRound();
    return true;
  }

  RoundBonuses _bonusesFor(GameState g, String playerId) {
    final raw = g.pendingBonuses[playerId] ?? const RoundBonuses();
    final shares = g.expansions.loot
        ? ScoringEngine.lootSharesForPlayer(
            playerId: playerId,
            alliances: g.pendingLootAlliances,
            isExact: g.isExactPending,
            classicBonusGate: g.classicBonusGate,
          )
        : 0;
    final captureOn = g.bonusesEnabled;
    return RoundBonuses(
      colorFourteens: captureOn ? raw.colorFourteens : 0,
      blackFourteens: captureOn ? raw.blackFourteens : 0,
      mermaidByPirate: captureOn ? raw.mermaidByPirate : 0,
      pirateBySkullKing: captureOn ? raw.pirateBySkullKing : 0,
      skullKingByMermaid: captureOn ? raw.skullKingByMermaid : 0,
      lootAlliances: shares,
      eights: (captureOn && g.expansions.bonusSevensEights) ? raw.eights : 0,
      sevens: (captureOn && g.expansions.bonusSevensEights) ? raw.sevens : 0,
      davyJonesSeaMonsters:
          (captureOn && g.expansions.davyJones) ? raw.davyJonesSeaMonsters : 0,
      conCaptured: (captureOn && g.expansions.con) ? raw.conCaptured : 0,
    );
  }

  void _finalizeRound() {
    final g = game!;
    final cards = g.currentCards;
    final voided = g.expansions.anySeaMonster ? g.pendingVoidedTricks : 0;
    final ghost = g.expansions.graybeard ? g.pendingGhostTricks : 0;
    final results = <PlayerRoundResult>[];
    for (final p in g.players) {
      final bid = g.effectiveBid(p.id);
      final tricks = g.pendingTricks[p.id] ?? 0;
      final bonuses = _bonusesFor(g, p.id);
      final wager =
          g.expansions.rascalWager ? (g.pendingRascalWagers[p.id] ?? 0) : 0;
      final shot = g.cannonballAllowed && (g.pendingCannonball[p.id] ?? false);
      final scored = ScoringEngine.score(
        bid: bid,
        tricks: tricks,
        roundCards: cards,
        bonuses: bonuses,
        bonusesEnabled: g.bonusesEnabled,
        rascalWager: wager,
        classicBonusGate: g.classicBonusGate,
        scoring: g.scoring,
        cannonball: shot,
      );
      results.add(PlayerRoundResult(
        playerId: p.id,
        bid: bid,
        tricks: tricks,
        bonuses: bonuses,
        bidScore: scored.bidScore,
        bonusScore: scored.bonusScore,
        rascalWager: wager,
        rascalWagerScore: scored.rascalWagerScore,
        total: scored.total,
        harryDelta: g.pendingHarryDeltas[p.id] ?? 0,
        cannonball: shot,
      ));
    }
    g.completedRounds.add(RoundRecord(
      index: g.currentRoundIndex,
      cards: cards,
      voidedTricks: voided,
      ghostTricks: ghost,
      results: results,
    ));
    g.currentRoundIndex++;
    g.updatedAt = DateTime.now();
    _resetPending();
    phase = RoundPhase.review;
    storage.saveActiveGame(g);
    notifyListeners();
  }

  void goToPhase(RoundPhase target) {
    final g = game;
    if (g == null || phase == RoundPhase.review) return;
    final phases = visiblePhases(g);
    final from = phases.indexOf(phase);
    final to = phases.indexOf(target);
    if (to < 0 || to > from) return;
    phase = target;
    errorMessage = null;
    notifyListeners();
  }

  void goBack() {
    final g = game;
    if (g == null || phase == RoundPhase.review) return;
    final phases = visiblePhases(g);
    final i = phases.indexOf(phase);
    if (i <= 0) return;
    phase = phases[i - 1];
    errorMessage = null;
    notifyListeners();
  }

  void nextRoundOrFinish() {
    final g = game!;
    if (g.isFinished) {
      phase = RoundPhase.review;
    } else {
      phase = RoundPhase.bidding;
      errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> finishAndArchive() async {
    if (game == null) return;
    game!.updatedAt = DateTime.now();
    await storage.archiveGame(game!);
    game = null;
    phase = RoundPhase.bidding;
    notifyListeners();
  }

  Future<void> abandonGame() async {
    await storage.clearActiveGame();
    game = null;
    notifyListeners();
  }
}
