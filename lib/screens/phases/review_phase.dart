import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../theme/app_theme.dart';

class ReviewPhase extends StatelessWidget {
  final GameState game;
  const ReviewPhase({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.completedRounds.isEmpty) {
      return const Center(child: Text('—'));
    }
    final last = game.completedRounds.last;
    final ranked = game.rankedPlayers();
    final extras = <String>[
      if (last.voidedTricks > 0) '${last.voidedTricks} annulé(s)',
      if (last.ghostTricks > 0) '${last.ghostTricks} Barbe Grise',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Text(
          'Manche ${last.index + 1} terminée (${last.cards} carte${last.cards > 1 ? 's' : ''}'
          '${extras.isEmpty ? '' : ', ${extras.join(', ')}'})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final r in last.results) _resultTile(r),
        const SizedBox(height: 8),
        const Text('Classement',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4),
        for (var i = 0; i < ranked.length; i++) _rankTile(ranked[i], i),
      ],
    );
  }

  Widget _resultTile(PlayerRoundResult r) {
    final name = game.nameOf(r.playerId) ?? r.playerId;
    final sign = r.total >= 0 ? '+' : '';
    final bits = <String>[
      'Enchère ${r.bid} · Plis ${r.tricks}',
      if (r.bonusScore != 0)
        'Bonus ${r.bonusScore > 0 ? '+' : ''}${r.bonusScore}',
      if (r.rascalWagerScore != 0)
        'Rascal ${r.rascalWagerScore > 0 ? '+' : ''}${r.rascalWagerScore}',
      if (r.harryDelta != 0) 'Harry ${r.harryDelta > 0 ? '+' : ''}${r.harryDelta}',
      if (r.cannonball) 'Boulet',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(bits.join(' · ')),
        trailing: Text(
          '$sign${r.total}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: r.total >= 0 ? AppTheme.success : AppTheme.danger,
          ),
        ),
      ),
    );
  }

  Widget _rankTile(Player p, int index) {
    final st = game.exactRoundsFor(p.id);
    final top = index == 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: top ? AppTheme.gold : AppTheme.surface2,
        foregroundColor: top ? AppTheme.ink : AppTheme.text,
        child: Text('${index + 1}'),
      ),
      title: Text(p.name),
      subtitle: Text(
        'Exactes ${st['exact']}/${st['played']}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '${game.totalFor(p.id)} pts',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
