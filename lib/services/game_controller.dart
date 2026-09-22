import 'package:flutter/foundation.dart';
import '../models/game_models.dart';
import '../scoring/scoring_engine.dart';
import 'storage_service.dart';

enum RoundPhase { bidding, harry, tricks, bonuses, review }

class GameController extends ChangeNotifier {
  final StorageService storage;
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
    g.pendingVoidedTricks = 0;
  }

  Future<void> startNewGame({
    required List<String> names,
    required GameMode mode,
    List<int>? customSequence,
    bool bonusesEnabled = true,
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
      expansions: g.expansions,
    );
  }

  void setBid(String playerId, int bid) {
    final g = game!;
    g.pendingBids[playerId] = bid.clamp(0, g.currentCards);
    // Reset Harry if bid re-edited
    g.pendingHarryDeltas[playerId] = 0;
    g.harryUsedThisRound[playerId] = false;
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

  void setBonuses(String playerId, RoundBonuses b) {
    game!.pendingBonuses[playerId] = b;
    notifyListeners();
  }

  void setRascalWager(String playerId, int wager) {
    if (wager != 0 && wager != 10 && wager != 20) return;
    game!.pendingRascalWagers[playerId] = wager;
    notifyListeners();
  }

  bool confirmBids() {
    final g = game!;
    if (g.expansions.harryTheGiant) {
      phase = RoundPhase.harry;
    } else {
      phase = RoundPhase.tricks;
    }
    errorMessage = null;
    notifyListeners();
    return true;
  }

  bool confirmHarry() {
    phase = RoundPhase.tricks;
    errorMessage = null;
    notifyListeners();
    return true;
  }

  bool confirmTricks() {
    final g = game!;
    final tricks = g.players.map((p) => g.pendingTricks[p.id] ?? 0).toList();
    final voided = (g.expansions.kraken || g.expansions.whiteWhale)
        ? g.pendingVoidedTricks
        : 0;
    if (!ScoringEngine.validateTricksSum(tricks, g.currentCards,
        voidedTricks: voided)) {
      final sum = tricks.fold<int>(0, (a, b) => a + b);
      errorMessage =
          'Plis ($sum) + annulés ($voided) doit égaler ${g.currentCards}.';
      notifyListeners();
      return false;
    }
    errorMessage = null;
    final needExtras = g.bonusesEnabled ||
        g.expansions.rascalWager ||
        g.expansions.loot;
    if (!needExtras) {
      _finalizeRound();
      return true;
    }
    phase = RoundPhase.bonuses;
    notifyListeners();
    return true;
  }

  bool confirmBonuses() {
    _finalizeRound();
    return true;
  }

  void _finalizeRound() {
    final g = game!;
    final cards = g.currentCards;
    final voided = (g.expansions.kraken || g.expansions.whiteWhale)
        ? g.pendingVoidedTricks
        : 0;
    final results = <PlayerRoundResult>[];
    for (final p in g.players) {
      final bid = g.effectiveBid(p.id);
      final tricks = g.pendingTricks[p.id] ?? 0;
      final exact = bid == tricks;
      final bonuses = (exact && g.bonusesEnabled)
          ? (g.pendingBonuses[p.id] ?? const RoundBonuses())
          : const RoundBonuses();
      final wager = g.expansions.rascalWager
          ? (g.pendingRascalWagers[p.id] ?? 0)
          : 0;
      final scored = ScoringEngine.score(
        bid: bid,
        tricks: tricks,
        roundCards: cards,
        bonuses: bonuses,
        bonusesEnabled: g.bonusesEnabled,
        rascalWager: wager,
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
      ));
    }
    g.completedRounds.add(RoundRecord(
      index: g.currentRoundIndex,
      cards: cards,
      voidedTricks: voided,
      results: results,
    ));
    g.currentRoundIndex++;
    g.updatedAt = DateTime.now();
    _resetPending();
    phase = RoundPhase.review;
    storage.saveActiveGame(g);
    notifyListeners();
  }

  void nextRoundOrFinish() {
    final g = game!;
    if (g.isFinished) {
      phase = RoundPhase.review;
    } else {
      phase = RoundPhase.bidding;
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
