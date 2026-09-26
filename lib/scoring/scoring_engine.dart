/// Moteur de score Skull King — Halcyon / Grandpa Beck's 2022, Rascal,
/// boulet de canon, et saisie des bonus d'extension.
///
/// Règle maison (défaut) : [classicBonusGate] est faux, donc les points
/// bonus (14, captures, 7/8, Davy Jones, Con, butin déjà qualifié) sont
/// accordés même si la mise est ratée. Le pari de Rascal le Flambeur reste
/// un vrai pari : +s'il est exact, −sinon.
library;

enum ScoringSystem {
  /// +20 × plis si exact, −10 × écart sinon, mise 0 = ±10 × cartes.
  skullKing,

  /// 10 × cartes : coup direct / moitié si écart 1 / 0 si écart ≥ 2.
  rascal,
}

extension ScoringSystemLabel on ScoringSystem {
  String get labelFr {
    switch (this) {
      case ScoringSystem.skullKing:
        return 'Skull King (classique)';
      case ScoringSystem.rascal:
        return 'Rascal';
    }
  }

  String get descriptionFr {
    switch (this) {
      case ScoringSystem.skullKing:
        return 'Audacieux : +20 par pli exact, −10 par pli d\'écart.';
      case ScoringSystem.rascal:
        return '10 pts × cartes. Exact = tout, écart 1 = moitié, écart ≥ 2 = 0.';
    }
  }
}

class RoundBonuses {
  /// 14 de couleur classique (jaune / vert / violet) en fin de manche. +10.
  final int colorFourteens;

  /// 14 noir (drapeau / atout). +20.
  final int blackFourteens;

  /// Sirènes capturées par un pirate (Tigresse / Scary Mary seulement si pirate). +20.
  final int mermaidByPirate;

  /// Pirates capturés par Skull King (pas Tigresse-fuite). +30.
  final int pirateBySkullKing;

  /// Skull King capturé par une sirène (+40, livret 2022).
  final int skullKingByMermaid;

  /// Alliances Butin déjà qualifiées (chaque alliance → +20 pour ce joueur).
  final int lootAlliances;

  /// 8 d'extension capturés. +5 chacun.
  final int eights;

  /// 7 d'extension capturés. −5 chacun.
  final int sevens;

  /// Monstres marins capturés par le coffre de Davy Jones. +20 chacun.
  final int davyJonesSeaMonsters;

  /// First Mate Con capturé par Skull King ou une sirène. +30 chacun.
  final int conCaptured;

  const RoundBonuses({
    this.colorFourteens = 0,
    this.blackFourteens = 0,
    this.mermaidByPirate = 0,
    this.pirateBySkullKing = 0,
    this.skullKingByMermaid = 0,
    this.lootAlliances = 0,
    this.eights = 0,
    this.sevens = 0,
    this.davyJonesSeaMonsters = 0,
    this.conCaptured = 0,
  });

  /// 14, captures et cartes d'extension (sans le butin).
  int get captureAndCardPoints =>
      colorFourteens * 10 +
      blackFourteens * 20 +
      mermaidByPirate * 20 +
      pirateBySkullKing * 30 +
      skullKingByMermaid * 40 +
      eights * 5 +
      sevens * -5 +
      davyJonesSeaMonsters * 20 +
      conCaptured * 30;

  int get lootPoints => lootAlliances * 20;

  int get totalPoints => captureAndCardPoints + lootPoints;

  Map<String, dynamic> toJson() => {
        'colorFourteens': colorFourteens,
        'blackFourteens': blackFourteens,
        'mermaidByPirate': mermaidByPirate,
        'pirateBySkullKing': pirateBySkullKing,
        'skullKingByMermaid': skullKingByMermaid,
        'lootAlliances': lootAlliances,
        'eights': eights,
        'sevens': sevens,
        'davyJonesSeaMonsters': davyJonesSeaMonsters,
        'conCaptured': conCaptured,
      };

