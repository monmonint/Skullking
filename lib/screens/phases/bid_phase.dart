import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../services/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_counter.dart';
import '../../widgets/player_face.dart';

class BidPhase extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  const BidPhase({super.key, required this.ctrl, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        const Text(
          'Combien de plis chaque joueur annonce-t-il ?',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < game.players.length; i++) ...[
          _BidCard(
            ctrl: ctrl,
            game: game,
            playerId: game.players[i].id,
            name: game.players[i].name,
            index: i,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _BidCard extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  final String playerId;
  final String name;
  final int index;

  const _BidCard({
    required this.ctrl,
    required this.game,
    required this.playerId,
    required this.name,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final bid = game.pendingBids[playerId] ?? 0;
    final shot = game.pendingCannonball[playerId] ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlayerFace(name: name, index: index),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(
                        'Mise $bid',
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                BigCounter(
                  id: 'bid-$playerId',
                  value: bid,
                  min: 0,
                  max: game.currentCards,
                  inline: true,
                  onChanged: (v) => ctrl.setBid(playerId, v),
                ),
              ],
            ),
            if (game.cannonballAllowed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _shot(
                      label: 'Chevrotine',
                      selected: !shot,
                      onTap: () => ctrl.setCannonball(playerId, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _shot(
                      label: 'Boulet',
                      selected: shot,
                      onTap: () => ctrl.setCannonball(playerId, true),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shot({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppTheme.accent : AppTheme.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? AppTheme.ink : AppTheme.text,
            ),
          ),
        ),
      ),
    );
  }
}
