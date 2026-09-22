import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../scoring/scoring_engine.dart';
import '../services/game_controller.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'play_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _count = 4;
  final List<TextEditingController> _names =
      List.generate(8, (_) => TextEditingController());
  GameMode _mode = GameMode.standard;
  bool _bonuses = true;
  bool _kraken = false;
  bool _whale = false;
  bool _harry = false;
  bool _loot = false;
  bool _rascal = false;
  final _customCtrl = TextEditingController(text: '1,2,3,4,5,6,7,8,9,10');
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    final last = await StorageService().loadLastPlayerNames();
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
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    final names = _names.take(_count).map((c) => c.text).toList();
    List<int>? custom;
    if (_mode == GameMode.custom) {
      try {
        custom = _customCtrl.text
            .split(RegExp(r'[,;\s]+'))
            .where((s) => s.isNotEmpty)
            .map(int.parse)
            .toList();
        if (custom.isEmpty) throw FormatException('vide');
      } catch (_) {
        setState(() => _error = 'Séquence invalide (ex: 1,2,3,5,8)');
        return;
      }
    }
    try {
      await context.read<GameController>().startNewGame(
            names: names,
            mode: _mode,
            customSequence: custom,
            bonusesEnabled: _bonuses,
            expansions: ExpansionOptions(
              kraken: _kraken,
              whiteWhale: _whale,
              harryTheGiant: _harry,
              loot: _loot,
              rascalWager: _rascal,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlayScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Widget _toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      activeThumbColor: AppTheme.accent,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle partie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Nombre de joueurs',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              IconButton(
                onPressed: _count > 2 ? () => setState(() => _count--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_count',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: _count < 8 ? () => setState(() => _count++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final last = await StorageService().loadLastPlayerNames();
                  if (last.isEmpty) return;
                  setState(() {
                    _count = last.length.clamp(2, 8);
                    for (var i = 0; i < 8; i++) {
                      _names[i].text =
                          i < last.length ? last[i] : 'Joueur ${i + 1}';
                    }
                  });
                },
                child: const Text('Derniers joueurs'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_count, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _names[i],
                decoration: InputDecoration(
                  labelText: 'Joueur ${i + 1}',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Mode de partie',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_mode.descriptionFr,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GameMode.values.map((m) {
              final selected = _mode == m;
              return ChoiceChip(
                label: Text(m.labelFr),
                selected: selected,
                onSelected: (_) => setState(() => _mode = m),
                selectedColor: AppTheme.accent,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : AppTheme.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          if (_mode == GameMode.custom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customCtrl,
              decoration: const InputDecoration(
                labelText: 'Séquence (cartes par manche)',
                hintText: '1,2,3,4,5',
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Score & bonus',
              style: TextStyle(fontWeight: FontWeight.w600)),
          _toggle(
            'Bonus de capture',
            '14, sirène↔pirate↔Skull King (Halcyon 2022)',
            _bonuses,
            (v) => setState(() => _bonuses = v),
          ),
          const SizedBox(height: 8),
          const Text('Extensions (journal de bord)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          _toggle(
            'Kraken',
            'Pli détruit — personne ne gagne. Comptez les plis annulés.',
            _kraken,
            (v) => setState(() => _kraken = v),
          ),
          _toggle(
            'Baleine blanche',
            'Plus haut numéro gagne (spéciaux annulés). Pli vide si que des spéciaux.',
            _whale,
            (v) => setState(() => _whale = v),
          ),
          _toggle(
            'Harry le Géant',
            'Après les enchères : ajuster mise ±1 (pouvoir pirate).',
            _harry,
            (v) => setState(() => _harry = v),
          ),
          _toggle(
            'Butin (Loot)',
            'Alliance +20 chacun si les deux réussissent leur mise.',
            _loot,
            (v) => setState(() => _loot = v),
          ),
          _toggle(
            'Rascal le Flambeur',
            'Pari 0 / 10 / 20 : gagné si exact, perdu sinon.',
            _rascal,
            (v) => setState(() => _rascal = v),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Tigresse / Scary Mary : saisir comme pirate si jouées en pirate '
              '(pas de bonus si Tigresse-fuite). '
              'Système Rascal/Boulet de canon (score alternatif) : non inclus — voir README.',
              style: TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.danger)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _start,
            child: const Text('Commencer'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