  factory RoundBonuses.fromJson(Map<String, dynamic> j) => RoundBonuses(
        colorFourteens: j['colorFourteens'] as int? ?? 0,
        blackFourteens: j['blackFourteens'] as int? ?? 0,
        mermaidByPirate: j['mermaidByPirate'] as int? ?? 0,
        pirateBySkullKing: j['pirateBySkullKing'] as int? ?? 0,
        skullKingByMermaid: j['skullKingByMermaid'] as int? ?? 0,
        lootAlliances: j['lootAlliances'] as int? ?? 0,
        eights: j['eights'] as int? ?? 0,
        sevens: j['sevens'] as int? ?? 0,
        davyJonesSeaMonsters: j['davyJonesSeaMonsters'] as int? ?? 0,
        conCaptured: j['conCaptured'] as int? ?? 0,
      );

  RoundBonuses copyWith({
    int? colorFourteens,
    int? blackFourteens,
    int? mermaidByPirate,
    int? pirateBySkullKing,
    int? skullKingByMermaid,
    int? lootAlliances,
    int? eights,
    int? sevens,
    int? davyJonesSeaMonsters,
    int? conCaptured,
  }) =>
      RoundBonuses(
        colorFourteens: colorFourteens ?? this.colorFourteens,
        blackFourteens: blackFourteens ?? this.blackFourteens,
        mermaidByPirate: mermaidByPirate ?? this.mermaidByPirate,
        pirateBySkullKing: pirateBySkullKing ?? this.pirateBySkullKing,
        skullKingByMermaid: skullKingByMermaid ?? this.skullKingByMermaid,
        lootAlliances: lootAlliances ?? this.lootAlliances,
        eights: eights ?? this.eights,
        sevens: sevens ?? this.sevens,
        davyJonesSeaMonsters: davyJonesSeaMonsters ?? this.davyJonesSeaMonsters,
        conCaptured: conCaptured ?? this.conCaptured,
      );
}

class ScoreResult {
  final int bidScore;
  final int bonusScore;
  final int rascalWagerScore;
  final int total;
  final bool exact;
  final bool wasBidZero;
  final int difference;

  const ScoreResult({
    required this.bidScore,
    required this.bonusScore,
    required this.rascalWagerScore,
    required this.total,
    required this.exact,
    required this.wasBidZero,
    required this.difference,
  });
}

/// Effet d'un pli avec monstre marin (aide / validation, pas une simulation).
enum SeaMonsterOutcome {
  /// Kraken (ou 2e carte = Kraken) : pli détruit, personne ne gagne.
  krakenDestroys,

  /// Baleine : plus haut numéro gagne (couleurs ignorées ; spéciaux détruits).
  whaleHighestNumber,

  /// Baleine mais uniquement des spéciaux : pli défaussé.
  whaleAllSpecialsDiscarded,

  /// Raie tachetée : plus petit numéro gagne.
  stingrayLowestNumber,

  /// Raie mais uniquement des spéciaux : pli défaussé.
  stingrayAllSpecialsDiscarded,
}

/// Alliance Butin : le joueur qui pose la carte et celui qui la capture.
class LootAlliance {
  final String playerA;
  final String playerB;

  const LootAlliance({required this.playerA, required this.playerB});

  bool involves(String id) => playerA == id || playerB == id;

  Map<String, dynamic> toJson() => {'playerA': playerA, 'playerB': playerB};

  factory LootAlliance.fromJson(Map<String, dynamic> j) => LootAlliance(
        playerA: j['playerA'] as String,
        playerB: j['playerB'] as String,
      );
}

