import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════
// ENUMS & MODELE
// ══════════════════════════════════════════

/// 10 maskotek po kolei — kolejność ważna! (kołowa rotacja)
enum PetSpecies {
  bugBot,       // 1. 🤖 robotyczny, niebieski
  flutterFox,   // 2. 🦊 lisek, fioletowy
  gitGhost,     // 3. 👻 duszek, biały
  pySnake,      // 4. 🐍 wąż, zielony
  nullKitty,    // 5. 🐱 kotek, różowy
  loopLizard,   // 6. 🦎 jaszczurka, pomarańczowy
  asyncAxolotl, // 7. 🦋 aksolotl, cyjan
  stackShark,   // 8. 🦈 rekin, czerwony
  cacheWolf,    // 9. 🐺 wilk, złoty
  kernelDragon, // 10.🐉 smok, tęczowy
}

enum PetStage { egg, baby, junior, senior, master }

class PetStageInfo {
  final String name;
  final String emoji;
  final int xpRequired;
  const PetStageInfo(this.name, this.emoji, this.xpRequired);
}

const Map<PetStage, PetStageInfo> kStages = {
  PetStage.egg:    PetStageInfo('Jajko',    '🥚', 0),
  PetStage.baby:   PetStageInfo('Niemowlę', '🐣', 50),
  PetStage.junior: PetStageInfo('Junior',   '🐥', 150),
  PetStage.senior: PetStageInfo('Senior',   '🐦', 350),
  PetStage.master: PetStageInfo('Mistrz',   '🦅', 700),
};

// Kolory HEX bez '#' — do Color(int.parse('FF$hex', radix:16))
const Map<PetSpecies, Map<String, String>> kSpeciesInfo = {
  PetSpecies.bugBot:       {'name': 'BugBot',       'emoji': '🤖', 'color': '3B82F6'}, // niebieski
  PetSpecies.flutterFox:   {'name': 'FlutterFox',   'emoji': '🦊', 'color': 'A855F7'}, // fioletowy
  PetSpecies.gitGhost:     {'name': 'GitGhost',     'emoji': '👻', 'color': 'E2E8F0'}, // biały
  PetSpecies.pySnake:      {'name': 'PySnake',      'emoji': '🐍', 'color': '22C55E'}, // zielony
  PetSpecies.nullKitty:    {'name': 'NullKitty',    'emoji': '🐱', 'color': 'EC4899'}, // różowy
  PetSpecies.loopLizard:   {'name': 'LoopLizard',   'emoji': '🦎', 'color': 'F97316'}, // pomarańczowy
  PetSpecies.asyncAxolotl: {'name': 'AsyncAxolotl', 'emoji': '🦋', 'color': '06B6D4'}, // cyjan
  PetSpecies.stackShark:   {'name': 'StackShark',   'emoji': '🦈', 'color': 'EF4444'}, // czerwony
  PetSpecies.cacheWolf:    {'name': 'CacheWolf',    'emoji': '🐺', 'color': 'EAB308'}, // złoty
  PetSpecies.kernelDragon: {'name': 'KernelDragon', 'emoji': '🐉', 'color': 'A78BFA'}, // tęczowy
};

// ── Nagrody za kolekcję ─────────────────
// 3  → motyw aplikacji
// 5  → animacja ewolucji
// 10 → Full Stack Master
const Map<int, Map<String, String>> kCollectionRewards = {
  3:  {'title': 'Motyw Aplikacji',   'emoji': '🎨', 'desc': 'Odblokowano ciemny motyw neonowy!'},
  5:  {'title': 'Animacja Ewolucji', 'emoji': '✨', 'desc': 'Odblokowano ekskluzywną animację ewolucji!'},
  10: {'title': 'Full Stack Master', 'emoji': '🏆', 'desc': 'Kolekcja ukończona! Odznaka Full Stack Master!'},
};

// ── Model zebranej maskotki ─────────────
class CollectedPet {
  final PetSpecies species;
  final DateTime   retiredAt;
  final int        totalXp;

  CollectedPet({
    required this.species,
    required this.retiredAt,
    required this.totalXp,
  });

