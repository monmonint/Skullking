/// Moteur de score Skull King — règles classiques Halcyon / Grandpa Beck's 2022.
/// Séparé de l'UI pour tests unitaires.
library;

class RoundBonuses {
  /// 14 de couleur classique (jaune / vert / violet) en possession en fin de manche.
  final int colorFourteens;

  /// 14 noir (drapeau / atout).
  final int blackFourteens;

  /// Sirènes capturées par un pirate (Tigresse-pirate ou Scary Mary-pirate comptent).
  final int mermaidByPirate;

  /// Pirates capturés par Skull King (Tigresse-pirate / Scary Mary-pirate comptent ;
  /// Tigresse-fuite ne compte PAS).
  final int pirateBySkullKing;

  /// Skull King capturé par une sirène (+40 Halcyon 2022).
  final int skullKingByMermaid;

  /// Alliances Butin réussies (chaque alliance exacte des DEUX joueurs → +20).
  final int lootAlliances;

  const RoundBonuses({
    this.colorFourteens = 0,
    this.blackFourteens = 0,
    this.mermaidByPirate = 0,
    this.pirateBySkullKing = 0,
    this.skullKingByMermaid = 0,
    this.lootAlliances = 0,
  });

  int get totalPoints =>
      colorFourteens * 10 +
      blackFourteens * 20 +
      mermaidByPirate * 20 +
      pirateBySkullKing * 30 +
      skullKingByMermaid * 40 +
      lootAlliances * 20;

  Map<String, dynamic> toJson() => {
        'colorFourteens': colorFourteens,
        'blackFourteens': blackFourteens,
        'mermaidByPirate': mermaidByPirate,
        'pirateBySkullKing': pirateBySkullKing,
        'skullKingByMermaid': skullKingByMermaid,
        'lootAlliances': lootAlliances,
      };

  factory RoundBonuses.fromJson(Map<String, dynamic> j) => RoundBonuses(
        colorFourteens: j['colorFourteens'] as int? ?? 0,
        blackFourteens: j['blackFourteens'] as int? ?? 0,
        mermaidByPirate: j['mermaidByPirate'] as int? ?? 0,
        pirateBySkullKing: j['pirateBySkullKing'] as int? ?? 0,
        skullKingByMermaid: j['skullKingByMermaid'] as int? ?? 0,
        lootAlliances: j['lootAlliances'] as int? ?? 0,
      );

  RoundBonuses copyWith({
    int? colorFourteens,
    int? blackFourteens,
    int? mermaidByPirate,
    int? pirateBySkullKing,
    int? skullKingByMermaid,
    int? lootAlliances,
  }) =>
      RoundBonuses(
        colorFourteens: colorFourteens ?? this.colorFourteens,
        blackFourteens: blackFourteens ?? this.blackFourteens,
        mermaidByPirate: mermaidByPirate ?? this.mermaidByPirate,
        pirateBySkullKing: pirateBySkullKing ?? this.pirateBySkullKing,
        skullKingByMermaid: skullKingByMermaid ?? this.skullKingByMermaid,
        lootAlliances: lootAlliances ?? this.lootAlliances,
      );
}

class ScoreResult {
  final int bidScore;
  final int bonusScore;
  final int rascalWagerScore;
  final int total;
  final bool exact;
  final bool wasBidZero;

  const ScoreResult({
    required this.bidScore,
    required this.bonusScore,
    required this.rascalWagerScore,
    required this.total,
    required this.exact,
    required this.wasBidZero,
  });
}

/// Effet d'un pli avec monstre marin (pour aide / validation).
enum SeaMonsterOutcome {
  /// Kraken (ou 2e carte = Kraken) : pli détruit, personne ne gagne.
  krakenDestroys,

  /// Baleine : plus haut numéro gagne (suits ignorées ; spéciaux = fuites).
  whaleHighestNumber,

  /// Baleine mais uniquement des spéciaux : pli défaussé.
  whaleAllSpecialsDiscarded,
}

