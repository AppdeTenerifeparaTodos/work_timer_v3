import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_localizations.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const WorkStudyTimerApp());
}

// Główna aplikacja
class WorkStudyTimerApp extends StatefulWidget {
  const WorkStudyTimerApp({super.key});

  @override
  State<WorkStudyTimerApp> createState() => _WorkStudyTimerAppState();
}

class _WorkStudyTimerAppState extends State<WorkStudyTimerApp> {
  Locale _locale = const Locale('pl', ''); // domyślnie polski

  void _changeLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode, '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Study Timer',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pl', ''),
        Locale('es', ''),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: HomePage(
        onLanguageChange: _changeLanguage,
        currentLocale: _locale,
      ),
    );
  }
}

// Model danych jednej sesji
class SessionEntry {
  final DateTime start;
  final DateTime end;
  final String description;
  final bool isManual;
  final String type;

  SessionEntry({
    required this.start,
    required this.end,
    required this.description,
    required this.isManual,
    required this.type,
  });

  Duration get duration => end.difference(start);

  SessionEntry copyWith({
    DateTime? start,
    DateTime? end,
    String? description,
    bool? isManual,
    String? type,
  }) {
    return SessionEntry(
      start: start ?? this.start,
      end: end ?? this.end,
      description: description ?? this.description,
      isManual: isManual ?? this.isManual,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'description': description,
      'isManual': isManual,
      'type': type,
    };
  }

  factory SessionEntry.fromJson(Map<String, dynamic> json) {
    return SessionEntry(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      description: json['description'] as String? ?? '',
      isManual: json['isManual'] as bool? ?? false,
      type: json['type'] as String? ?? 'nauka',
    );
  }
}

// Ekran główny
class HomePage extends StatefulWidget {
  final Function(String) onLanguageChange;
  final Locale currentLocale;

  const HomePage({
    super.key,
    required this.onLanguageChange,
    required this.currentLocale,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _customTypes = [];
  final List<String> _savedDescriptions = [];

  String? _backgroundImagePath;
  final ImagePicker _picker = ImagePicker();
  Color _iconColor = Colors.white;
  double _iconHue = 0.0;

  DateTime? _activeStartTime;
  String _activeDescription = '';
  String _activeType = 'nauka';

  final List<SessionEntry> _history = [];

  final TextEditingController _manualDescriptionController = TextEditingController();
  final TextEditingController _manualStartController = TextEditingController();
  final TextEditingController _manualEndController = TextEditingController();
  String _manualType = 'nauka';

  DateTime _manualDate = DateTime.now();

  String _selectedRange = 'dzisiaj';
  String _searchText = '';

  // NOWE - Kontrolery dla autocomplete
  final TextEditingController _activeDescController = TextEditingController();
  bool _showActiveSuggestions = false;
  bool _showManualSuggestions = false;
  final FocusNode _activeFocusNode = FocusNode();
  final FocusNode _manualFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadBackgroundImage();
    _loadIconColor();
    _loadSavedDescriptions();
    _loadCustomTypes();
    _loadActiveSession(); // NOWE - Wczytaj aktywną sesję jeśli była

    // Listenery dla focus
    _activeFocusNode.addListener(() {
      setState(() {
        _showActiveSuggestions = _activeFocusNode.hasFocus;
      });
    });

    _manualFocusNode.addListener(() {
      setState(() {
        _showManualSuggestions = _manualFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _manualDescriptionController.dispose();
    _manualStartController.dispose();
    _manualEndController.dispose();
    _activeDescController.dispose();
    _activeFocusNode.dispose();
    _manualFocusNode.dispose();
    super.dispose();
  }

  // Filtrowane sugestie dla aktywnej sesji
  List<String> get _activeFilteredSuggestions {
    if (_activeDescController.text.isEmpty) return [];
    return _savedDescriptions
        .where((desc) => desc.toLowerCase().contains(_activeDescController.text.toLowerCase()))
        .take(5)
        .toList();
  }

  // Filtrowane sugestie dla manualnej sesji
  List<String> get _manualFilteredSuggestions {
    if (_manualDescriptionController.text.isEmpty) return [];
    return _savedDescriptions
        .where((desc) => desc.toLowerCase().contains(_manualDescriptionController.text.toLowerCase()))
        .take(5)
        .toList();
  }

  Future<void> _pickBackgroundImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() {
      _backgroundImagePath = image.path;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image_path', image.path);
  }

  Future<void> _loadBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('background_image_path');
    if (path == null || path.isEmpty) return;

    if (!await File(path).exists()) {
      await prefs.remove('background_image_path');
      return;
    }

    setState(() {
      _backgroundImagePath = path;
    });
  }

  Future<void> _saveIconColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('icon_color', color.value);
    await prefs.setDouble('icon_hue', _iconHue);
  }

  Future<void> _loadIconColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt('icon_color');
    final hue = prefs.getDouble('icon_hue');
    if (value == null) return;
    setState(() {
      _iconColor = Color(value);
      if (hue != null) _iconHue = hue;
    });
  }

  Future<void> _saveSavedDescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_descriptions', _savedDescriptions);
  }

  Future<void> _loadSavedDescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_descriptions') ?? [];
    setState(() {
      _savedDescriptions.clear();
      _savedDescriptions.addAll(saved);
    });
  }

