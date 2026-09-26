import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../scoring/scoring_engine.dart';
import '../services/game_controller.dart';
import '../theme/app_theme.dart';
import 'play_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _step = 0;
  int _count = 4;
  final List<TextEditingController> _names =
      List.generate(8, (_) => TextEditingController());
  GameMode _mode = GameMode.standard;
  bool _bonuses = true;
  bool _classicGate = false;
  ScoringSystem _scoring = ScoringSystem.skullKing;
  bool _cannonball = false;
  ExpansionOptions _exp = const ExpansionOptions();
  final _customCtrl = TextEditingController(text: '1,2,3,4,5,6,7,8,9,10');
  String? _error;
  bool _loading = true;
  bool _namesRequested = false;

  static const _titles = ['Joueurs', 'Mode', 'Options'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_namesRequested) return;
    _namesRequested = true;
    _loadLast();
  }

  Future<void> _loadLast() async {
    final storage = context.read<GameController>().storage;
    final defaults = await storage.loadSetupDefaults();
    if (!mounted) return;
    if (defaults != null && defaults.playerNames.isNotEmpty) {
      _applyDefaults(defaults);
    } else {
      final last = await storage.loadLastPlayerNames();
      if (!mounted) return;
      if (last.isNotEmpty) {
        _count = last.length.clamp(2, 8);
        for (var i = 0; i < last.length && i < 8; i++) {
          _names[i].text = last[i];
        }
      } else {
        for (var i = 0; i < 8; i++) {
          _names[i].text = 'Joueur ${i + 1}';
        }
      }
    }
    setState(() => _loading = false);
  }

  void _applyDefaults(GameSetupDefaults defaults) {
    _count = defaults.playerNames.length.clamp(2, 8);
    for (var i = 0; i < 8; i++) {
      _names[i].text = i < defaults.playerNames.length
          ? defaults.playerNames[i]
          : 'Joueur ${i + 1}';
    }
    _mode = defaults.mode;
    _bonuses = defaults.bonusesEnabled;
    _classicGate = defaults.classicBonusGate;
    _scoring = defaults.scoring;
    _cannonball = defaults.cannonballAllowed &&
        defaults.scoring == ScoringSystem.rascal;
    _exp = defaults.expansions;
    if (defaults.customSequence.isNotEmpty) {
      _customCtrl.text = defaults.customSequence.join(',');
    }
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    _customCtrl.dispose();
    super.dispose();
  }

  List<int>? _parseCustom() {
    try {
      final custom = _customCtrl.text
          .split(RegExp(r'[,;\s]+'))
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toList();
      if (custom.isEmpty || custom.any((c) => c < 0)) return null;
      return custom;
    } catch (_) {
      return null;
    }
  }

  void _next() {
    setState(() => _error = null);
    if (_step == 1 && _mode == GameMode.custom && _parseCustom() == null) {
      setState(() => _error = 'Séquence invalide (ex. 1,2,3,5,8)');
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
    }
  }

  Future<void> _start() async {
    setState(() => _error = null);
    final names = _names.take(_count).map((c) => c.text).toList();
    List<int>? custom;
    if (_mode == GameMode.custom) {
      custom = _parseCustom();
      if (custom == null) {
        setState(() => _error = 'Séquence invalide (ex. 1,2,3,5,8)');
        return;
      }
    }
    try {
      await context.read<GameController>().startNewGame(
            names: names,
            mode: _mode,
            customSequence: custom,
            bonusesEnabled: _bonuses,
            classicBonusGate: _classicGate,
            scoring: _scoring,
            cannonballAllowed: _cannonball,
            expansions: _exp,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlayScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvelle partie · ${_titles[_step]}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: List.generate(3, (i) {
                final on = i <= _step;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                    height: 6,
                    decoration: BoxDecoration(
                      color: on ? AppTheme.accent : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_step + 1}/3  ${_titles[_step]}',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(_error!, style: const TextStyle(color: AppTheme.danger)),
            ),
          Expanded(child: _stepBody()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _error = null;
                      _step--;
                    }),
                    child: const Text('Retour'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  key: Key(_step == 2 ? 'setup-start' : 'setup-next'),
                  onPressed: _step == 2 ? _start : _next,
                  child: Text(_step == 2 ? 'Lancer la partie' : 'Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _players();
      case 1:
        return _modes();
      default:
        return _options();
    }
  }

  Widget _players() {
    return ListView(
      key: const ValueKey('setup-players'),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Qui embarque ? De 2 à 8 joueurs.',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  key: const Key('player-count-minus'),
                  onPressed: _count > 2 ? () => setState(() => _count--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_count',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  key: const Key('player-count-plus'),
                  onPressed: _count < 8 ? () => setState(() => _count++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final storage = context.read<GameController>().storage;
                    final defaults = await storage.loadSetupDefaults();
                    if (!mounted) return;
                    if (defaults != null && defaults.playerNames.isNotEmpty) {
                      setState(() => _applyDefaults(defaults));
                      return;
                    }
                    final last = await storage.loadLastPlayerNames();
                    if (last.isEmpty || !mounted) return;
                    setState(() {
                      _count = last.length.clamp(2, 8);
                      for (var i = 0; i < 8; i++) {
                        _names[i].text =
                            i < last.length ? last[i] : 'Joueur ${i + 1}';
                      }
                    });
                  },
                  child: const Text('Derniers'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_count, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _names[i],
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Joueur ${i + 1}',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _modes() {
    return ListView(
      key: const ValueKey('setup-modes'),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Combien de cartes à chaque manche ?',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 12),
        for (final m in GameMode.values) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _mode == m ? AppTheme.accent.withValues(alpha: 0.14) : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                key: Key('mode-${m.name}'),
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _mode = m),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _mode == m ? AppTheme.accent : AppTheme.cardBorder,
                      width: _mode == m ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _mode == m
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _mode == m ? AppTheme.accent : AppTheme.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.labelFr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.descriptionFr,
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        if (_mode == GameMode.custom) ...[
          const SizedBox(height: 4),
          TextField(
            controller: _customCtrl,
            decoration: const InputDecoration(
              labelText: 'Séquence (cartes par manche)',
              hintText: '1,2,3,4,5',
            ),
          ),
        ],
      ],
    );
  }

  Widget _options() {
    return ListView(
      key: const ValueKey('setup-options'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        const Text('Raccourcis', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const Key('preset-journal'),
              label: const Text('Journal 2022'),
              onPressed: () => setState(() {
                _exp = _exp.withLogbook2022;
                _bonuses = true;
              }),
            ),
            ActionChip(
              key: const Key('preset-extension'),
              label: const Text('Extension score'),
              onPressed: () => setState(() {
                _exp = _exp.withScoreExpansion;
                _bonuses = true;
              }),
            ),
            ActionChip(
              label: const Text('Tout activer'),
              onPressed: () => setState(() {
                _exp = _exp.withLogbook2022.withScoreExpansion.copyWith(
                  graybeard: _count == 2,
                );
                _bonuses = true;
                _scoring = ScoringSystem.rascal;
                _cannonball = true;
              }),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Comptage', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final s in ScoringSystem.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _selectCard(
              selected: _scoring == s,
              title: s.labelFr,
              subtitle: s.descriptionFr,
              onTap: () => setState(() {
                _scoring = s;
                if (s != ScoringSystem.rascal) _cannonball = false;
              }),
            ),
          ),
        if (_scoring == ScoringSystem.rascal)
          _toggle(
            'Boulet de canon autorisé',
            'Chaque joueur choisit chevrotine ou boulet après sa mise.',
            _cannonball,
            (v) => setState(() => _cannonball = v),
          ),
        _toggle(
          'Points bonus (14, captures, 7/8…)',
          'Cartes et captures. Le butin et le pari Rascal restent à part.',
          _bonuses,
          (v) => setState(() => _bonuses = v),
        ),
        _toggle(
          'Bonus seulement si enchère exacte',
          'Désactivé : les bonus s\'appliquent aussi aux mises ratées. '
              'Activé : barème Halcyon classique.',
          _classicGate,
          (v) => setState(() => _classicGate = v),
        ),
        const SizedBox(height: 8),
        const Text('Monstres', style: TextStyle(fontWeight: FontWeight.w800)),
        _toggle(
          'Kraken',
          'Pli détruit. Comptez-le dans les plis annulés.',
          _exp.kraken,
          (v) => setState(() => _exp = _exp.copyWith(kraken: v)),
        ),
        _toggle(
          'Baleine blanche',
          'Plus haut numéro. Que des spéciaux → pli annulé.',
          _exp.whiteWhale,
          (v) => setState(() => _exp = _exp.copyWith(whiteWhale: v)),
        ),
        _toggle(
          'Raie tachetée',
          'Plus petit numéro. Que des spéciaux → pli annulé.',
          _exp.stingray,
          (v) => setState(() => _exp = _exp.copyWith(stingray: v)),
        ),
        _toggle(
          'Coffre de Davy Jones',
          '+20 par monstre marin qu\'il capture (saisie en bonus).',
          _exp.davyJones,
          (v) => setState(() => _exp = _exp.copyWith(davyJones: v)),
        ),
        const SizedBox(height: 8),
        const Text('Cartes et alliances', style: TextStyle(fontWeight: FontWeight.w800)),
        _toggle(
          'Butin',
          'Jusqu\'à 2 alliances, +20 chacun.',
          _exp.loot,
          (v) => setState(() => _exp = _exp.copyWith(loot: v)),
        ),
        _toggle(
          '7 et 8 d\'extension',
          '8 : +5. 7 : −5. Saisie en fin de manche.',
          _exp.bonusSevensEights,
          (v) => setState(() => _exp = _exp.copyWith(bonusSevensEights: v)),
        ),
        _toggle(
          'Con (capturé)',
          '+30 si Skull King ou une sirène le prend.',
          _exp.con,
          (v) => setState(() => _exp = _exp.copyWith(con: v)),
        ),
        _toggle(
          'Tigresse / Scary Mary',
          'Rappel : pirate seulement si jouée en pirate.',
          _exp.tigressNotes,
          (v) => setState(() => _exp = _exp.copyWith(tigressNotes: v)),
        ),
        const SizedBox(height: 8),
        const Text('Pouvoirs', style: TextStyle(fontWeight: FontWeight.w800)),
        _toggle(
          'Harry le Géant',
          'Après les plis : ajuster la mise de ±1.',
          _exp.harryTheGiant,
          (v) => setState(() => _exp = _exp.copyWith(harryTheGiant: v)),
        ),
        _toggle(
          'Rascal le Flambeur',
          'Pari 0 / 10 / 20, gagné seulement si la mise est exacte.',
          _exp.rascalWager,
          (v) => setState(() => _exp = _exp.copyWith(rascalWager: v)),
        ),
        _toggle(
          'Rosie la Douce',
          'Rappel : choisir qui entame le pli suivant.',
          _exp.rosie,
          (v) => setState(() => _exp = _exp.copyWith(rosie: v)),
        ),
        _toggle(
          'Will le Bandit',
          'Rappel : piocher 2, défausser 2.',
          _exp.bandit,
          (v) => setState(() => _exp = _exp.copyWith(bandit: v)),
        ),
        _toggle(
          'Juanita Jade',
          'Rappel : regarder les cartes non distribuées.',
          _exp.juanita,
          (v) => setState(() => _exp = _exp.copyWith(juanita: v)),
        ),
        _toggle(
          'Barbe Grise',
          _count == 2
              ? 'Variante 2 joueurs : ses plis ne marquent pas.'
              : 'Prévu pour 2 joueurs. Vous pouvez quand même compter ses plis.',
          _exp.graybeard,
          (v) => setState(() => _exp = _exp.copyWith(graybeard: v)),
        ),
      ],
    );
  }

  Widget _selectCard({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppTheme.accent.withValues(alpha: 0.14) : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.accent : AppTheme.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}
