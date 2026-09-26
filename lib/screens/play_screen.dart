import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../scoring/scoring_engine.dart';
import '../services/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/leaderboard_strip.dart';
import '../widgets/phase_chips.dart';
import 'phases/bid_phase.dart';
import 'phases/bonus_phase.dart';
import 'phases/harry_phase.dart';
import 'phases/review_phase.dart';
import 'phases/tricks_phase.dart';
import 'summary_screen.dart';

class PlayScreen extends StatefulWidget {
  /// Ferme cet écran quand la correction de manche se termine (résumé final).
  final bool closeWhenEditEnds;

  const PlayScreen({super.key, this.closeWhenEditEnds = false});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  GameController? _ctrl;
  bool _wasEditing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ctrl = context.read<GameController>();
    if (!identical(_ctrl, ctrl)) {
      _ctrl?.removeListener(_onCtrl);
      _ctrl = ctrl;
      _wasEditing = ctrl.isEditingRound;
      ctrl.addListener(_onCtrl);
    }
  }

  void _onCtrl() {
    final editing = _ctrl?.isEditingRound ?? false;
    if (widget.closeWhenEditEnds && _wasEditing && !editing && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
    _wasEditing = editing;
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onCtrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final g = ctrl.game;
    if (g == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partie')),
        body: const Center(child: Text('Aucune partie active')),
      );
    }

    final editing = g.editingCompletedIndex;
    final editingRound =
        editing == null ? null : g.completedRounds[editing];
    final cards = editingRound != null
        ? editingRound.cards
        : (g.isFinished ? 0 : g.currentCards);
    final title = editingRound != null
        ? 'Modifier manche ${editingRound.index + 1}'
        : g.isFinished
            ? 'Fin de partie'
            : 'Manche ${g.currentRoundIndex + 1}/${g.roundSequence.length}';
    final subtitle = editingRound != null
        ? '$cards carte${cards > 1 ? 's' : ''} · les scores seront recalculés'
        : g.isFinished
            ? g.mode.labelFr
            : '$cards carte${cards > 1 ? 's' : ''} · ${g.mode.labelFr}';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        actions: [
          if (editingRound != null)
            TextButton(
              onPressed: ctrl.cancelEdit,
              child: const Text('Annuler'),
            )
          else if (g.completedRounds.isNotEmpty)
            IconButton(
              tooltip: 'Manches de la partie',
              onPressed: () => _showRounds(context, ctrl, g),
              icon: const Icon(Icons.history),
            ),
        ],
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          LeaderboardStrip(game: g),
          const SizedBox(height: 8),
          Expanded(child: _phase(ctrl, g)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhaseChips(
                phases: visiblePhases(g),
                current: ctrl.phase,
                onTap: ctrl.phase == RoundPhase.review ? null : ctrl.goToPhase,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_canBack(ctrl)) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: ctrl.goBack,
                        child: const Text('Retour'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      key: const Key('play-next'),
                      onPressed: () => _onPrimary(context, ctrl, g),
                      child: Text(_primaryLabel(ctrl, g)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canBack(GameController ctrl) {
    if (ctrl.game == null || ctrl.phase == RoundPhase.review) return false;
    return visiblePhases(ctrl.game!).indexOf(ctrl.phase) > 0;
  }

  String _primaryLabel(GameController ctrl, GameState g) {
    switch (ctrl.phase) {
      case RoundPhase.bidding:
        return 'Valider les enchères';
      case RoundPhase.tricks:
        if (g.expansions.harryTheGiant) return 'Harry le Géant';
        if (g.hasBonusStep) return 'Bonus';
        return g.isEditingRound ? 'Enregistrer la manche' : 'Calculer les scores';
      case RoundPhase.harry:
        if (g.hasBonusStep) return 'Bonus';
        return g.isEditingRound ? 'Enregistrer la manche' : 'Calculer les scores';
      case RoundPhase.bonuses:
        return g.isEditingRound ? 'Enregistrer la manche' : 'Calculer les scores';
      case RoundPhase.review:
        return g.isFinished ? 'Résumé final' : 'Manche suivante';
    }
  }

  void _onPrimary(BuildContext context, GameController ctrl, GameState g) {
    switch (ctrl.phase) {
      case RoundPhase.bidding:
        ctrl.confirmBids();
      case RoundPhase.tricks:
        ctrl.confirmTricks();
      case RoundPhase.harry:
        ctrl.confirmHarry();
      case RoundPhase.bonuses:
        ctrl.confirmBonuses();
      case RoundPhase.review:
        if (g.isFinished) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SummaryScreen()),
          );
        } else {
          ctrl.nextRoundOrFinish();
        }
    }
  }

  Widget _phase(GameController ctrl, GameState g) {
    switch (ctrl.phase) {
      case RoundPhase.bidding:
        return BidPhase(ctrl: ctrl, game: g);
      case RoundPhase.tricks:
        return TricksPhase(ctrl: ctrl, game: g);
      case RoundPhase.harry:
        return HarryPhase(ctrl: ctrl, game: g);
      case RoundPhase.bonuses:
        return BonusPhase(ctrl: ctrl, game: g);
      case RoundPhase.review:
        return ReviewPhase(
          game: g,
          onEdit: ctrl.beginEditRound,
        );
    }
  }

  void _showRounds(BuildContext context, GameController ctrl, GameState g) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Manches de la partie',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              for (var i = 0; i < g.completedRounds.length; i++)
                ListTile(
                  key: Key('edit-round-$i'),
                  title: Text(
                    'Manche ${g.completedRounds[i].index + 1} · '
                    '${g.completedRounds[i].cards} carte'
                    '${g.completedRounds[i].cards > 1 ? 's' : ''}',
                  ),
                  subtitle: Text(_roundLine(g, g.completedRounds[i])),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ctrl.beginEditRound(i);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _roundLine(GameState g, RoundRecord round) {
    return round.results.map((r) {
      final name = g.nameOf(r.playerId) ?? r.playerId;
      final sign = r.total >= 0 ? '+' : '';
      return '$name $sign${r.total}';
    }).join(' · ');
  }
}
