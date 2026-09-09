import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';
import 'launcher.dart';

const List<String> kPlatforms = [
  'PC',
  'PlayStation',
  'Xbox',
  'Switch',
  'Mobile',
  'Web',
  'Retro',
  'Other',
];

/// Offline-first library store. Persists to SharedPreferences as JSON.
class LibraryStore extends ChangeNotifier {
  static const _key = 'omnilauncher.library.v1';
  final List<Game> _games = [];
  bool loaded = false;

  List<Game> get games => List.unmodifiable(_games);
  int get totalMinutes => _games.fold(0, (s, g) => s + g.playtimeMinutes);
  int get favorites => _games.where((g) => g.favorite).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _games.clear();
    if (raw == null) {
      _games.addAll(Game.sample());
      await _save();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _games.addAll(
            list.map((e) => Game.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        _games.addAll(Game.sample());
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_games.map((g) => g.toJson()).toList()));
  }

  Future<void> add(Game game) async {
    _games.add(game);
    notifyListeners();
    await _save();
  }

  Future<void> update(Game game) async {
    final i = _games.indexWhere((g) => g.id == game.id);
    if (i >= 0) _games[i] = game;
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _games.removeWhere((g) => g.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> toggleFavorite(String id) async {
    final g = _games.firstWhere((g) => g.id == id);
    g.favorite = !g.favorite;
    notifyListeners();
    await _save();
  }

  Future<void> addPlaytime(String id, int minutes) async {
    final g = _games.firstWhere((g) => g.id == id);
    g.playtimeMinutes += minutes;
    g.lastPlayed = DateTime.now();
    notifyListeners();
    await _save();
  }

  /// Launches the real executable on desktop; returns a status message.
  /// Web and entries without a path just log a session note.
  Future<String> play(Game g) async {
    final launched = await Launcher.launch(g.execPath);
    if (launched == true) {
      await addPlaytime(g.id, 0);
      return 'Launched ${g.title}';
    }
    if (launched == false) {
      return 'Could not launch — check the executable path.';
    }
    return kIsWeb
        ? 'Web build: link your game URL in a desktop build to launch for real.'
        : 'No executable set — edit the game to add one, playtime still tracked.';
  }
}
