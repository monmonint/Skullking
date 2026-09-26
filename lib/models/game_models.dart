import '../scoring/scoring_engine.dart';

class Player {
  final String id;
  String name;

  Player({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Player.fromJson(Map<String, dynamic> j) =>
      Player(id: j['id'] as String, name: j['name'] as String);
}

class PlayerRoundResult {
  final String playerId;
  final int bid;
  final int tricks;
  final RoundBonuses bonuses;
  final int bidScore;
  final int bonusScore;
  final int rascalWager;
  final int rascalWagerScore;
  final int total;
  final int harryDelta;
  final bool cannonball;

  /// Mise annoncée avant Harry. Null sur les parties enregistrées avant 1.2.
  final int? declaredBid;

  const PlayerRoundResult({
    required this.playerId,
    required this.bid,
    required this.tricks,
    required this.bonuses,
    required this.bidScore,
    required this.bonusScore,
    this.rascalWager = 0,
    this.rascalWagerScore = 0,
    required this.total,
    this.harryDelta = 0,
    this.cannonball = false,
    this.declaredBid,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'bid': bid,
        'tricks': tricks,
        'bonuses': bonuses.toJson(),
        'bidScore': bidScore,
        'bonusScore': bonusScore,
        'rascalWager': rascalWager,
        'rascalWagerScore': rascalWagerScore,
        'total': total,
        'harryDelta': harryDelta,
        'cannonball': cannonball,
        if (declaredBid != null) 'declaredBid': declaredBid,
      };

  factory PlayerRoundResult.fromJson(Map<String, dynamic> j) =>
      PlayerRoundResult(
        playerId: j['playerId'] as String,
        bid: j['bid'] as int,
        tricks: j['tricks'] as int,
        bonuses: RoundBonuses.fromJson(
          Map<String, dynamic>.from(j['bonuses'] as Map? ?? {}),
        ),
        bidScore: j['bidScore'] as int,
        bonusScore: j['bonusScore'] as int,
        rascalWager: j['rascalWager'] as int? ?? 0,
        rascalWagerScore: j['rascalWagerScore'] as int? ?? 0,
        total: j['total'] as int,
        harryDelta: j['harryDelta'] as int? ?? 0,
        cannonball: j['cannonball'] as bool? ?? false,
        declaredBid: j['declaredBid'] as int?,
      );
}

class RoundRecord {
  final int index;
  final int cards;
  final int voidedTricks;
  final int ghostTricks;
  final List<PlayerRoundResult> results;
  final List<LootAlliance> lootAlliances;

  const RoundRecord({
    required this.index,
    required this.cards,
    this.voidedTricks = 0,
    this.ghostTricks = 0,
    required this.results,
    this.lootAlliances = const [],
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'cards': cards,
        'voidedTricks': voidedTricks,
        'ghostTricks': ghostTricks,
        'results': results.map((r) => r.toJson()).toList(),
        'lootAlliances': lootAlliances.map((a) => a.toJson()).toList(),
      };

  factory RoundRecord.fromJson(Map<String, dynamic> j) => RoundRecord(
        index: j['index'] as int,
        cards: j['cards'] as int,
        voidedTricks: j['voidedTricks'] as int? ?? 0,
        ghostTricks: j['ghostTricks'] as int? ?? 0,
        results: (j['results'] as List)
            .map((e) =>
                PlayerRoundResult.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        lootAlliances: (j['lootAlliances'] as List? ?? [])
            .map((e) =>
                LootAlliance.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class GameState {
  final String id;
  final DateTime createdAt;
  DateTime updatedAt;
  List<Player> players;
  GameMode mode;
  List<int> roundSequence;
  bool bonusesEnabled;

  /// Vrai = bonus seulement si enchère exacte (Halcyon). Défaut faux.
  bool classicBonusGate;
  ScoringSystem scoring;
  bool cannonballAllowed;
  ExpansionOptions expansions;
  List<RoundRecord> completedRounds;
  int currentRoundIndex;

  Map<String, int> pendingBids;
  Map<String, int> pendingTricks;
  Map<String, RoundBonuses> pendingBonuses;
  Map<String, int> pendingRascalWagers;
  Map<String, int> pendingHarryDeltas;
  Map<String, bool> harryUsedThisRound;
  Map<String, bool> pendingCannonball;
  List<LootAlliance> pendingLootAlliances;
  int pendingVoidedTricks;
  int pendingGhostTricks;

  /// Index dans [completedRounds] en cours de correction. Non persisté.
  int? editingCompletedIndex;

  GameState({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.players,
    required this.mode,
    required this.roundSequence,
    this.bonusesEnabled = true,
    this.classicBonusGate = false,
    this.scoring = ScoringSystem.skullKing,
    this.cannonballAllowed = false,
    this.expansions = const ExpansionOptions(),
    List<RoundRecord>? completedRounds,
    this.currentRoundIndex = 0,
    Map<String, int>? pendingBids,
    Map<String, int>? pendingTricks,
    Map<String, RoundBonuses>? pendingBonuses,
    Map<String, int>? pendingRascalWagers,
    Map<String, int>? pendingHarryDeltas,
    Map<String, bool>? harryUsedThisRound,
    Map<String, bool>? pendingCannonball,
    List<LootAlliance>? pendingLootAlliances,
    this.pendingVoidedTricks = 0,
    this.pendingGhostTricks = 0,
  })  : completedRounds = completedRounds ?? [],
        pendingBids = pendingBids ?? {},
        pendingTricks = pendingTricks ?? {},
        pendingBonuses = pendingBonuses ?? {},
        pendingRascalWagers = pendingRascalWagers ?? {},
        pendingHarryDeltas = pendingHarryDeltas ?? {},
        harryUsedThisRound = harryUsedThisRound ?? {},
        pendingCannonball = pendingCannonball ?? {},
        pendingLootAlliances = pendingLootAlliances ?? [];

  bool get isFinished => currentRoundIndex >= roundSequence.length;

  bool get isEditingRound => editingCompletedIndex != null;

  /// Cartes de la manche saisie : la manche corrigée, sinon la manche en cours.
  int get currentCards {
    final edit = editingCompletedIndex;
    if (edit != null && edit >= 0 && edit < completedRounds.length) {
      return completedRounds[edit].cards;
    }
    if (isFinished) return 0;
    return roundSequence[currentRoundIndex];
  }

  bool get hasBonusStep =>
      bonusesEnabled ||
      expansions.loot ||
      expansions.rascalWager ||
      expansions.davyJones ||
      expansions.bonusSevensEights ||
      expansions.con;

  /// Enchère effective (après Harry).
  int effectiveBid(String playerId) {
    final base = pendingBids[playerId] ?? 0;
    final d = pendingHarryDeltas[playerId] ?? 0;
    return ScoringEngine.applyHarryBidAdjust(base, d, currentCards);
  }

  bool isExactPending(String playerId) =>
      effectiveBid(playerId) == (pendingTricks[playerId] ?? 0);

  int totalFor(String playerId) {
    var t = 0;
    for (final r in completedRounds) {
      for (final pr in r.results) {
        if (pr.playerId == playerId) t += pr.total;
      }
    }
    return t;
  }

  /// Stats simples : manches exactes / jouées.
  Map<String, int> exactRoundsFor(String playerId) {
    var exact = 0;
    final played = completedRounds.length;
    for (final r in completedRounds) {
      for (final pr in r.results) {
        if (pr.playerId == playerId && pr.bid == pr.tricks) exact++;
      }
    }
    return {'exact': exact, 'played': played};
  }

  List<Player> rankedPlayers() {
    final copy = List<Player>.from(players);
    copy.sort((a, b) => totalFor(b.id).compareTo(totalFor(a.id)));
    return copy;
  }

  String? nameOf(String id) {
    for (final p in players) {
      if (p.id == id) return p.name;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'players': players.map((p) => p.toJson()).toList(),
        'mode': mode.name,
        'roundSequence': roundSequence,
        'bonusesEnabled': bonusesEnabled,
        'classicBonusGate': classicBonusGate,
        'scoring': scoring.name,
        'cannonballAllowed': cannonballAllowed,
        'expansions': expansions.toJson(),
        'completedRounds': completedRounds.map((r) => r.toJson()).toList(),
        'currentRoundIndex': currentRoundIndex,
      };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        players: (j['players'] as List)
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        mode: GameMode.values.firstWhere(
          (m) => m.name == j['mode'],
          orElse: () => GameMode.standard,
        ),
        roundSequence:
            (j['roundSequence'] as List).map((e) => e as int).toList(),
        bonusesEnabled: j['bonusesEnabled'] as bool? ?? true,
        classicBonusGate: j['classicBonusGate'] as bool? ?? false,
        scoring: ScoringSystem.values.firstWhere(
          (s) => s.name == j['scoring'],
          orElse: () => ScoringSystem.skullKing,
        ),
        cannonballAllowed: j['cannonballAllowed'] as bool? ?? false,
        expansions: ExpansionOptions.fromJson(
          j['expansions'] == null
              ? null
              : Map<String, dynamic>.from(j['expansions'] as Map),
        ),
        completedRounds: (j['completedRounds'] as List? ?? [])
            .map((e) =>
                RoundRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        currentRoundIndex: j['currentRoundIndex'] as int? ?? 0,
      );
}

/// Réglages repris pour la partie suivante (noms, mode, extensions).
class GameSetupDefaults {
  final List<String> playerNames;
  final GameMode mode;
  final List<int> customSequence;
  final bool bonusesEnabled;
  final bool classicBonusGate;
  final ScoringSystem scoring;
  final bool cannonballAllowed;
  final ExpansionOptions expansions;

  const GameSetupDefaults({
    required this.playerNames,
    required this.mode,
    required this.customSequence,
    required this.bonusesEnabled,
    required this.classicBonusGate,
    required this.scoring,
    required this.cannonballAllowed,
    required this.expansions,
  });

  Map<String, dynamic> toJson() => {
        'playerNames': playerNames,
        'mode': mode.name,
        'customSequence': customSequence,
        'bonusesEnabled': bonusesEnabled,
        'classicBonusGate': classicBonusGate,
        'scoring': scoring.name,
        'cannonballAllowed': cannonballAllowed,
        'expansions': expansions.toJson(),
      };

  factory GameSetupDefaults.fromJson(Map<String, dynamic> j) =>
      GameSetupDefaults(
        playerNames: (j['playerNames'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
        mode: GameMode.values.firstWhere(
          (m) => m.name == j['mode'],
          orElse: () => GameMode.standard,
        ),
        customSequence:
            (j['customSequence'] as List? ?? []).map((e) => e as int).toList(),
        bonusesEnabled: j['bonusesEnabled'] as bool? ?? true,
        classicBonusGate: j['classicBonusGate'] as bool? ?? false,
        scoring: ScoringSystem.values.firstWhere(
          (s) => s.name == j['scoring'],
          orElse: () => ScoringSystem.skullKing,
        ),
        cannonballAllowed: j['cannonballAllowed'] as bool? ?? false,
        expansions: ExpansionOptions.fromJson(
          j['expansions'] == null
              ? null
              : Map<String, dynamic>.from(j['expansions'] as Map),
        ),
      );
}
