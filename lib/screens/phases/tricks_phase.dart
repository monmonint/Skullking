import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../scoring/scoring_engine.dart';
import '../../services/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_counter.dart';
import '../../widgets/player_face.dart';

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
          'Plis $total / ${game.currentCards}',
          style: TextStyle(
            color: ok ? AppTheme.success : AppTheme.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          ok ? 'Tous les plis sont saisis' : _remainingLabel(total),
          style: const TextStyle(color: AppTheme.muted, fontSize: 13),
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
        for (var i = 0; i < game.players.length; i++) ...[
          _TrickCard(
            ctrl: ctrl,
            game: game,
            player: game.players[i],
            index: i,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _remainingLabel(int total) {
    final n = (game.currentCards - total).abs();
    final plural = n > 1;
    final word = total < game.currentCards
        ? (plural ? 'restants' : 'restant')
        : 'en trop';
    return '$n pli${plural ? 's' : ''} $word';
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
  final int index;
  const _TrickCard({
    required this.ctrl,
    required this.game,
    required this.player,
    required this.index,
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            PlayerFace(name: player.name, index: index),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(
                    'Mise $bid · $label',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            BigCounter(
              id: 'tricks-${player.id}',
              value: tricks,
              min: 0,
              max: game.currentCards,
              inline: true,
              onChanged: (v) => ctrl.setTricks(player.id, v),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Text(
                '$sign${preview.bidScore}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: preview.bidScore >= 0 ? AppTheme.success : AppTheme.danger,
                ),
              ),
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
