import 'package:flutter/material.dart';
import '../scoring/scoring_engine.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'play_screen.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final g = ctrl.game;
    if (g == null) {
      return const Scaffold(body: Center(child: Text('Partie introuvable')));
    }
    final ranked = g.rankedPlayers();
    final winner = ranked.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé final'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.emoji_events, size: 64, color: AppTheme.accent),
          const SizedBox(height: 8),
          Text(
            'Vainqueur : ${winner.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(
            '${g.totalFor(winner.id)} points · ${g.mode.labelFr}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.accent, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ...ranked.asMap().entries.map((e) {
            final p = e.value;
            final st = g.exactRoundsFor(p.id);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      e.key == 0 ? AppTheme.accent : AppTheme.surface2,
                  foregroundColor: e.key == 0 ? Colors.black : AppTheme.text,
                  child: Text('${e.key + 1}'),
                ),
                title: Text(p.name),
                subtitle: Text('Mises exactes ${st['exact']}/${st['played']}'),
                trailing: Text(
                  '${g.totalFor(p.id)} pts',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Détail par manche',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...g.completedRounds.map((r) {
            return ExpansionTile(
              title: Text(
                'Manche ${r.index + 1} (${r.cards} cartes'
                '${r.voidedTricks > 0 ? ', ${r.voidedTricks} annulés' : ''})',
              ),
              children: r.results.map((pr) {
                final name =
                    g.players.firstWhere((p) => p.id == pr.playerId).name;
                return ListTile(
                  dense: true,
                  title: Text(name),
                  subtitle: Text('E${pr.bid} / P${pr.tricks}'),
                  trailing: Text('${pr.total >= 0 ? '+' : ''}${pr.total}'),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await ctrl.rematch();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PlayScreen()),
              );
            },
            child: const Text('Revanche (mêmes joueurs)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await ctrl.finishAndArchive();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
            child: const Text('Enregistrer et quitter'),
          ),
        ],
      ),
    );
  }
}