  Map<String, dynamic> toJson() => {
    'species':   species.index,
    'retiredAt': retiredAt.toIso8601String(),
    'totalXp':   totalXp,
  };

  factory CollectedPet.fromJson(Map<String, dynamic> j) => CollectedPet(
    species:   PetSpecies.values[(j['species'] as int).clamp(0, PetSpecies.values.length - 1)],
    retiredAt: DateTime.parse(j['retiredAt'] as String),
    totalXp:   j['totalXp'] as int,
  );
}

// ══════════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════════

class PetProvider extends ChangeNotifier {
  PetSpecies _species      = PetSpecies.bugBot;
  int        _xp           = 0;
  int        _energy       = 100;
  String     _mood         = '😊';
  DateTime   _lastActivity = DateTime.now();

  int      _xpToday     = 0;
  DateTime _xpTodayDate = DateTime.now();
  static const int kDailyXpLimit = 100;

  List<CollectedPet>      _collection     = [];
  List<Map<String, String>> _pendingRewards = [];

  // ── Gettery ────────────────────────────
  PetSpecies get species          => _species;
  int        get xp               => _xp;
  int        get energy           => _energy;
  String     get mood             => _mood;
  int        get xpToday          => _xpToday;
  int        get dailyXpRemaining => (kDailyXpLimit - _xpToday).clamp(0, kDailyXpLimit);
  List<CollectedPet> get collection => List.unmodifiable(_collection);
  bool get isCollectionComplete   => _collection.length >= PetSpecies.values.length;

  /// Nagrody czekające na wyświetlenie — odczytaj i wywołaj popPendingRewards() w UI
  List<Map<String, String>> popPendingRewards() {
    final list = List<Map<String, String>>.from(_pendingRewards);
    _pendingRewards.clear();
    return list;
  }

  PetStage get stage {
    PetStage result = PetStage.egg;
    for (final entry in kStages.entries) {
      if (_xp >= entry.value.xpRequired) result = entry.key;
    }
    return result;
  }

  double get stageProgress {
    final idx = stage.index;
    if (idx >= PetStage.values.length - 1) return 1.0;
    final cur  = kStages[stage]!.xpRequired;
    final next = kStages[PetStage.values[idx + 1]]!.xpRequired;
    if (next == cur) return 1.0;
    return ((_xp - cur) / (next - cur)).clamp(0.0, 1.0);
  }

  /// Emerytura: 1000 XP (700 Mistrz + 300 bonus)
  bool get isRetired => _xp >= kStages[PetStage.master]!.xpRequired + 300;

  String get speciesEmoji => kSpeciesInfo[_species]!['emoji']!;
  String get speciesName  => kSpeciesInfo[_species]!['name']!;
  String get stageEmoji   => kStages[stage]!.emoji;
  String get stageName    => kStages[stage]!.name;

  Color get speciesColor {
    final hex = kSpeciesInfo[_species]!['color']!;
    return Color(int.parse('FF$hex', radix: 16));
  }

  // ── Load ───────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final idx = prefs.getInt('pet_species') ?? 0;
    _species  = PetSpecies.values[idx.clamp(0, PetSpecies.values.length - 1)];
    _xp       = prefs.getInt('pet_xp')     ?? 0;
    _energy   = prefs.getInt('pet_energy') ?? 100;
    _mood     = prefs.getString('pet_mood') ?? '😊';
    _xpToday  = prefs.getInt('pet_xp_today') ?? 0;

    final lastStr   = prefs.getString('pet_last_activity');
    final xpDateStr = prefs.getString('pet_xp_today_date');
    _lastActivity = lastStr   != null ? DateTime.parse(lastStr)   : DateTime.now();
    _xpTodayDate  = xpDateStr != null ? DateTime.parse(xpDateStr) : DateTime.now();

    _checkDailyReset();
    _applyEnergyDecay();

    final collJson = prefs.getStringList('pet_collection') ?? [];
    _collection = collJson
        .map((s) {
          try { return CollectedPet.fromJson(jsonDecode(s) as Map<String, dynamic>); }
          catch (_) { return null; }
        })
        .whereType<CollectedPet>()
        .toList();

