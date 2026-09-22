import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../scoring/scoring_engine.dart';
import '../services/game_controller.dart';
import '../theme/app_theme.dart';
import 'summary_screen.dart';

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final g = ctrl.game;
    if (g == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partie')),
        body: const Center(child: Text('Aucune partie active')),
      );
    }

    if (g.isFinished && ctrl.phase == RoundPhase.review) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SummaryScreen()),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          g.isFinished
              ? 'Fin de partie'
              : 'M${g.currentRoundIndex + 1}/${g.roundSequence.length} · ${g.currentCards} carte${g.currentCards > 1 ? 's' : ''}',
        ),
        actions: [
          IconButton(
            tooltip: 'Classement',
            icon: const Icon(Icons.leaderboard),
            onPressed: () => _showLeaderboard(context, g),
          ),
        ],
      ),
      body: _body(context, ctrl, g),
    );
  }

  Widget _body(BuildContext context, GameController ctrl, GameState g) {
    switch (ctrl.phase) {
      case RoundPhase.bidding:
        return _BiddingPhase(ctrl: ctrl, game: g);
      case RoundPhase.harry:
        return _HarryPhase(ctrl: ctrl, game: g);
      case RoundPhase.tricks:
        return _TricksPhase(ctrl: ctrl, game: g);
      case RoundPhase.bonuses:
        return _BonusesPhase(ctrl: ctrl, game: g);
      case RoundPhase.review:
        return _ReviewPhase(ctrl: ctrl, game: g);
    }
  }

  void _showLeaderboard(BuildContext context, GameState g) {
    final ranked = g.rankedPlayers();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Classement',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...ranked.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final st = g.exactRoundsFor(p.id);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      i == 0 ? AppTheme.accent : AppTheme.surface2,
                  foregroundColor: i == 0 ? Colors.black : AppTheme.text,
                  child: Text('${i + 1}'),
                ),
                title: Text(p.name),
                subtitle: Text(
                  'Exactes ${st['exact']}/${st['played']}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                trailing: Text(
                  '${g.totalFor(p.id)} pts',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BiddingPhase extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  const _BiddingPhase({required this.ctrl, required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Enchères — combien de plis chaque joueur annonce ?',
            style: TextStyle(color: AppTheme.muted),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: game.players.length,
            itemBuilder: (_, i) {
              final p = game.players[i];
              final bid = game.pendingBids[p.id] ?? 0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Enchère : $bid'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed:
                            bid > 0 ? () => ctrl.setBid(p.id, bid - 1) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$bid',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: bid < game.currentCards
                            ? () => ctrl.setBid(p.id, bid + 1)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => ctrl.confirmBids(),
            child: Text(game.expansions.harryTheGiant
                ? 'Continuer (Harry le Géant)'
                : 'Valider les enchères'),
          ),
        ),
      ],
    );
  }
}

class _HarryPhase extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  const _HarryPhase({required this.ctrl, required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Harry le Géant — pour chaque joueur qui a utilisé le pouvoir '
            '(gagné un pli avec Harry), ajustez la mise de ±1 ou laissez 0.',
            style: TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: game.players.length,
            itemBuilder: (_, i) {
              final p = game.players[i];
              final base = game.pendingBids[p.id] ?? 0;
              final d = game.pendingHarryDeltas[p.id] ?? 0;
              final eff = game.effectiveBid(p.id);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Base $base → effective $eff'),
                  trailing: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: -1, label: Text('-1')),
                      ButtonSegment(value: 0, label: Text('0')),
                      ButtonSegment(value: 1, label: Text('+1')),
                    ],
                    selected: {d},
                    onSelectionChanged: (s) =>
                        ctrl.setHarryDelta(p.id, s.first),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => ctrl.confirmHarry(),
            child: const Text('Valider et jouer les plis'),
          ),
        ),
      ],
    );
  }
}

class _TricksPhase extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  const _TricksPhase({required this.ctrl, required this.game});

  @override
  Widget build(BuildContext context) {
    final sum = game.players
        .map((p) => game.pendingTricks[p.id] ?? 0)
        .fold<int>(0, (a, b) => a + b);
    final monsters = game.expansions.kraken || game.expansions.whiteWhale;
    final voided = monsters ? game.pendingVoidedTricks : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            monsters
                ? 'Plis $sum + annulés $voided / ${game.currentCards}'
                : 'Plis remportés — somme $sum / ${game.currentCards}',
            style: TextStyle(
              color: (sum + voided) == game.currentCards
                  ? AppTheme.success
                  : AppTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (monsters)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: AppTheme.surface2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Plis annulés (Kraken / Baleine-spéciaux)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (game.expansions.kraken)
                          'Kraken : pli détruit, personne ne gagne.',
                        if (game.expansions.whiteWhale)
                          'Baleine : plus haut nº gagne ; si que des spéciaux → annulé.',
                        'Si les deux : la 2ᵉ carte prime (l\'autre = fuite).',
                      ].join(' '),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.muted),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: voided > 0
                              ? () => ctrl.setVoidedTricks(voided - 1)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$voided',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: voided < game.currentCards
                              ? () => ctrl.setVoidedTricks(voided + 1)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (ctrl.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(ctrl.errorMessage!,
                style: const TextStyle(color: AppTheme.danger)),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: game.players.length,
            itemBuilder: (_, i) {
              final p = game.players[i];
              final tricks = game.pendingTricks[p.id] ?? 0;
              final bid = game.effectiveBid(p.id);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Enchère $bid · Plis $tricks'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: tricks > 0
                            ? () => ctrl.setTricks(p.id, tricks - 1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$tricks',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: tricks < game.currentCards
                            ? () => ctrl.setTricks(p.id, tricks + 1)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => ctrl.confirmTricks(),
            child: Text(game.bonusesEnabled ||
                    game.expansions.rascalWager ||
                    game.expansions.loot
                ? 'Continuer (bonus / paris)'
                : 'Calculer les scores'),
          ),
        ),
      ],
    );
  }
}