class ScoringEngine {
  /// Score d'une manche.
  ///
  /// [classicBonusGate] : si vrai, barème officiel (bonus seulement si la mise
  /// est exacte ; en Rascal chevrotine, moitié des bonus de cartes/captures
  /// si l'écart est de 1). Défaut : faux — les bonus saisis sont toujours
  /// ajoutés.
  ///
  /// [cannonball] n'agit qu'avec [ScoringSystem.rascal] : 15 × cartes si exact,
  /// sinon 0. Le pari Rascal (0/10/20) reste indépendant.
  static ScoreResult score({
    required int bid,
    required int tricks,
    required int roundCards,
    RoundBonuses bonuses = const RoundBonuses(),
    bool bonusesEnabled = true,
    int rascalWager = 0,
    bool classicBonusGate = false,
    ScoringSystem scoring = ScoringSystem.skullKing,
    bool cannonball = false,
  }) {
    if (roundCards < 0) throw ArgumentError('roundCards must be >= 0');
    if (tricks < 0 || bid < 0) {
      throw ArgumentError('bid and tricks must be >= 0');
    }
    if (rascalWager != 0 && rascalWager != 10 && rascalWager != 20) {
      throw ArgumentError('rascalWager must be 0, 10 or 20');
    }

    final wasBidZero = bid == 0;
    final exact = tricks == bid;
    final difference = (tricks - bid).abs();
    final useCannonball = cannonball && scoring == ScoringSystem.rascal;

    final int bidScore;
    if (scoring == ScoringSystem.rascal) {
      if (useCannonball) {
        bidScore = exact ? 15 * roundCards : 0;
      } else {
        final pot = 10 * roundCards;
        if (exact) {
          bidScore = pot;
        } else if (difference == 1) {
          bidScore = pot ~/ 2;
        } else {
          bidScore = 0;
        }
      }
    } else if (wasBidZero) {
      bidScore = exact ? 10 * roundCards : -10 * roundCards;
    } else if (exact) {
      bidScore = 20 * tricks;
    } else {
      bidScore = -10 * difference;
    }

    final bonusScore = resolveBonusScore(
      bonuses: bonuses,
      bonusesEnabled: bonusesEnabled,
      exact: exact,
      difference: difference,
      classicBonusGate: classicBonusGate,
      scoring: scoring,
      cannonball: useCannonball,
    );

    final rascalWagerScore =
        rascalWager == 0 ? 0 : (exact ? rascalWager : -rascalWager);

    return ScoreResult(
      bidScore: bidScore,
      bonusScore: bonusScore,
      rascalWagerScore: rascalWagerScore,
      total: bidScore + bonusScore + rascalWagerScore,
      exact: exact,
      wasBidZero: wasBidZero,
      difference: difference,
    );
  }

  /// Points bonus après le filtre « enchère exacte » et le barème Rascal.
  ///
  /// Le butin inclus dans [bonuses] est ajouté en entier (la qualification
  /// des deux alliés se fait en amont). Il n'est pas réduit de moitié.
  /// Si [bonusesEnabled] est faux, seuls les points de butin restent.
  static int resolveBonusScore({
    required RoundBonuses bonuses,
    required bool bonusesEnabled,
    required bool exact,
    required int difference,
    required bool classicBonusGate,
    required ScoringSystem scoring,
    required bool cannonball,
  }) {
    final loot = bonuses.lootPoints;
    final capture = bonusesEnabled ? bonuses.captureAndCardPoints : 0;

    if (!classicBonusGate) {
      return capture + loot;
    }

    final lootAward = exact ? loot : 0;
    if (scoring == ScoringSystem.skullKing || cannonball) {
      return (exact ? capture : 0) + lootAward;
    }

    final int scaledCapture;
    if (exact) {
      scaledCapture = capture;
    } else if (difference == 1) {
      scaledCapture = capture ~/ 2;
    } else {
      scaledCapture = 0;
    }
    return scaledCapture + lootAward;
  }

  /// Butin officiel : les deux doivent être exacts.
  /// Règle maison ([classicBonusGate] faux) : l'alliance compte quand même.
  static bool lootAllianceScores({
    required bool exactA,
    required bool exactB,
    required bool classicBonusGate,
  }) =>
      !classicBonusGate || (exactA && exactB);

  /// Nombre d'alliances qui rapportent +20 à [playerId].
  static int lootSharesForPlayer({
    required String playerId,
    required List<LootAlliance> alliances,
    required bool Function(String id) isExact,
    required bool classicBonusGate,
  }) {
    var n = 0;
    for (final a in alliances) {
      if (!a.involves(playerId)) continue;
      if (lootAllianceScores(
        exactA: isExact(a.playerA),
        exactB: isExact(a.playerB),
        classicBonusGate: classicBonusGate,
      )) {
        n++;
      }
    }
    return n;
  }

