import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../scoring/scoring_engine.dart';
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
    if (g == null || g.rankedPlayers().isEmpty) {
      return const Scaffold(body: Center(child: Text('Partie introuvable')));
    }
    final ranked = g.rankedPlayers();
    final winner = ranked.first;
    final gate = g.classicBonusGate
        ? 'Bonus seulement si enchère exacte'
        : 'Bonus même si la mise est ratée';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé final'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.emoji_events, size: 64, color: AppTheme.gold),
          const SizedBox(height: 8),
          Text(
            winner.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Text(
            '${g.totalFor(winner.id)} points',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${g.mode.labelFr} · ${g.scoring.labelFr}\n$gate',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, height: 1.35),
          ),
          const SizedBox(height: 20),
          ...ranked.asMap().entries.map((e) {
            final p = e.value;
            final st = g.exactRoundsFor(p.id);
            final top = e.key == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: top ? AppTheme.gold : AppTheme.surface2,
                    foregroundColor: top ? AppTheme.ink : AppTheme.text,
                    child: Text('${e.key + 1}'),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Mises exactes ${st['exact']}/${st['played']}'),
                  trailing: Text(
                    '${g.totalFor(p.id)} pts',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text('Détail par manche',
              style: TextStyle(fontWeight: FontWeight.w800)),
          ...g.completedRounds.map((r) {
            return ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Manche ${r.index + 1} · ${r.cards} carte${r.cards > 1 ? 's' : ''}'
                '${r.voidedTricks > 0 ? ' · ${r.voidedTricks} annulés' : ''}',
              ),
              children: r.results.map((pr) {
                final name = g.nameOf(pr.playerId) ?? pr.playerId;
                final bonus = pr.bonusScore == 0
                    ? ''
                    : ' · bonus ${pr.bonusScore > 0 ? '+' : ''}${pr.bonusScore}';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(name),
                  subtitle: Text('E${pr.bid} / P${pr.tricks}$bonus'),
                  trailing: Text(
                    '${pr.total >= 0 ? '+' : ''}${pr.total}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: pr.total >= 0 ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 16),
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
          const SizedBox(height: 10),
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
