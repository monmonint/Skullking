import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../scoring/scoring_engine.dart';
import '../../services/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_counter.dart';

class TricksPhase extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  const TricksPhase({super.key, required this.ctrl, required this.game});

  @override
  Widget build(BuildContext context) {
    final sum = game.players
        .map((p) => game.pendingTricks[p.id] ?? 0)
        .fold<int>(0, (a, b) => a + b);
    final monsters = game.expansions.anySeaMonster;
    final voided = monsters ? game.pendingVoidedTricks : 0;
    final ghost = game.expansions.graybeard ? game.pendingGhostTricks : 0;
    final total = sum + voided + ghost;
    final ok = total == game.currentCards;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Text(
          monsters || game.expansions.graybeard
              ? 'Plis $sum'
                  '${monsters ? ' + annulés $voided' : ''}'
                  '${game.expansions.graybeard ? ' + Barbe Grise $ghost' : ''}'
                  ' / ${game.currentCards}'
              : 'Plis remportés — $sum / ${game.currentCards}',
          style: TextStyle(
            color: ok ? AppTheme.success : AppTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: game.currentCards == 0
                ? 0
                : (total / game.currentCards).clamp(0, 1).toDouble(),
            backgroundColor: AppTheme.surface2,
            color: ok ? AppTheme.success : AppTheme.accent,
          ),
        ),
        if (ctrl.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(ctrl.errorMessage!, style: const TextStyle(color: AppTheme.danger)),
        ],
        if (monsters) ...[
          const SizedBox(height: 12),
          _infoCard(
            title: 'Plis annulés',
            body: _monsterHelp(game.expansions),
            child: BigCounter(
              id: 'voided',
              value: voided,
              min: 0,
              max: game.currentCards,
              showChips: game.currentCards <= 10,
              onChanged: ctrl.setVoidedTricks,
            ),
          ),
        ],
        if (game.expansions.graybeard) ...[
          const SizedBox(height: 12),
          _infoCard(
            title: 'Barbe Grise',
            body:
                'Il ne marque pas. Tigresse jouée par lui = fuite. '
                'Comptez seulement les plis qu\'il remporte.',
            child: BigCounter(
              id: 'ghost',
              value: ghost,
              min: 0,
              max: game.currentCards,
              showChips: game.currentCards <= 10,
              onChanged: ctrl.setGhostTricks,
            ),
          ),
        ],
        if (game.expansions.anyTablePower) ...[
          const SizedBox(height: 12),
          _infoCard(
            title: 'Rappels de table',
            body: [
              if (game.expansions.rosie) 'Rosie : choisir qui entame le pli suivant.',
              if (game.expansions.bandit) 'Will : piocher 2, défausser 2.',
              if (game.expansions.juanita)
                'Juanita : regarder les cartes non distribuées.',
            ].join('\n'),
          ),
        ],
        const SizedBox(height: 12),
        for (final p in game.players) ...[
          _TrickCard(ctrl: ctrl, game: game, player: p),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  static String _monsterHelp(ExpansionOptions e) {
    final lines = <String>[];
    if (e.kraken) {
      lines.add('Kraken : le pli est détruit, personne ne gagne.');
    }
    if (e.whiteWhale) {
      lines.add('Baleine : plus haut numéro. Que des spéciaux → annulé.');
    }
    if (e.stingray) {
      lines.add('Raie : plus petit numéro. Que des spéciaux → annulé.');
    }
    if ((e.kraken ? 1 : 0) + (e.whiteWhale ? 1 : 0) + (e.stingray ? 1 : 0) > 1) {
      lines.add('Si deux monstres : la 2e carte prime, la 1re compte comme une fuite.');
    }
    return lines.join(' ');
  }
}

class _TrickCard extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  final Player player;
  const _TrickCard({
    required this.ctrl,
    required this.game,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final tricks = game.pendingTricks[player.id] ?? 0;
    final bid = game.pendingBids[player.id] ?? 0;
    final preview = ScoringEngine.score(
      bid: game.effectiveBid(player.id),
      tricks: tricks,
      roundCards: game.currentCards,
      scoring: game.scoring,
      cannonball:
          game.cannonballAllowed && (game.pendingCannonball[player.id] ?? false),
      classicBonusGate: game.classicBonusGate,
    );
    final label = ScoringEngine.accuracyLabelFr(
      scoring: game.scoring,
      cannonball:
          game.cannonballAllowed && (game.pendingCannonball[player.id] ?? false),
      exact: preview.exact,
      difference: preview.difference,
    );
    final sign = preview.bidScore >= 0 ? '+' : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              'Mise $bid · $label · mise $sign${preview.bidScore}',
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            BigCounter(
              id: 'tricks-${player.id}',
              value: tricks,
              min: 0,
              max: game.currentCards,
              showChips: true,
              onChanged: (v) => ctrl.setTricks(player.id, v),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _infoCard({required String title, required String body, Widget? child}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.35)),
          if (child != null) ...[
            const SizedBox(height: 8),
            child,
          ],
        ],
      ),
    ),
  );
}
