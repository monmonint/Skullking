import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';
import '../stats/career_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/player_face.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  CareerSnapshot _snap = CareerSnapshot.empty;
  bool _loading = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final storage = context.read<GameController>().storage;
    final history = await storage.loadHistory();
    if (!mounted) return;
    setState(() {
      _snap = buildCareer(history);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _snap.players.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucune partie archivée.\nLes stats se remplissent après « Enregistrer et quitter ».',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted, height: 1.4),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _snap.players.length,
                  itemBuilder: (_, i) => _PlayerStatsCard(
                    career: _snap.players[i],
                    index: i,
                  ),
                ),
    );
  }
}

class _PlayerStatsCard extends StatefulWidget {
  final PlayerCareer career;
  final int index;
  const _PlayerStatsCard({required this.career, required this.index});

  @override
  State<_PlayerStatsCard> createState() => _PlayerStatsCardState();
}

class _PlayerStatsCardState extends State<_PlayerStatsCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.career;
    final pct = (c.winRate * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlayerFace(name: c.name, index: widget.index),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 18)),
                        Text(
                          '${c.games} partie${c.games > 1 ? 's' : ''} · ${c.wins} victoire${c.wins > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: AppTheme.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$pct %',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tile('Mises exactes', '${(c.exactRate * 100).round()} %'),
                  _tile('Meilleur score', '${c.highest}'),
                  _tile('Moyenne', c.avgScore.toStringAsFixed(0)),
                  _tile('Manches > 0', '${(c.positiveRate * 100).round()} %'),
                  _tile('Écart moyen', c.avgGap.toStringAsFixed(1)),
                  _tile('Mises à 0', '${(c.zeroRate * 100).round()} %'),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _open = !_open),
                child: Text(_open ? 'Masquer le détail' : 'Voir le détail'),
              ),
              if (_open) ...[
                Text(
                  'Bonus collectés · ${c.bonusPoints} pts',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppTheme.accent),
                ),
                const SizedBox(height: 6),
                _bonusLine('14 couleur', c.colorFourteens),
                _bonusLine('14 noir', c.blackFourteens),
                _bonusLine('Pirates capturés', c.pirates),
                _bonusLine('Sirènes capturées', c.mermaids),
                _bonusLine('Skull King capturé', c.skullKings),
                _bonusLine('Butin', c.loot),
                _bonusLine('8', c.eights),
                _bonusLine('7', c.sevens),
                _bonusLine('Davy Jones', c.leviathans),
                _bonusLine('Con', c.cons),
                const SizedBox(height: 10),
                const Text('Taux de réussite par manche',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (c.byRound.isEmpty)
                  const Text('—', style: TextStyle(color: AppTheme.muted))
                else
                  for (final index in (c.byRound.keys.toList()..sort()))
                    _bar(c.byRound[index]!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _bonusLine(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _bar(RoundRate rate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('M${rate.index + 1}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: rate.rate,
                minHeight: 10,
                backgroundColor: AppTheme.surface2,
                color: AppTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(rate.rate * 100).round()}%',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
