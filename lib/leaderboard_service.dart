import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardEntry {
  final String name;
  final int score;
  final DateTime date;
  final int maxLevel;

  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.date,
    required this.maxLevel,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'date': date.toIso8601String(),
        'maxLevel': maxLevel,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        name: json['name'] ?? 'Player',
        score: json['score'] ?? 0,
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        maxLevel: json['maxLevel'] ?? 1,
      );
}

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  static const String _leaderboardKey = 'snake_leaderboard';
  List<LeaderboardEntry> _entries = [];
  bool _isLoaded = false;

  List<LeaderboardEntry> get entries {
    _ensureLoaded();
    return List.unmodifiable(_entries);
  }

  void _ensureLoaded() {
    if (!_isLoaded) {
      throw Exception('LeaderboardService not loaded. Call load() first.');
    }
  }

  Future<void> load() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_leaderboardKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _entries = jsonList.map((e) => LeaderboardEntry.fromJson(e)).toList();
      _entries.sort((a, b) => b.score.compareTo(a.score));
      if (_entries.length > 10) {
        _entries = _entries.sublist(0, 10);
      }
    } else {
      _entries = [];
    }
    _isLoaded = true;
  }

  Future<void> addEntry(String name, int score, int maxLevel) async {
    _ensureLoaded();
    _entries.add(LeaderboardEntry(
      name: name,
      score: score,
      date: DateTime.now(),
      maxLevel: maxLevel,
    ));
    _entries.sort((a, b) => b.score.compareTo(a.score));
    if (_entries.length > 10) {
      _entries = _entries.sublist(0, 10);
    }
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_leaderboardKey, jsonString);
  }

  Future<void> clear() async {
    _entries.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_leaderboardKey);
    _isLoaded = true;
  }

  int? getRank(int score) {
    _ensureLoaded();
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].score == score) {
        return i + 1;
      }
    }
    return null;
  }

  bool isTopTen(int score) {
    _ensureLoaded();
    if (score <= 0) return false;  // Score must be positive
    if (_entries.length < 10) return true;
    return score > _entries.last.score;
  }
}