  void _addDescriptionToSaved(String description) {
    if (description.trim().isEmpty) return;
    final trimmed = description.trim();
    if (!_savedDescriptions.contains(trimmed)) {
      setState(() {
        _savedDescriptions.add(trimmed);
      });
      _saveSavedDescriptions();
    }
  }

  Color _colorFromHue(double hue) {
    final h = hue % 360 / 60;
    final c = 1.0;
    final x = c * (1 - ((h % 2) - 1).abs());
    double r = 0, g = 0, b = 0;
    if (h < 1) {
      r = c;
      g = x;
    } else if (h < 2) {
      r = x;
      g = c;
    } else if (h < 3) {
      g = c;
      b = x;
    } else if (h < 4) {
      g = x;
      b = c;
    } else if (h < 5) {
      r = x;
      b = c;
    } else {
      r = c;
      b = x;
    }
    return Color.fromARGB(
      255,
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
    );
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _history.map((e) => e.toJson()).toList();
    final encoded = jsonEncode(jsonList);
    await prefs.setString('history', encoded);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('history');
    if (encoded == null || encoded.isEmpty) return;
    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      setState(() {
        _history.clear();
        for (var item in decoded) {
          _history.add(SessionEntry.fromJson(item as Map<String, dynamic>));
        }
      });
      _updateDescriptionsFromHistory();
    } catch (e) {
      debugPrint('Błąd podczas ładowania historii: $e');
    }
  }

  void _updateDescriptionsFromHistory() {
    final Set<String> uniqueDescriptions = {};
    for (var entry in _history) {
      if (entry.description.trim().isNotEmpty) {
        uniqueDescriptions.add(entry.description.trim());
      }
    }
    setState(() {
      _savedDescriptions.clear();
      _savedDescriptions.addAll(uniqueDescriptions.toList()..sort());
    });
    _saveSavedDescriptions();
  }

  Future<void> _saveCustomTypes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_types', _customTypes);
  }

  Future<void> _loadCustomTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = prefs.getStringList('custom_types') ?? [];
    setState(() {
      _customTypes.clear();
      _customTypes.addAll(loaded);
    });
  }

  // NOWE - Zapisz aktywną sesję
  Future<void> _saveActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeStartTime != null) {
      await prefs.setString('active_session_start', _activeStartTime!.toIso8601String());
      await prefs.setString('active_session_description', _activeDescController.text);
      await prefs.setString('active_session_type', _activeType);
    } else {
      await prefs.remove('active_session_start');
      await prefs.remove('active_session_description');
      await prefs.remove('active_session_type');
    }
  }

  // NOWE - Wczytaj aktywną sesję
  Future<void> _loadActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final startString = prefs.getString('active_session_start');
    if (startString != null) {
      try {
        final start = DateTime.parse(startString);
        final description = prefs.getString('active_session_description') ?? '';
        final type = prefs.getString('active_session_type') ?? 'nauka';

        setState(() {
          _activeStartTime = start;
          _activeDescController.text = description;
          _activeType = type;
        });
      } catch (e) {
        debugPrint('Błąd wczytywania aktywnej sesji: $e');
      }
    }
  }

  void _stopActiveSession() {
    if (_activeStartTime == null) return;

    final newEntry = SessionEntry(
      start: _activeStartTime!,
      end: DateTime.now(),
      description: _activeDescController.text.trim(),
      isManual: false,
      type: _activeType,
    );

    setState(() {
      _history.add(newEntry);
      _activeStartTime = null;
      _activeDescController.clear();
      _activeType = 'nauka';
    });

    _saveHistory();
    _addDescriptionToSaved(newEntry.description);
    _saveActiveSession(); // NOWE - Wyczyść zapisaną sesję
  }

  void _addManualSession() {
    final loc = AppLocalizations.of(context)!;

    final startText = _manualStartController.text.trim();
    final endText = _manualEndController.text.trim();
    final description = _manualDescriptionController.text.trim();

    if (description.isEmpty || startText.isEmpty || endText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('fill_all_fields'))),
      );
      return;
    }

    final startParts = startText.split(':');
    final endParts = endText.split(':');
    if (startParts.length != 2 || endParts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('invalid_time_format'))),
      );
      return;
    }

    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);

    if (startHour == null ||
        startMinute == null ||
        endHour == null ||
        endMinute == null ||
        startHour < 0 ||
        startHour > 23 ||
        startMinute < 0 ||
        startMinute > 59 ||
        endHour < 0 ||
        endHour > 23 ||
        endMinute < 0 ||
        endMinute > 59) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('invalid_time_format'))),
      );
      return;
    }

    final start = DateTime(
      _manualDate.year,
      _manualDate.month,
      _manualDate.day,
      startHour,
      startMinute,
    );
    var end = DateTime(
      _manualDate.year,
      _manualDate.month,
      _manualDate.day,
      endHour,
      endMinute,
    );

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final newEntry = SessionEntry(
      start: start,
      end: end,
      description: description,
      isManual: true,
      type: _manualType,
    );

    setState(() {
      _history.add(newEntry);
      _manualDescriptionController.clear();
      _manualStartController.clear();
      _manualEndController.clear();
    });

    _saveHistory();
    _addDescriptionToSaved(description);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.translate('session_added'))),
    );
  }

  void _deleteSession(int index) {
    final loc = AppLocalizations.of(context)!;

    if (index < 0 || index >= _filteredHistory.length) return;
    final toDelete = _filteredHistory[index];
    final realIndex = _history.indexOf(toDelete);
    if (realIndex == -1) return;

    setState(() {
      _history.removeAt(realIndex);
    });
    _saveHistory();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.translate('session_deleted'))),
    );
  }

  void _editSession(int index) async {
    final loc = AppLocalizations.of(context)!;

    if (index < 0 || index >= _filteredHistory.length) return;
    final entry = _filteredHistory[index];
    final realIndex = _history.indexOf(entry);
    if (realIndex == -1) return;

    final startHour = entry.start.hour.toString().padLeft(2, '0');
    final startMin = entry.start.minute.toString().padLeft(2, '0');
    final endHour = entry.end.hour.toString().padLeft(2, '0');
    final endMin = entry.end.minute.toString().padLeft(2, '0');

    final descController = TextEditingController(text: entry.description);
    final startController = TextEditingController(text: '$startHour:$startMin');
    final endController = TextEditingController(text: '$endHour:$endMin');
    String editType = entry.type;
    DateTime editDate = entry.start;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: Text(loc.translate('edit_session')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: loc.translate('description_label'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${loc.translate('date_label')}'
                              '${editDate.year.toString().padLeft(4, '0')}-'
                              '${editDate.month.toString().padLeft(2, '0')}-'
                              '${editDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await _pickDate(editDate);
                          if (picked != null) {
                            setStateDialog(() {
                              editDate = picked;
                            });
                          }
                        },
                        child: Text(loc.translate('choose_date')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: startController,
                    decoration: InputDecoration(
                      labelText: loc.translate('start_time_label'),
                      hintText: loc.translate('start_time_hint'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: endController,
                    decoration: InputDecoration(
                      labelText: loc.translate('end_time_label'),
                      hintText: loc.translate('end_time_hint'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${loc.translate('type')}:'),
                      const SizedBox(width: 8),
                      _buildTypeDropdown(
                        context: context,
                        value: editType,
                        onChanged: (newVal) {
                          if (newVal == null) return;
                          setStateDialog(() {
                            editType = newVal;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.translate('cancel_btn')),
              ),
              ElevatedButton(
                onPressed: () {
                  final newDesc = descController.text.trim();
                  final startText = startController.text.trim();
                  final endText = endController.text.trim();

                  if (newDesc.isEmpty || startText.isEmpty || endText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.translate('fill_all_fields'))),
                    );
                    return;
                  }

                  final startParts = startText.split(':');
                  final endParts = endText.split(':');
                  if (startParts.length != 2 || endParts.length != 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.translate('invalid_time_format'))),
                    );
                    return;
                  }

                  final sH = int.tryParse(startParts[0]);
                  final sM = int.tryParse(startParts[1]);
                  final eH = int.tryParse(endParts[0]);
                  final eM = int.tryParse(endParts[1]);
                  if (sH == null ||
                      sM == null ||
                      eH == null ||
                      eM == null ||
                      sH < 0 ||
                      sH > 23 ||
                      sM < 0 ||
                      sM > 59 ||
                      eH < 0 ||
                      eH > 23 ||
                      eM < 0 ||
                      eM > 59) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.translate('invalid_time_format'))),
                    );
                    return;
                  }

                  final newStart = DateTime(
                    editDate.year,
                    editDate.month,
                    editDate.day,
                    sH,
                    sM,
                  );
                  var newEnd = DateTime(
                    editDate.year,
                    editDate.month,
                    editDate.day,
                    eH,
                    eM,
                  );
                  if (newEnd.isBefore(newStart)) {
                    newEnd = newEnd.add(const Duration(days: 1));
                  }

                  setState(() {
                    _history[realIndex] = entry.copyWith(
                      start: newStart,
                      end: newEnd,
                      description: newDesc,
                      type: editType,
                    );
                  });
                  _saveHistory();
                  _addDescriptionToSaved(newDesc);

                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.translate('session_updated'))),
                  );
                },
                child: Text(loc.translate('save_btn')),
              ),
            ],
          );
        });
      },
    );

    descController.dispose();
    startController.dispose();
    endController.dispose();
  }

  Future<DateTime?> _pickDate(DateTime currentDate) async {
    return await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Widget _buildTypeDropdown({
    required BuildContext context,
    required String value,
    required void Function(String?) onChanged,
  }) {
    final loc = AppLocalizations.of(context)!;

    final defaultTypes = [
      'nauka',
      'praca_platna',
      'praca_nieplatna',
      'sport',
      'czas_wolny',
    ];

    final items = <DropdownMenuItem<String>>[];

    for (final t in defaultTypes) {
      items.add(DropdownMenuItem(
        value: t,
        child: Text(_typeLabel(t, context)),
      ));
    }

    for (final customType in _customTypes) {
      items.add(DropdownMenuItem(
        value: customType,
        child: Text(customType),
      ));
    }

    return DropdownButton<String>(
      value: items.any((item) => item.value == value) ? value : 'nauka',
      items: items,
      onChanged: onChanged,
    );
  }

  void _addCustomTypeDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.translate('add_custom_type_title')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: loc.translate('type_name_label'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.translate('cancel_btn')),
            ),
            ElevatedButton(
              onPressed: () {
                final newType = controller.text.trim();
                if (newType.isEmpty) return;
                if (_customTypes.contains(newType)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.translate('type_exists'))),
                  );
                  return;
                }
                setState(() {
                  _customTypes.add(newType);
                });
                _saveCustomTypes();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('type_added'))),
                );
              },
              child: Text(loc.translate('add_btn')),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  void _manageCustomTypesDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(loc.translate('manage_custom_types')),
              content: _customTypes.isEmpty
                  ? Text(loc.translate('no_custom_types'))
                  : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _customTypes.length,
                  itemBuilder: (context, index) {
                    final typeName = _customTypes[index];
                    return ListTile(
                      title: Text(typeName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setStateDialog(() {
                            _customTypes.removeAt(index);
                          });
                          setState(() {});
                          _saveCustomTypes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.translate('type_deleted'))),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(loc.translate('close_btn')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _typeLabel(String type, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      case 'nauka':
        return loc.translate('learning');
      case 'praca_platna':
        return loc.translate('paid_work');
      case 'praca_nieplatna':
        return loc.translate('unpaid_work');
      case 'sport':
        return loc.translate('sport');
      case 'czas_wolny':
        return loc.translate('free_time');
      default:
        return type;
    }
  }

  List<SessionEntry> get _filteredHistory {
    final now = DateTime.now();
    final filtered = _history.where((entry) {
      if (_searchText.isNotEmpty) {
        final lower = entry.description.toLowerCase();
        if (!lower.contains(_searchText.toLowerCase())) return false;
      }

      switch (_selectedRange) {
        case 'dzisiaj':
          final today = DateTime(now.year, now.month, now.day);
          final entryDay = DateTime(entry.start.year, entry.start.month, entry.start.day);
          return entryDay == today;

        case 'tydzien':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final entryDay = DateTime(entry.start.year, entry.start.month, entry.start.day);
          return !entryDay.isBefore(weekStart);

        case 'miesiac':
          return entry.start.year == now.year && entry.start.month == now.month;

        case 'wszystko':
        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) => b.start.compareTo(a.start));
    return filtered;
  }

  Map<String, Duration> _computeSummary() {
    final map = <String, Duration>{};

    for (final entry in _filteredHistory) {
      final key = entry.type;
      map[key] = (map[key] ?? Duration.zero) + entry.duration;
    }
    return map;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  String _rangeLabel(String range, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (range) {
      case 'dzisiaj':
        return loc.translate('today');
      case 'tydzien':
        return loc.translate('this_week');
      case 'miesiac':
        return loc.translate('this_month');
      case 'wszystko':
        return loc.translate('all');
      default:
        return range;
    }
  }

  Future<void> _exportHistory() async {
    final loc = AppLocalizations.of(context)!;

    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('history_empty'))),
      );
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final filename =
          'history_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}.json';
      final file = File('${dir.path}/$filename');

      final jsonList = _history.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await file.writeAsString(encoded);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.translate('export_success')}: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.translate('export_error')}: $e')),
      );
    }
  }

  Future<void> _importHistory() async {
    final loc = AppLocalizations.of(context)!;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir
          .listSync()
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f as File)
          .toList();

      if (files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('no_files_to_import'))),
        );
        return;
      }

      files.sort((a, b) => b.path.compareTo(a.path));
      final chosen = await showDialog<File>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(loc.translate('choose_file_to_import')),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final f = files[index];
                  final name = f.path.split('/').last;
                  return ListTile(
                    title: Text(name),
                    onTap: () => Navigator.of(ctx).pop(f),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.translate('cancel_btn')),
              ),
            ],
          );
        },
      );

      if (chosen == null) return;

      final content = await chosen.readAsString();
      final List<dynamic> decoded = jsonDecode(content);
      final imported = <SessionEntry>[];
      for (var item in decoded) {
        imported.add(SessionEntry.fromJson(item as Map<String, dynamic>));
      }

      setState(() {
        _history.addAll(imported);
      });
      _saveHistory();
      _updateDescriptionsFromHistory();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('import_success'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.translate('import_error')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final summary = _computeSummary();

    Widget backgroundWidget;
    if (_backgroundImagePath != null && _backgroundImagePath!.isNotEmpty) {
      backgroundWidget = Image.file(
        File(_backgroundImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      backgroundWidget = Container(
        color: Colors.grey[200],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('app_title')),
        actions: [
          // Flaga polska
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.currentLocale.languageCode == 'pl'
                      ? Colors.blue
                      : Colors.grey.shade400,
                  width: widget.currentLocale.languageCode == 'pl' ? 3 : 1,
                ),
              ),
              child: const Center(
                child: Text(
                  '🇵🇱',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            onPressed: () {
              widget.onLanguageChange('pl');
            },
            tooltip: 'Polski',
          ),
          // Flaga hiszpańska
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.currentLocale.languageCode == 'es'
                      ? Colors.blue
                      : Colors.grey.shade400,
                  width: widget.currentLocale.languageCode == 'es' ? 3 : 1,
                ),
              ),
              child: const Center(
                child: Text(
                  '🇪🇸',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            onPressed: () {
              widget.onLanguageChange('es');
            },
            tooltip: 'Español',
          ),
          const SizedBox(width: 8),
          // Menu z ustawieniami - bardziej widoczne
          PopupMenuButton<String>(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.indigo,
                size: 24,
              ),
            ),
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'change_bg') {
                _pickBackgroundImage();
              } else if (value == 'remove_bg') {
                setState(() {
                  _backgroundImagePath = null;
                });
                SharedPreferences.getInstance().then((prefs) {
                  prefs.remove('background_image_path');
                });
              } else if (value == 'icon_color') {
                _showIconColorPicker();
              } else if (value == 'manage_types') {
                _loadCustomTypes().then((_) {
                  _manageCustomTypesDialog(context);
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'change_bg',
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.indigo),
                    const SizedBox(width: 12),
                    Text(
                      loc.translate('change_background'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove_bg',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      loc.translate('remove_background'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'icon_color',
                child: Row(
                  children: [
                    const Icon(Icons.palette, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      loc.translate('icon_color_picker'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'manage_types',
                child: Row(
                  children: [
                    const Icon(Icons.category, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      loc.translate('manage_custom_types'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: backgroundWidget),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FILTR OKRESU
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(loc.translate('today')),
                        selected: _selectedRange == 'dzisiaj',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRange = 'dzisiaj';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text(loc.translate('this_week')),
                        selected: _selectedRange == 'tydzien',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRange = 'tydzien';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text(loc.translate('this_month')),
                        selected: _selectedRange == 'miesiac',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRange = 'miesiac';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text(loc.translate('all')),
                        selected: _selectedRange == 'wszystko',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRange = 'wszystko';
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // PODSUMOWANIE
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate('summary_title'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (summary.isEmpty)
                            Text(loc.translate('no_data'))
                          else
                            ...summary.entries.map((e) {
                              final typeLabel = _typeLabel(e.key, context);
                              final timeLabel = _formatDuration(e.value);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text('$typeLabel: $timeLabel'),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  // SEKCJA 1: START / STOP z AUTOCOMPLETE
                  Text(
                    loc.translate('start_stop_section'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // POLE Z AUTOCOMPLETE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _activeDescController,
                        focusNode: _activeFocusNode,
                        decoration: InputDecoration(
                          labelText: loc.translate('description_label'),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() {});
                          if (_activeStartTime != null) {
                            _saveActiveSession(); // NOWE - Zapisz przy zmianie
                          }
                        },
                      ),
                      if (_showActiveSuggestions && _activeFilteredSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _activeFilteredSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _activeFilteredSuggestions[index];
                              return ListTile(
                                dense: true,
                                title: Text(suggestion),
                                onTap: () {
                                  _activeDescController.text = suggestion;
                                  _activeFocusNode.unfocus();
                                  setState(() {
                                    _showActiveSuggestions = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(loc.translate('type')),
                      const SizedBox(width: 8),
                      _buildTypeDropdown(
                        context: context,
                        value: _activeType,
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          setState(() {
                            _activeType = newValue;
                          });
                          if (_activeStartTime != null) {
                            _saveActiveSession(); // NOWE - Zapisz przy zmianie typu
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_activeStartTime != null)
                    Text(
                      '${loc.translate('running_since')}: '
                          '${_activeStartTime!.hour.toString().padLeft(2, '0')}:'
                          '${_activeStartTime!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _activeStartTime == null
                              ? () {
                            setState(() {
                              _activeStartTime = DateTime.now();
                            });
                            _saveActiveSession(); // NOWE - Zapisz
                          }
                              : null,
                          child: Text(loc.translate('start_btn')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _activeStartTime != null ? _stopActiveSession : null,
                          child: Text(loc.translate('stop_btn')),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // SEKCJA 2: DODAWANIE MANUALNE z AUTOCOMPLETE
                  Text(
                    loc.translate('add_manual'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // POLE Z AUTOCOMPLETE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _manualDescriptionController,
                        focusNode: _manualFocusNode,
                        decoration: InputDecoration(
                          labelText: loc.translate('description_label'),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      if (_showManualSuggestions && _manualFilteredSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _manualFilteredSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _manualFilteredSuggestions[index];
                              return ListTile(
                                dense: true,
                                title: Text(suggestion),
                                onTap: () {
                                  _manualDescriptionController.text = suggestion;
                                  _manualFocusNode.unfocus();
                                  setState(() {
                                    _showManualSuggestions = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${loc.translate('date_label')}'
                              '${_manualDate.year.toString().padLeft(4, '0')}-'
                              '${_manualDate.month.toString().padLeft(2, '0')}-'
                              '${_manualDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await _pickDate(_manualDate);
                          if (picked != null) {
                            setState(() {
                              _manualDate = picked;
                            });
                          }
                        },
                        child: Text(loc.translate('choose_date')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualStartController,
                          keyboardType: TextInputType.datetime,
                          decoration: InputDecoration(
                            labelText: loc.translate('start_time_label'),
                            hintText: loc.translate('start_time_hint'),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _manualEndController,
                          keyboardType: TextInputType.datetime,
                          decoration: InputDecoration(
                            labelText: loc.translate('end_time_label'),
                            hintText: loc.translate('end_time_hint'),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(loc.translate('type')),
                      const SizedBox(width: 8),
                      _buildTypeDropdown(
                        context: context,
                        value: _manualType,
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          setState(() {
                            _manualType = newValue;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: loc.translate('add_custom_type_title'),
                        onPressed: () => _addCustomTypeDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: loc.translate('manage_custom_types'),
                        onPressed: () => _manageCustomTypesDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addManualSession,
                      child: Text(loc.translate('add_session_btn')),
                    ),
                  ),

                  const Divider(height: 32),

                  // SEKCJA 3: HISTORIA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${loc.translate('history_title')} (${_rangeLabel(_selectedRange, context)})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: loc.translate('export'),
                            icon: const Icon(Icons.upload_file),
                            onPressed: _exportHistory,
                          ),
                          IconButton(
                            tooltip: loc.translate('import'),
                            icon: const Icon(Icons.download),
                            onPressed: _importHistory,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      labelText: loc.translate('search_hint'),
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_filteredHistory.isEmpty)
                    Text(loc.translate('history_empty'))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredHistory[index];
                        final durationText = _formatDuration(entry.duration);
                        final startTime =
                            '${entry.start.hour.toString().padLeft(2, '0')}:${entry.start.minute.toString().padLeft(2, '0')}';
                        final endTime =
                            '${entry.end.hour.toString().padLeft(2, '0')}:${entry.end.minute.toString().padLeft(2, '0')}';
                        final typeText = _typeLabel(entry.type, context);
                        final modeText = entry.isManual ? 'Manualnie' : 'Start/Stop';
                        final dateLabel =
                            '${entry.start.year}-${entry.start.month.toString().padLeft(2, '0')}-${entry.start.day.toString().padLeft(2, '0')}';

                        return Card(
                          child: ListTile(
                            title: Text(entry.description),
                            subtitle: Text(
                              '$dateLabel  $startTime - $endTime  $durationText  $typeText  Tryb: $modeText',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edytuj',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editSession(index),
                                ),
                                IconButton(
                                  tooltip: 'Usuń',
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteSession(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIconColorPicker() {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(loc.translate('icon_color_picker')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.translate('slide_to_change_color')),
                  const SizedBox(height: 16),
                  Slider(
                    value: _iconHue,
                    min: 0,
                    max: 360,
                    divisions: 360,
                    label: _iconHue.round().toString(),
                    onChanged: (value) {
                      setStateDialog(() {
                        _iconHue = value;
                        _iconColor = _colorFromHue(value);
                      });
                      setState(() {
                        _iconColor = _colorFromHue(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(loc.translate('cancel_btn')),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveIconColor(_iconColor);
                    Navigator.of(ctx).pop();
                  },
                  child: Text(loc.translate('save_btn')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}