  /// Somme des plis joueurs + plis hors joueurs (annulés, Barbe Grise) == cartes.
  static bool validateTricksSum(
    List<int> tricks,
    int roundCards, {
    int voidedTricks = 0,
    int ghostTricks = 0,
  }) {
    if (tricks.any((t) => t < 0) || voidedTricks < 0 || ghostTricks < 0) {
      return false;
    }
    final sum = tricks.fold<int>(0, (a, b) => a + b);
    return sum + voidedTricks + ghostTricks == roundCards;
  }

  /// Harry le Géant : ajuste l'enchère de ±1 (ou 0), bornée à [0, cards].
  static int applyHarryBidAdjust(int bid, int delta, int roundCards) {
    if (delta != -1 && delta != 0 && delta != 1) {
      throw ArgumentError('Harry delta must be -1, 0 or 1');
    }
    return (bid + delta).clamp(0, roundCards);
  }

  /// Mise annoncée avant Harry, à partir de la mise effective stockée.
  /// Si l'ajustement a été borné (0 ou le nombre de cartes), on retient
  /// l'extrémité. Les parties nouvelles stockent aussi la mise déclarée.
  static int inferDeclaredBid(int effectiveBid, int harryDelta, int roundCards) {
    final raw = effectiveBid - harryDelta;
    if (raw >= 0 && raw <= roundCards) return raw;
    if (harryDelta > 0) return roundCards;
    if (harryDelta < 0) return 0;
    return effectiveBid.clamp(0, roundCards);
  }

  /// Reconstruit des alliances dont le nombre par joueur correspond aux parts
  /// déjà marquées (anciennes parties sans la liste des paires).
  static List<LootAlliance> alliancesFromShareCounts(
    List<({String playerId, int shares})> shares,
  ) {
    final remaining = <String, int>{
      for (final s in shares)
        if (s.shares > 0) s.playerId: s.shares,
    };
    final out = <LootAlliance>[];
    while (out.length < 8) {
      final ids = remaining.keys.where((id) => (remaining[id] ?? 0) > 0).toList()
        ..sort((a, b) => remaining[b]!.compareTo(remaining[a]!));
      if (ids.length < 2) break;
      final a = ids[0];
      final b = ids[1];
      out.add(LootAlliance(playerA: a, playerB: b));
      remaining[a] = remaining[a]! - 1;
      remaining[b] = remaining[b]! - 1;
    }
    return out;
  }

  /// Quel monstre prime si plusieurs sont dans le même pli.
  /// Sans raie, le comportement historique est conservé : à deux (Kraken +
  /// Baleine), la 2e carte gagne et le défaut (2e inconnue) est le Kraken.
  static SeaMonsterOutcome resolveSeaMonsterClash({
    required bool krakenPresent,
    required bool whalePresent,
    bool stingrayPresent = false,
    String? secondPlayed,
  }) {
    if (!krakenPresent && !whalePresent && !stingrayPresent) {
      throw ArgumentError('Aucun monstre présent');
    }

    if (stingrayPresent && (krakenPresent || whalePresent)) {
      final winner = secondPlayed ?? 'kraken';
      if (winner == 'whale' && whalePresent) {
        return SeaMonsterOutcome.whaleHighestNumber;
      }
      if (winner == 'stingray') {
        return SeaMonsterOutcome.stingrayLowestNumber;
      }
      if (krakenPresent && winner == 'kraken') {
        return SeaMonsterOutcome.krakenDestroys;
      }
      if (whalePresent && !krakenPresent) {
        return SeaMonsterOutcome.whaleHighestNumber;
      }
      return stingrayPresent && !krakenPresent
          ? SeaMonsterOutcome.stingrayLowestNumber
          : SeaMonsterOutcome.krakenDestroys;
    }

    if (stingrayPresent) return SeaMonsterOutcome.stingrayLowestNumber;

    if (krakenPresent && whalePresent) {
      if (secondPlayed == 'whale') {
        return SeaMonsterOutcome.whaleHighestNumber;
      }
      return SeaMonsterOutcome.krakenDestroys;
    }
    if (krakenPresent) return SeaMonsterOutcome.krakenDestroys;
    if (whalePresent) return SeaMonsterOutcome.whaleHighestNumber;
    throw ArgumentError('Aucun monstre présent');
  }

