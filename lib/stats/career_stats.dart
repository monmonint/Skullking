import '../models/game_models.dart';

class RoundRate {
  final int index;
  int played = 0;
  int exact = 0;

  RoundRate(this.index);

  double get rate => played == 0 ? 0 : exact / played;
}

class PlayerCareer {
  final String name;
  int games = 0;
  int wins = 0;
  int rounds = 0;
  int exact = 0;
  int positiveRounds = 0;
  int zeroBids = 0;
  int zeroHits = 0;
  int gapSum = 0;
  int gameScoreSum = 0;
  int highest = 0;
  int bonusPoints = 0;
  int colorFourteens = 0;
  int blackFourteens = 0;
  int mermaids = 0;
  int pirates = 0;
  int skullKings = 0;
  int loot = 0;
  int eights = 0;
  int sevens = 0;
  int leviathans = 0;
  int cons = 0;
  final Map<int, RoundRate> byRound = {};

  PlayerCareer(this.name);

  double get exactRate => rounds == 0 ? 0 : exact / rounds;
  double get winRate => games == 0 ? 0 : wins / games;
  double get positiveRate => rounds == 0 ? 0 : positiveRounds / rounds;
  double get avgGap => rounds == 0 ? 0 : gapSum / rounds;
  double get avgScore => games == 0 ? 0 : gameScoreSum / games;
  double get zeroRate => zeroBids == 0 ? 0 : zeroHits / zeroBids;
}

class CareerSnapshot {
  final int games;
  final int uniquePlayers;
  final double avgPlayers;
  final String? recentWinner;
  final int? recentWinnerScore;
  final int highestScore;
  final String? highestName;
  final List<PlayerCareer> players;

  const CareerSnapshot({
    required this.games,
    required this.uniquePlayers,
    required this.avgPlayers,
    required this.recentWinner,
    required this.recentWinnerScore,
    required this.highestScore,
    required this.highestName,
    required this.players,
  });

  static const empty = CareerSnapshot(
    games: 0,
    uniquePlayers: 0,
    avgPlayers: 0,
    recentWinner: null,
    recentWinnerScore: null,
    highestScore: 0,
    highestName: null,
    players: [],
  );
}

CareerSnapshot buildCareer(List<GameState> history) {
  final map = <String, PlayerCareer>{};
  String? recentWinner;
  int? recentScore;
  var highest = 0;
  String? highestName;
  var playerSlots = 0;

  for (var gi = 0; gi < history.length; gi++) {
    final g = history[gi];
    playerSlots += g.players.length;
    if (g.players.isEmpty || g.completedRounds.isEmpty) continue;
    final ranked = g.rankedPlayers();
    final topScore = g.totalFor(ranked.first.id);
    final winners = ranked.where((p) => g.totalFor(p.id) == topScore).toList();
    if (gi == 0) {
      recentWinner = winners.map((p) => p.name).join(', ');
      recentScore = topScore;
    }
    for (final p in g.players) {
      final total = g.totalFor(p.id);
      final career = map.putIfAbsent(p.name, () => PlayerCareer(p.name));
      career.games++;
      career.gameScoreSum += total;
      if (total > career.highest) career.highest = total;
      if (total > highest) {
        highest = total;
        highestName = p.name;
      }
      if (winners.any((w) => w.id == p.id)) career.wins++;
      for (final round in g.completedRounds) {
        for (final r in round.results) {
          if (r.playerId != p.id) continue;
          career.rounds++;
          final gap = (r.tricks - r.bid).abs();
          career.gapSum += gap;
          if (r.bid == r.tricks) career.exact++;
          if (r.total > 0) career.positiveRounds++;
          if (r.bid == 0) {
            career.zeroBids++;
            if (r.tricks == 0) career.zeroHits++;
          }
          career.bonusPoints += r.bonusScore;
          career.colorFourteens += r.bonuses.colorFourteens;
          career.blackFourteens += r.bonuses.blackFourteens;
          career.mermaids += r.bonuses.mermaidByPirate;
          career.pirates += r.bonuses.pirateBySkullKing;
          career.skullKings += r.bonuses.skullKingByMermaid;
          career.loot += r.bonuses.lootAlliances;
          career.eights += r.bonuses.eights;
          career.sevens += r.bonuses.sevens;
          career.leviathans += r.bonuses.davyJonesSeaMonsters;
          career.cons += r.bonuses.conCaptured;
          final rate = career.byRound.putIfAbsent(
            round.index,
            () => RoundRate(round.index),
          );
          rate.played++;
          if (r.bid == r.tricks) rate.exact++;
        }
      }
    }
  }

  final players = map.values.toList()
    ..sort((a, b) {
      final byWins = b.wins.compareTo(a.wins);
      if (byWins != 0) return byWins;
      return b.highest.compareTo(a.highest);
    });

  return CareerSnapshot(
    games: history.where((g) => g.completedRounds.isNotEmpty).length,
    uniquePlayers: map.length,
    avgPlayers: history.isEmpty ? 0 : playerSlots / history.length,
    recentWinner: recentWinner,
    recentWinnerScore: recentScore,
    highestScore: highest,
    highestName: highestName,
    players: players,
  );
}