    notifyListeners();
  }

  // ── Save ───────────────────────────────
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pet_species',          _species.index);
    await prefs.setInt('pet_xp',               _xp);
    await prefs.setInt('pet_energy',           _energy);
    await prefs.setString('pet_mood',          _mood);
    await prefs.setInt('pet_xp_today',         _xpToday);
    await prefs.setString('pet_last_activity', _lastActivity.toIso8601String());
    await prefs.setString('pet_xp_today_date', _xpTodayDate.toIso8601String());
    await prefs.setStringList(
      'pet_collection',
      _collection.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  void _checkDailyReset() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final saved = DateTime(_xpTodayDate.year, _xpTodayDate.month, _xpTodayDate.day);
    if (today.isAfter(saved)) {
      _xpToday     = 0;
      _xpTodayDate = now;
    }
  }

  void _applyEnergyDecay() {
    final daysSince = DateTime.now().difference(_lastActivity).inDays;
    if (daysSince >= 2) {
      _energy = (_energy - (daysSince - 1) * 10).clamp(0, 100);
      _mood   = _energy < 30 ? '😢' : '😴';
    }
  }

  void _checkCollectionRewards(int oldCount) {
    final newCount = _collection.length;
    for (final entry in kCollectionRewards.entries) {
      if (oldCount < entry.key && newCount >= entry.key) {
        _pendingRewards.add(entry.value);
      }
    }
  }

  // ══════════════════════════════════════════
  // GŁÓWNA METODA: XP z timera
  // Wywołaj po zakończeniu sesji w _stopActiveSession()
  // ══════════════════════════════════════════
  Future<String?> awardXpFromTimer(int minutesStudied) async {
    _checkDailyReset();

    final remaining = kDailyXpLimit - _xpToday;
    if (remaining <= 0) return '😴 Limit XP na dziś osiągnięty!';

    int earned = (minutesStudied / 5).floor();
    earned = earned.clamp(0, remaining);
    if (earned == 0) return null;

    final wasStage = stage;
    _xp       += earned;
    _xpToday  += earned;
    _lastActivity = DateTime.now();
    _energy   = (_energy + 5).clamp(0, 100);
    _mood     = '🔥';

    String message = '+$earned XP dla $speciesName! (${_xpToday}/$kDailyXpLimit dziś)';

    if (stage != wasStage) {
      message = '🎊 $speciesName ewoluował do: $stageName $stageEmoji!';
    }

    if (isRetired) {
      message = _retirePet();
    }

    await _save();
    notifyListeners();
    return message;
  }

  // ── Emerytura maskotki ─────────────────
  String _retirePet() {
    final oldCount    = _collection.length;
    final retiredName = speciesName;

    _collection.add(CollectedPet(
      species:   _species,
      retiredAt: DateTime.now(),
      totalXp:   _xp,
    ));

    _checkCollectionRewards(oldCount);

    // Szukamy następnej niezebrane maskotki (kołowo)
    final collectedIndices = _collection.map((p) => p.species.index).toSet();

    if (collectedIndices.length >= PetSpecies.values.length) {
      // Cała kolekcja zebrana — reset do BugBota (nowy cykl)
      _species = PetSpecies.bugBot;
      _xp = 0; _energy = 100; _mood = '🥚';
      return '🏆 KOLEKCJA UKOŃCZONA! $retiredName na emeryturze! Nowy cykl: ${speciesName}!';
    }

    int nextIdx = (_species.index + 1) % PetSpecies.values.length;
    int tries = 0;
    while (collectedIndices.contains(nextIdx) && tries < PetSpecies.values.length) {
      nextIdx = (nextIdx + 1) % PetSpecies.values.length;
      tries++;
    }

    _species = PetSpecies.values[nextIdx];
    _xp = 0; _energy = 100; _mood = '🥚';

    return '🎊 $retiredName na emeryturze! Nowe jajko: $speciesName! (${_collection.length}/${PetSpecies.values.length})';
  }

  // ── Karmienie ──────────────────────────
  void feed() {
    _energy = (_energy + 15).clamp(0, 100);
    _mood   = '😋';
    _save();
    notifyListeners();
  }
}
