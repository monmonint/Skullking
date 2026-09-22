import 'package:flutter/material.dart';
import '../scoring/scoring_engine.dart';
import '../models/game_models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GameState> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await StorageService().loadHistory();
    setState(() {
      _games = h;
      _loading = false;
    });
  }

  String _fmt(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yy = local.year;
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
              ? const Center(
                  child: Text('Aucune partie enregistrée',
                      style: TextStyle(color: AppTheme.muted)))
              : ListView.builder(
                  itemCount: _games.length,
                  itemBuilder: (_, i) {
                    final g = _games[i];
                    final ranked = g.rankedPlayers();
                    final winner = ranked.isNotEmpty ? ranked.first : null;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ExpansionTile(
                        title: Text(
                          winner != null
                              ? 'Gagnant : ${winner.name} (${g.totalFor(winner.id)} pts)'
                              : 'Partie',
                        ),
                        subtitle: Text(
                          '${_fmt(g.updatedAt)} · ${g.players.length} joueurs · ${g.mode.labelFr}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.muted),
                        ),
                        children: ranked
                            .map((p) => ListTile(
                                  dense: true,
                                  title: Text(p.name),
                                  trailing: Text('${g.totalFor(p.id)} pts'),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
