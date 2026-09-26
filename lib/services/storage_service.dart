import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

abstract class GameStorage {
  Future<List<String>> loadLastPlayerNames();
  Future<void> saveLastPlayerNames(List<String> names);
  Future<GameSetupDefaults?> loadSetupDefaults();
  Future<void> saveSetupDefaults(GameSetupDefaults defaults);
  Future<void> saveActiveGame(GameState game);
  Future<GameState?> loadActiveGame();
  Future<void> clearActiveGame();
  Future<List<GameState>> loadHistory();
  Future<void> archiveGame(GameState game);
}

class StorageService implements GameStorage {
  static const _historyKey = 'game_history_v1';
  static const _lastPlayersKey = 'last_players_v1';
  static const _setupDefaultsKey = 'setup_defaults_v1';
  static const _activeGameKey = 'active_game_v1';
  static const _maxHistory = 30;

  @override
  Future<List<String>> loadLastPlayerNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_lastPlayersKey) ?? [];
  }

  @override
  Future<void> saveLastPlayerNames(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lastPlayersKey, names);
  }

  @override
  Future<GameSetupDefaults?> loadSetupDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_setupDefaultsKey);
    if (raw == null) return null;
    try {
      return GameSetupDefaults.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSetupDefaults(GameSetupDefaults defaults) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_setupDefaultsKey, jsonEncode(defaults.toJson()));
  }

  @override
  Future<void> saveActiveGame(GameState game) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeGameKey, jsonEncode(game.toJson()));
  }

  @override
  Future<GameState?> loadActiveGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeGameKey);
    if (raw == null) return null;
    try {
      return GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearActiveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeGameKey);
  }

  @override
  Future<List<GameState>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => GameState.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> archiveGame(GameState game) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();
    history.insert(0, game);
    while (history.length > _maxHistory) {
      history.removeLast();
    }
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((g) => g.toJson()).toList()),
    );
    await clearActiveGame();
  }
}
