import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../scoring/scoring_engine.dart';
import '../services/game_controller.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'play_screen.dart';
import 'rules_screen.dart';
import 'setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final hasActive = ctrl.game != null && !ctrl.game!.isFinished;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgLift, AppTheme.bg],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const SizedBox(height: 12),
              const _Emblem(),
              const SizedBox(height: 16),
              const Text(
                'Skull King',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Compte-points · non officiel',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted, fontSize: 15),
              ),
              const SizedBox(height: 28),
              if (hasActive) ...[
                _ResumeCard(ctrl: ctrl),
                const SizedBox(height: 14),
              ],
              ElevatedButton.icon(
                key: const Key('home-new'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SetupScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle partie'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('home-history'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('Historique'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('home-rules'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RulesScreen()),
                  );
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Règles / Aide'),
              ),
              const SizedBox(height: 28),
              const Text(
                'Règles Halcyon 2022, Rascal et extensions en saisie de score.\n'
                'Par défaut, les bonus comptent même si la mise est ratée.\n'
                'Aucune affiliation avec ScoreNow ou Grandpa Beck\'s Games.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.anchor, size: 48, color: AppTheme.accent),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final GameController ctrl;
  const _ResumeCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final g = ctrl.game!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Partie en cours · manche ${g.currentRoundIndex + 1}/${g.roundSequence.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${g.mode.labelFr} · ${g.players.length} joueurs',
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlayScreen()),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Reprendre'),
            ),
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Abandonner ?'),
                    content: const Text(
                      'La partie en cours sera perdue (non archivée).',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Abandonner'),
                      ),
                    ],
                  ),
                );
                if (ok == true) await ctrl.abandonGame();
              },
              child: const Text(
                'Abandonner la partie',
                style: TextStyle(color: AppTheme.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
