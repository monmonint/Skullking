import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';
import '../theme/app_theme.dart';
import 'setup_screen.dart';
import 'history_screen.dart';
import 'play_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final hasActive = ctrl.game != null && !ctrl.game!.isFinished;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.sailing, size: 72, color: AppTheme.accent),
              const SizedBox(height: 12),
              const Text(
                'Skull King',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.text,
                ),
              ),
              const Text(
                'Compte-points · non officiel',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted, fontSize: 14),
              ),
              const SizedBox(height: 40),
              if (hasActive) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PlayScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'Reprendre la partie\nManche ${ctrl.game!.currentRoundIndex + 1}/${ctrl.game!.roundSequence.length}',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
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
                  child: const Text('Abandonner la partie'),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SetupScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle partie'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('Historique'),
              ),
              const Spacer(),
              const Text(
                'Règles Halcyon 2021/2022 · hors ligne\n'
                'Aucune affiliation avec ScoreNow / Grand Prix Games',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