class ScoringEngine {
  /// Score classique Halcyon / Grandpa Beck's 2022.
  ///
  /// [rascalWager] : pari Rascal le Flambeur (0, 10 ou 20).
  /// Exact → +wager ; raté → −wager. Indépendant des bonus de capture.
  static ScoreResult score({
    required int bid,
    required int tricks,
    required int roundCards,
    RoundBonuses bonuses = const RoundBonuses(),
    bool bonusesEnabled = true,
    int rascalWager = 0,
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

    int bidScore;
    if (wasBidZero) {
      bidScore = exact ? 10 * roundCards : -10 * roundCards;
    } else if (exact) {
      bidScore = 20 * tricks;
    } else {
      bidScore = -10 * (tricks - bid).abs();
    }

    final bonusScore =
        (exact && bonusesEnabled) ? bonuses.totalPoints : 0;

    final rascalWagerScore =
        rascalWager == 0 ? 0 : (exact ? rascalWager : -rascalWager);

    return ScoreResult(
      bidScore: bidScore,
      bonusScore: bonusScore,
      rascalWagerScore: rascalWagerScore,
      total: bidScore + bonusScore + rascalWagerScore,
      exact: exact,
      wasBidZero: wasBidZero,
    );
  }

  /// Somme des plis joueurs + plis annulés (Kraken / Baleine-spéciaux) == cartes.
  static bool validateTricksSum(
    List<int> tricks,
    int roundCards, {
    int voidedTricks = 0,
  }) {
    if (tricks.any((t) => t < 0) || voidedTricks < 0) return false;
    final sum = tricks.fold<int>(0, (a, b) => a + b);
    return sum + voidedTricks == roundCards;
  }

  /// Harry le Géant : ajuste l'enchère de ±1 (ou 0 = inchangé), bornée à [0, cards].
  static int applyHarryBidAdjust(int bid, int delta, int roundCards) {
    if (delta != -1 && delta != 0 && delta != 1) {
      throw ArgumentError('Harry delta must be -1, 0 or 1');
    }
    return (bid + delta).clamp(0, roundCards);
  }

  /// Résout quel monstre prime si les deux sont dans le même pli.
  /// [secondPlayed] : 'kraken' ou 'whale'.
  static SeaMonsterOutcome resolveSeaMonsterClash({
    required bool krakenPresent,
    required bool whalePresent,
    String? secondPlayed,
  }) {
    if (krakenPresent && whalePresent) {
      if (secondPlayed == 'whale') {
        return SeaMonsterOutcome.whaleHighestNumber;
      }
      // Kraken second (ou défaut) : détruit
      return SeaMonsterOutcome.krakenDestroys;
    }
    if (krakenPresent) return SeaMonsterOutcome.krakenDestroys;
    if (whalePresent) return SeaMonsterOutcome.whaleHighestNumber;
    throw ArgumentError('Aucun monstre présent');
  }
}

/// Modes de partie (séquences officielles journal de bord 2022).
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
        return 'Standard (1→10)';
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
        return '10 manches : 1,2,3…10 cartes';
      case GameMode.evenKeel:
        return '10 manches : 2,2,4,4,6,6,8,8,10,10';
      case GameMode.blitz:
        return '5 manches de 5 cartes';
      case GameMode.barrage:
        return '10 manches de 10 cartes';
      case GameMode.whirlpool:
        return '10 manches : 9,9,7,7,5,5,3,3,1,1';
      case GameMode.bedtime:
        return '1 manche de 1 carte (+ bisou)';
      case GameMode.skipToBrawl:
        return '5 manches : 6,7,8,9,10';
      case GameMode.custom:
        return 'Séquence libre (ex. 3,5,7,10)';
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
  /// Notes Tigresse / Scary Mary dans le flux bonus (toujours informatif).
  final bool tigressNotes;

  const ExpansionOptions({
    this.kraken = false,
    this.whiteWhale = false,
    this.harryTheGiant = false,
    this.loot = false,
    this.rascalWager = false,
    this.tigressNotes = true,
  });

  Map<String, dynamic> toJson() => {
        'kraken': kraken,
        'whiteWhale': whiteWhale,
        'harryTheGiant': harryTheGiant,
        'loot': loot,
        'rascalWager': rascalWager,
        'tigressNotes': tigressNotes,
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
    );
  }

  ExpansionOptions copyWith({
    bool? kraken,
    bool? whiteWhale,
    bool? harryTheGiant,
    bool? loot,
    bool? rascalWager,
    bool? tigressNotes,
  }) =>
      ExpansionOptions(
        kraken: kraken ?? this.kraken,
        whiteWhale: whiteWhale ?? this.whiteWhale,
        harryTheGiant: harryTheGiant ?? this.harryTheGiant,
        loot: loot ?? this.loot,
        rascalWager: rascalWager ?? this.rascalWager,
        tigressNotes: tigressNotes ?? this.tigressNotes,
      );
}