  static String accuracyLabelFr({
    required ScoringSystem scoring,
    required bool cannonball,
    required bool exact,
    required int difference,
  }) {
    if (scoring == ScoringSystem.rascal && cannonball) {
      return exact ? 'Boulet — touché' : 'Boulet — raté';
    }
    if (scoring == ScoringSystem.rascal) {
      if (exact) return 'Coup direct';
      if (difference == 1) return 'Frappe à revers';
      return 'Échec cuisant';
    }
    return exact ? 'Exact' : 'Raté';
  }
}

/// Modes de partie (séquences du journal de bord 2022).
enum GameMode {
  /// 1→10
  standard,

  /// Pas d'impair : 2×(2,4,6,8,10)
  evenKeel,

  /// Attaque éclair / Blitz : 5×5
  blitz,

  /// Tir de barrage : 10×10
  barrage,

  /// Tourbillon : 2×(9,7,5,3,1)
  whirlpool,

  /// L'heure du dodo : 1 carte
  bedtime,

  /// Prêt au combat : 6→10
  skipToBrawl,

  /// Liste libre
  custom,
}

extension GameModeLabel on GameMode {
  String get labelFr {
    switch (this) {
      case GameMode.standard:
        return 'Standard';
      case GameMode.evenKeel:
        return 'Pas d\'impair';
      case GameMode.blitz:
        return 'Attaque éclair';
      case GameMode.barrage:
        return 'Tir de barrage';
      case GameMode.whirlpool:
        return 'Tourbillon';
      case GameMode.bedtime:
        return 'Heure du dodo';
      case GameMode.skipToBrawl:
        return 'Prêt au combat';
      case GameMode.custom:
        return 'Personnalisé';
    }
  }

  String get descriptionFr {
    switch (this) {
      case GameMode.standard:
        return '10 manches : 1, 2, 3 … 10 cartes';
      case GameMode.evenKeel:
        return '10 manches : 2, 2, 4, 4, 6, 6, 8, 8, 10, 10';
      case GameMode.blitz:
        return '5 manches de 5 cartes';
      case GameMode.barrage:
        return '10 manches de 10 cartes';
      case GameMode.whirlpool:
        return '10 manches : 9, 9, 7, 7, 5, 5, 3, 3, 1, 1';
      case GameMode.bedtime:
        return '1 manche de 1 carte, puis bonne nuit';
      case GameMode.skipToBrawl:
        return '5 manches : 6, 7, 8, 9, 10';
      case GameMode.custom:
        return 'Séquence libre (ex. 3, 5, 7, 10)';
    }
  }

  bool get playable => true;
}

List<int> buildRoundSequence(GameMode mode, {List<int>? custom}) {
  switch (mode) {
    case GameMode.standard:
      return List<int>.generate(10, (i) => i + 1);
    case GameMode.evenKeel:
      return [2, 2, 4, 4, 6, 6, 8, 8, 10, 10];
    case GameMode.blitz:
      return [5, 5, 5, 5, 5];
    case GameMode.barrage:
      return List<int>.filled(10, 10);
    case GameMode.whirlpool:
      return [9, 9, 7, 7, 5, 5, 3, 3, 1, 1];
    case GameMode.bedtime:
      return [1];
    case GameMode.skipToBrawl:
      return [6, 7, 8, 9, 10];
    case GameMode.custom:
      if (custom == null || custom.isEmpty) {
        throw ArgumentError('Séquence personnalisée requise');
      }
      if (custom.any((c) => c < 0)) {
        throw ArgumentError('Les valeurs doivent être ≥ 0');
      }
      return List<int>.from(custom);
  }
}

/// Options d'extension activées pour la partie.
class ExpansionOptions {
  final bool kraken;
  final bool whiteWhale;
  final bool harryTheGiant;
  final bool loot;
  final bool rascalWager;