class _BonusesPhase extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  const _BonusesPhase({required this.ctrl, required this.game});

  @override
  Widget build(BuildContext context) {
    final exactPlayers = game.players.where((p) {
      return game.effectiveBid(p.id) == (game.pendingTricks[p.id] ?? 0);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            game.expansions.tigressNotes
                ? 'Bonus si enchère exacte. Tigresse/Scary Mary = pirate si jouées en pirate '
                    '(pas de bonus capture si Tigresse-fuite).'
                : 'Bonus si enchère exacte.',
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (game.expansions.rascalWager) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Pari Rascal (tous les joueurs)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...game.players.map((p) {
                  final w = game.pendingRascalWagers[p.id] ?? 0;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text(p.name),
                      trailing: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('0')),
                          ButtonSegment(value: 10, label: Text('10')),
                          ButtonSegment(value: 20, label: Text('20')),
                        ],
                        selected: {w},
                        onSelectionChanged: (s) =>
                            ctrl.setRascalWager(p.id, s.first),
                      ),
                    ),
                  );
                }),
              ],
              if (game.bonusesEnabled && exactPlayers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Personne n\'a réussi son enchère — pas de bonus de capture.',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (game.bonusesEnabled)
                ...exactPlayers.map((p) {
                  final b =
                      game.pendingBonuses[p.id] ?? const RoundBonuses();
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          _bonusRow('14 couleur (+10)', b.colorFourteens, (v) {
                            ctrl.setBonuses(
                                p.id, b.copyWith(colorFourteens: v));
                          }),
                          _bonusRow('14 noir (+20)', b.blackFourteens, (v) {
                            ctrl.setBonuses(
                                p.id, b.copyWith(blackFourteens: v));
                          }),
                          _bonusRow('Sirène par pirate (+20)',
                              b.mermaidByPirate, (v) {
                            ctrl.setBonuses(
                                p.id, b.copyWith(mermaidByPirate: v));
                          }),
                          _bonusRow('Pirate par Skull King (+30)',
                              b.pirateBySkullKing, (v) {
                            ctrl.setBonuses(
                                p.id, b.copyWith(pirateBySkullKing: v));
                          }),
                          _bonusRow('Skull King par sirène (+40)',
                              b.skullKingByMermaid, (v) {
                            ctrl.setBonuses(
                                p.id, b.copyWith(skullKingByMermaid: v));
                          }),
                          if (game.expansions.loot)
                            _bonusRow('Alliances Butin (+20 chacune)',
                                b.lootAlliances, (v) {
                              ctrl.setBonuses(
                                  p.id, b.copyWith(lootAlliances: v));
                            }),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => ctrl.confirmBonuses(),
            child: const Text('Calculer les scores'),
          ),
        ),
      ],
    );
  }

  Widget _bonusRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text('$value',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < 10 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ReviewPhase extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  const _ReviewPhase({required this.ctrl, required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.completedRounds.isEmpty) {
      return const Center(child: Text('—'));
    }
    final last = game.completedRounds.last;
    final ranked = game.rankedPlayers();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Manche ${last.index + 1} terminée (${last.cards} cartes'
            '${last.voidedTricks > 0 ? ', ${last.voidedTricks} annulé(s)' : ''})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              ...last.results.map((r) {
                final name = game.players
                    .firstWhere((p) => p.id == r.playerId)
                    .name;
                final sign = r.total >= 0 ? '+' : '';
                final extras = <String>[];
                if (r.bonusScore != 0) extras.add('Bonus +${r.bonusScore}');
                if (r.rascalWagerScore != 0) {
                  extras.add(
                      'Rascal ${r.rascalWagerScore > 0 ? '+' : ''}${r.rascalWagerScore}');
                }
                if (r.harryDelta != 0) {
                  extras.add('Harry ${r.harryDelta > 0 ? '+' : ''}${r.harryDelta}');
                }
                return ListTile(
                  title: Text(name),
                  subtitle: Text(
                    'Enchère ${r.bid} · Plis ${r.tricks}'
                    '${extras.isEmpty ? '' : ' · ${extras.join(' · ')}'}',
                  ),
                  trailing: Text(
                    '$sign${r.total}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: r.total >= 0 ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                );
              }),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Classement général',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...ranked.asMap().entries.map((e) {
                final p = e.value;
                final st = game.exactRoundsFor(p.id);
                return ListTile(
                  leading: Text('#${e.key + 1}',
                      style: const TextStyle(color: AppTheme.accent)),
                  title: Text(p.name),
                  subtitle: Text('Exactes ${st['exact']}/${st['played']}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Text('${game.totalFor(p.id)} pts',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              if (game.isFinished) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SummaryScreen()),
                );
              } else {
                ctrl.nextRoundOrFinish();
              }
            },
            child: Text(game.isFinished
                ? 'Voir le résumé final'
                : 'Manche suivante'),
          ),
        ),
      ],
    );
  }
}
