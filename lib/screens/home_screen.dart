import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';
import '../stats/career_stats.dart';
import '../theme/app_theme.dart';
import '../update/update_prompt.dart';
import 'history_screen.dart';
import 'play_screen.dart';
import 'rules_screen.dart';
import 'setup_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CareerSnapshot _snap = CareerSnapshot.empty;
  bool _started = false;
  bool _updateChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
    if (UpdateLaunch.enabledOf(context) && !_updateChecked) {
      _updateChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        checkForAppUpdate(context, manual: false);
      });
    }
  }

  Future<void> _load() async {
    final storage = context.read<GameController>().storage;
    final history = await storage.loadHistory();
    if (!mounted) return;
    setState(() => _snap = buildCareer(history));
  }

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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Skull King',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('home-rules'),
                    tooltip: 'Règles / Aide',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RulesScreen()),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                  ),
                  PopupMenuButton<String>(
                    key: const Key('home-menu'),
                    tooltip: 'Menu',
                    onSelected: (value) {
                      if (value == 'update') {
                        checkForAppUpdate(context, manual: true);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'update',
                        child: Text('Rechercher une mise à jour'),
                      ),
                    ],
                  ),
                ],
              ),
              const Text(
                'Compte-points · non officiel',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 16),
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
              if (hasActive) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PlayScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'Reprendre · manche ${ctrl.game!.currentRoundIndex + 1}/${ctrl.game!.roundSequence.length}',
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Tableau de bord',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Parties jouées',
                      value: '${_snap.games}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Joueurs',
                      value: '${_snap.uniquePlayers}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Dernier vainqueur',
                      value: _snap.recentWinner ?? '—',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Joueurs / partie',
                      value: _snap.games == 0
                          ? '—'
                          : _snap.avgPlayers.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _StatCard(
                label: 'Meilleur score',
                value: _snap.highestName == null
                    ? '—'
                    : '${_snap.highestScore} · ${_snap.highestName}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Par défaut, les bonus comptent même si la mise est ratée.\n'
                'Aucune affiliation avec ScoreNow ou Grandpa Beck\'s Games.',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) => _nav(context, ctrl, hasActive, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.anchor_outlined),
            selectedIcon: Icon(Icons.anchor),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Partie',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  void _nav(BuildContext context, GameController ctrl, bool hasActive, int i) {
    switch (i) {
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                hasActive ? const PlayScreen() : const SetupScreen(),
          ),
        );
      case 2:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
      case 3:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StatsScreen()));
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