  /// Rappels Tigresse / Scary Mary dans le flux bonus.
  final bool tigressNotes;
  final bool stingray;
  final bool davyJones;
  final bool bonusSevensEights;
  final bool con;
  final bool graybeard;
  final bool rosie;
  final bool bandit;
  final bool juanita;

  const ExpansionOptions({
    this.kraken = false,
    this.whiteWhale = false,
    this.harryTheGiant = false,
    this.loot = false,
    this.rascalWager = false,
    this.tigressNotes = true,
    this.stingray = false,
    this.davyJones = false,
    this.bonusSevensEights = false,
    this.con = false,
    this.graybeard = false,
    this.rosie = false,
    this.bandit = false,
    this.juanita = false,
  });

  bool get anySeaMonster => kraken || whiteWhale || stingray;

  bool get anyTablePower => rosie || bandit || juanita;

  Map<String, dynamic> toJson() => {
        'kraken': kraken,
        'whiteWhale': whiteWhale,
        'harryTheGiant': harryTheGiant,
        'loot': loot,
        'rascalWager': rascalWager,
        'tigressNotes': tigressNotes,
        'stingray': stingray,
        'davyJones': davyJones,
        'bonusSevensEights': bonusSevensEights,
        'con': con,
        'graybeard': graybeard,
        'rosie': rosie,
        'bandit': bandit,
        'juanita': juanita,
      };

  factory ExpansionOptions.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ExpansionOptions();
    return ExpansionOptions(
      kraken: j['kraken'] as bool? ?? false,
      whiteWhale: j['whiteWhale'] as bool? ?? false,
      harryTheGiant: j['harryTheGiant'] as bool? ?? false,
      loot: j['loot'] as bool? ?? false,
      rascalWager: j['rascalWager'] as bool? ?? false,
      tigressNotes: j['tigressNotes'] as bool? ?? true,
      stingray: j['stingray'] as bool? ?? false,
      davyJones: j['davyJones'] as bool? ?? false,
      bonusSevensEights: j['bonusSevensEights'] as bool? ?? false,
      con: j['con'] as bool? ?? false,
      graybeard: j['graybeard'] as bool? ?? false,
      rosie: j['rosie'] as bool? ?? false,
      bandit: j['bandit'] as bool? ?? false,
      juanita: j['juanita'] as bool? ?? false,
    );
  }

  ExpansionOptions copyWith({
    bool? kraken,
    bool? whiteWhale,
    bool? harryTheGiant,
    bool? loot,
    bool? rascalWager,
    bool? tigressNotes,
    bool? stingray,
    bool? davyJones,
    bool? bonusSevensEights,
    bool? con,
    bool? graybeard,
    bool? rosie,
    bool? bandit,
    bool? juanita,
  }) =>
      ExpansionOptions(
        kraken: kraken ?? this.kraken,
        whiteWhale: whiteWhale ?? this.whiteWhale,
        harryTheGiant: harryTheGiant ?? this.harryTheGiant,
        loot: loot ?? this.loot,
        rascalWager: rascalWager ?? this.rascalWager,
        tigressNotes: tigressNotes ?? this.tigressNotes,
        stingray: stingray ?? this.stingray,
        davyJones: davyJones ?? this.davyJones,
        bonusSevensEights: bonusSevensEights ?? this.bonusSevensEights,
        con: con ?? this.con,
        graybeard: graybeard ?? this.graybeard,
        rosie: rosie ?? this.rosie,
        bandit: bandit ?? this.bandit,
        juanita: juanita ?? this.juanita,
      );

  /// Journal de bord 2022 : monstres, butin, pouvoirs de pirate.
  ExpansionOptions get withLogbook2022 => copyWith(
        kraken: true,
        whiteWhale: true,
        harryTheGiant: true,
        loot: true,
        rascalWager: true,
        tigressNotes: true,
        rosie: true,
        bandit: true,
        juanita: true,
      );

  /// Cartes d'extension dont le score se saisit (raie, 7/8, Davy Jones, Con).
  ExpansionOptions get withScoreExpansion => copyWith(
        stingray: true,
        davyJones: true,
        bonusSevensEights: true,
        con: true,
      );
}
