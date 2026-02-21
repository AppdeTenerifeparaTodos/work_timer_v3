import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'instructions_screen.dart';
import 'notification_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
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
      home: MainTabScreen(
        onLanguageChange: _changeLanguage,
        currentLocale: _locale,
      ),
    );
  }
}


// NOWY MODEL - CEL
class Goal {
  final String id;
  final String name;
  final double targetHours;
  final String period;
  final String? activityType;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.name,
    required this.targetHours,
    required this.period,
    this.activityType,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetHours': targetHours,
      'period': period,
      'activityType': activityType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetHours: (json['targetHours'] as num).toDouble(),
      period: json['period'] as String,
      activityType: json['activityType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// 📅 MODEL WYDARZENIA
class CalendarEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final String category;
  final String? notes;
  final int? reminderMinutes; // null = brak, 5 = 5 min przed, 15 = 15 min przed, itd.
  final DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.category,
    this.notes,
    this.reminderMinutes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'category': category,
      'notes': notes,
      'reminderMinutes': reminderMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      category: json['category'] as String,
      notes: json['notes'] as String?,
      reminderMinutes: json['reminderMinutes'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// Główny ekran z zakładkami
class MainTabScreen extends StatefulWidget {
  final Function(String) onLanguageChange;
  final Locale currentLocale;

  const MainTabScreen({
    super.key,
    required this.onLanguageChange,
    required this.currentLocale,
  });

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(
            onLanguageChange: widget.onLanguageChange,
            currentLocale: widget.currentLocale,
          ),
          StatisticsPageWrapper(),
          GamesMenuPage(), // ← ZMIENIONE!
          EventsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.indigo,
        type: BottomNavigationBarType.fixed, // ← WAŻNE! Dla 4+ zakładek
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: AppLocalizations.of(context)!.translate('summary_title'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad),
            label: AppLocalizations.of(context)!.translate('games_tab'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: AppLocalizations.of(context)!.translate('events_tab'),
          ),
        ],
      ),
    );
  }
}

// Poziomy trudności dla gry memory
enum MemoryDifficulty {
  easy,       // poziom 1
  medium,     // poziom 2
  hard,       // poziom 3
  advanced,   // poziom 4
  expert,     // poziom 5
}

// Zamiana trudności na numer poziomu (1–5)
int difficultyToLevel(MemoryDifficulty d) {
  switch (d) {
    case MemoryDifficulty.easy:
      return 1;
    case MemoryDifficulty.medium:
      return 2;
    case MemoryDifficulty.hard:
      return 3;
    case MemoryDifficulty.advanced:
      return 4;
    case MemoryDifficulty.expert:
      return 5;
  }
}


// ========================================
// 🎮 MEMORY GAME - NOWA GRA!
// ========================================
// 🎮 NOWA STRONA: MENU GIER
// Wklej to PRZED klasą MemoryCard w main.dart

// ========================================
// 📅 KALENDARZ WYDARZEŃ
// ========================================

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<CalendarEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('calendar_events');
    if (encoded == null || encoded.isEmpty) return;

    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      setState(() {
        _events.clear();
        for (var item in decoded) {
          _events.add(CalendarEvent.fromJson(item as Map<String, dynamic>));
        }
        // Sortuj po dacie
        _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
    } catch (e) {
      debugPrint('Błąd ładowania wydarzeń: $e');
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _events.map((e) => e.toJson()).toList();
    final encoded = jsonEncode(jsonList);
    await prefs.setString('calendar_events', encoded);

    for (final event in _events) {
      if (event.reminderMinutes != null) {
        await NotificationService().scheduleEventReminder(
          eventId: event.id,
          title: event.title,
          eventDateTime: event.dateTime,
          reminderMinutes: event.reminderMinutes!,
        );
      }
    }
  }

  void _deleteEvent(String eventId) {
    NotificationService().cancelEventReminder(eventId);
    setState(() {
      _events.removeWhere((e) => e.id == eventId);
    });
    _saveEvents();

    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.translate('event_deleted'))),
    );
  }

  void _addEventDialog() async {
    final loc = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final notesController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedCategory = 'praca';
    String? customCategory;
    int? reminderMinutes = 15;

    CalendarEvent? newEvent; // ← NOWE: event tworzony wewnątrz dialogu

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(loc.translate('add_event')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: loc.translate('event_title'),
                        hintText: loc.translate('event_title_hint'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(loc.translate('event_date')),
                      subtitle: Text(
                        '${selectedDate.day}.${selectedDate.month}.${selectedDate.year} '
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setStateDialog(() {
                              selectedDate = date;
                              selectedTime = time;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${loc.translate('event_category')}: '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'praca', child: Text(loc.translate('work'))),
                              DropdownMenuItem(value: 'sport', child: Text(loc.translate('sport'))),
                              DropdownMenuItem(value: 'czas_wolny', child: Text(loc.translate('free_time'))),
                              DropdownMenuItem(value: 'inne', child: Text(loc.translate('event_category_other'))),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setStateDialog(() {
                                  selectedCategory = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (selectedCategory == 'inne') ...[
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          labelText: loc.translate('event_category_custom'),
                          hintText: loc.translate('event_category_custom_hint'),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setStateDialog(() {
                            customCategory = value.trim().isEmpty ? null : value.trim();
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: loc.translate('event_notes'),
                        hintText: loc.translate('event_notes_hint'),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(loc.translate('event_reminder')),
                      subtitle: reminderMinutes == null
                          ? Text('Brak przypomnienia')
                          : Text(_getReminderLabel(reminderMinutes!)),
                      trailing: Icon(Icons.notifications),
                      onTap: () async {
                        final selected = await showDialog<int?>(
                          context: ctx,
                          builder: (dialogCtx) {
                            return SimpleDialog(
                              title: Text(loc.translate('event_reminder')),
                              children: [
                                SimpleDialogOption(child: Text('🔕 Bez przypomnienia'), onPressed: () => Navigator.pop(dialogCtx, -1)),
                                SimpleDialogOption(child: Text('⏰ 5 minut przed'), onPressed: () => Navigator.pop(dialogCtx, 5)),
                                SimpleDialogOption(child: Text('⏰ 10 minut przed'), onPressed: () => Navigator.pop(dialogCtx, 10)),
                                SimpleDialogOption(child: Text('⏰ 15 minut przed'), onPressed: () => Navigator.pop(dialogCtx, 15)),
                                SimpleDialogOption(child: Text('⏰ 30 minut przed'), onPressed: () => Navigator.pop(dialogCtx, 30)),
                                SimpleDialogOption(child: Text('⏰ 1 godzinę przed'), onPressed: () => Navigator.pop(dialogCtx, 60)),
                                SimpleDialogOption(child: Text('⏰ 2 godziny przed'), onPressed: () => Navigator.pop(dialogCtx, 120)),
                                SimpleDialogOption(child: Text('⏰ 3 godziny przed'), onPressed: () => Navigator.pop(dialogCtx, 180)),
                                SimpleDialogOption(child: Text('⏰ 6 godzin przed'), onPressed: () => Navigator.pop(dialogCtx, 360)),
                                SimpleDialogOption(child: Text('⏰ 12 godzin przed'), onPressed: () => Navigator.pop(dialogCtx, 720)),
                                SimpleDialogOption(child: Text('⏰ 1 dzień przed'), onPressed: () => Navigator.pop(dialogCtx, 1440)),
                                SimpleDialogOption(child: Text('⏰ 2 dni przed'), onPressed: () => Navigator.pop(dialogCtx, 2880)),
                                SimpleDialogOption(child: Text('⏰ 1 tydzień przed'), onPressed: () => Navigator.pop(dialogCtx, 10080)),
                              ],
                            );
                          },
                        );
                        if (selected != null) {
                          setStateDialog(() {
                            reminderMinutes = selected == -1 ? null : selected;
                          });
                        }
                      },
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
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      setStateDialog(() {}); // odświeżenie bez błędu
                      return;
                    }

                    final eventDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    // ← KLUCZOWE: zapisujemy event do zmiennej zewnętrznej
                    newEvent = CalendarEvent(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      dateTime: eventDateTime,
                      category: selectedCategory == 'inne' && customCategory != null
                          ? customCategory!
                          : selectedCategory,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      reminderMinutes: reminderMinutes,
                      createdAt: DateTime.now(),
                    );

                    Navigator.of(ctx).pop(); // zamknij dialog
                  },
                  child: Text(loc.translate('add_btn')),
                ),
              ],
            );
          },
        );
      },
    );

    // ← PO zamknięciu dialogu - bezpieczne miejsce na setState
    if (newEvent != null && mounted) {
      setState(() {
        _events.add(newEvent!);
        _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
      await _saveEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('event_added'))),
        );
      }
    }

    titleController.dispose();
    notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();

    final todayEvents = _events.where((e) {
      final eventDay = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      final today = DateTime(now.year, now.month, now.day);
      return eventDay == today;
    }).toList();

    final upcomingEvents = _events.where((e) => e.dateTime.isAfter(now)).toList();

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text(loc.translate('events_title')),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _events.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              loc.translate('no_events'),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dziś
          if (todayEvents.isNotEmpty) ...[
            Text(
              '📅 ${loc.translate('today_events')}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            const SizedBox(height: 12),
            ...todayEvents.map((event) => _buildEventCard(event)),
            const SizedBox(height: 24),
          ],

          // Nadchodzące
          if (upcomingEvents.isNotEmpty) ...[
            Text(
              '🔜 ${loc.translate('upcoming_events')}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            const SizedBox(height: 12),
            ...upcomingEvents.map((event) => _buildEventCard(event)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEventDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEvent(event.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_getDayName(event.dateTime.weekday)} ${event.dateTime.day}.${event.dateTime.month}.${event.dateTime.year} '
                      '${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getCategoryLabel(event.category),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (event.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                event.notes!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            if (event.reminderMinutes != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.notifications_active, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    _getReminderLabel(event.reminderMinutes!),
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    final loc = AppLocalizations.of(context)!;
    final isSpanish = loc.locale.languageCode == 'es';
    switch (weekday) {
      case 1: return isSpanish ? 'Lu' : 'Pn';
      case 2: return isSpanish ? 'Ma' : 'Wt';
      case 3: return isSpanish ? 'Mi' : 'Śr';
      case 4: return isSpanish ? 'Ju' : 'Cz';
      case 5: return isSpanish ? 'Vi' : 'Pt';
      case 6: return isSpanish ? 'Sá' : 'So';
      case 7: return isSpanish ? 'Do' : 'Nd';
      default: return '';
    }
  }

  String _getCategoryLabel(String category) {
    final loc = AppLocalizations.of(context)!;
    switch (category) {
      case 'praca':
        return loc.translate('work');
      case 'sport':
        return loc.translate('sport');
      case 'czas_wolny':
        return loc.translate('free_time');
      default:
        return category;
    }
  }

  String _getReminderLabel(int minutes) {
    if (minutes < 60) {
      return '$minutes min przed';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return '$hours h przed';
    } else if (minutes < 10080) {
      final days = minutes ~/ 1440;
      return '$days dni przed';
    } else {
      return '1 tydzień przed';
    }
  }
} // ← KONIEC klasy _EventsPageState
class GamesMenuPage extends StatelessWidget {
  const GamesMenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text(loc.translate('games_tab')),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek
              Text(
                loc.translate('choose_game'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.translate('games_subtitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Lista gier
              Expanded(
                child: ListView(
                  children: [
                    // Memory Game
                    _buildGameCard(
                      context,
                      icon: Icons.psychology,
                      color: Colors.purple,
                      title: loc.translate('memory_game_title'),
                      description: loc.translate('memory_game_desc'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MemoryLevelsPage(),
                          ),
                        );
                      },

                    ),

                    const SizedBox(height: 16),

                    // Snake - Coming Soon
                    _buildGameCard(
                      context,
                      icon: Icons.casino,
                      color: Colors.green,
                      title: '🐍 Snake',
                      description: loc.translate('coming_soon'),
                      isLocked: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.translate('coming_soon')),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // 2048 - Coming Soon
                    _buildGameCard(
                      context,
                      icon: Icons.grid_4x4,
                      color: Colors.orange,
                      title: '🎯 2048',
                      description: loc.translate('coming_soon'),
                      isLocked: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.translate('coming_soon')),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String description,
        required VoidCallback onTap,
        bool isLocked = false,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                color.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Ikona
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLocked ? Icons.lock : icon,
                  size: 32,
                  color: color,
                ),
              ),

              const SizedBox(width: 16),

              // Tekst
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Strzałka
              Icon(
                Icons.arrow_forward_ios,
                color: isLocked ? Colors.grey : Colors.indigo,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ekran wyboru poziomu Memory
class MemoryLevelsPage extends StatefulWidget {
  const MemoryLevelsPage({super.key});

  @override
  State<MemoryLevelsPage> createState() => _MemoryLevelsPageState();
}

class _MemoryLevelsPageState extends State<MemoryLevelsPage> {
  int _maxUnlockedLevel = 1; // na początku tylko łatwy

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxUnlockedLevel = prefs.getInt('memory_max_level') ?? 1;
    });
  }

  Future<void> _saveProgress(int newLevel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('memory_max_level', newLevel);
  }

  void _openLevel(MemoryDifficulty difficulty) {
    final loc = AppLocalizations.of(context)!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemoryGamePage(
          difficulty: difficulty,
          onLevelCompleted: () {
            final level = difficultyToLevel(difficulty);
            if (level >= _maxUnlockedLevel && level < 5) {
              final nextLevel = level + 1;
              setState(() {
                _maxUnlockedLevel = nextLevel;
              });
              _saveProgress(nextLevel);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.translate('congratulations')),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  bool _isLocked(MemoryDifficulty difficulty) {
    final level = difficultyToLevel(difficulty);
    return level > _maxUnlockedLevel;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text(loc.translate('memory_choose_level')),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset poziomów',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('memory_max_level_v2'); // ten sam klucz co w _loadProgress/_saveProgress
              setState(() {
                _maxUnlockedLevel = 1;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Postęp poziomów zresetowany'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLevelTile(
            title: loc.translate('memory_level_easy'),
            difficulty: MemoryDifficulty.easy,
          ),
          _buildLevelTile(
            title: loc.translate('memory_level_medium'),
            difficulty: MemoryDifficulty.medium,
          ),
          _buildLevelTile(
            title: loc.translate('memory_level_hard'),
            difficulty: MemoryDifficulty.hard,
          ),
          _buildLevelTile(
            title: loc.translate('memory_level_advanced'),
            difficulty: MemoryDifficulty.advanced,
          ),
          _buildLevelTile(
            title: loc.translate('memory_level_expert'),
            difficulty: MemoryDifficulty.expert,
          ),
        ],
      ),
    );
  }


  Widget _buildLevelTile({
    required String title,
    required MemoryDifficulty difficulty,
  }) {
    final loc = AppLocalizations.of(context)!;
    final isLocked = _isLocked(difficulty);

    return Card(
      child: ListTile(
        leading: Icon(
          isLocked ? Icons.lock : Icons.lock_open,
          color: isLocked ? Colors.grey : Colors.indigo,
        ),
        title: Text(title),
        subtitle: isLocked
            ? Text(
          loc.translate('memory_locked'),
          style: const TextStyle(fontSize: 12),
        )
            : null,
        onTap: isLocked ? null : () => _openLevel(difficulty),
      ),
    );
  }
}


class MemoryCard {
  final String emoji;
  final int id;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.emoji,
    required this.id,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class MemoryGamePage extends StatefulWidget {
  final MemoryDifficulty difficulty;     // NOWE
  final VoidCallback? onLevelCompleted;  // NOWE

  const MemoryGamePage({
    super.key,
    this.difficulty = MemoryDifficulty.easy, // domyślnie łatwy
    this.onLevelCompleted,
  });

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}


// 🎮 ZAMIEŃ CAŁĄ KLASĘ _MemoryGamePageState NA TEN KOD:

class _MemoryGamePageState extends State<MemoryGamePage> {
  List<MemoryCard> _cards = [];
  List<int> _flippedIndices = [];

  int _moves = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameWon = false;

  Map<int, int> _bestTimesByLevel = {}; // level → best time in seconds
  Map<int, int> _bestMovesByLevel = {}; // level → best moves

// 🎨 Różne emotki dla każdego poziomu
  List<String> _getEmojisForLevel() {
    switch (widget.difficulty) {
      case MemoryDifficulty.easy:
      // 🍎 Poziom 1: OWOCE (6 par)
        return ['🍎', '🍊', '🍋', '🍌', '🍉', '🍇'];

      case MemoryDifficulty.medium:
      // 🐶 Poziom 2: ZWIERZĘTA (8 par)
        return ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];

      case MemoryDifficulty.hard:
      // 🍕 Poziom 3: JEDZENIE (10 par)
        return ['🍕', '🍔', '🍟', '🌭', '🍿', '🥤', '🍩', '🍪', '🎂', '🍰'];

      case MemoryDifficulty.advanced:
      // ⚽ Poziom 4: SPORT (12 par)
        return ['⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸', '🏒', '🥊'];

      case MemoryDifficulty.expert:
      // 🌟 Poziom 5: MIX WSZYSTKIEGO (15 par)
        return ['🌍', '🌈', '⭐', '🌙', '☀️', '🌊', '🔥', '❄️', '💎', '🎯', '🎨', '🎭', '🎪', '🎮', '🎸'];
    }
  }

  // Ile par kart ma być dla danego poziomu trudności
  int _pairsForDifficulty() {
    switch (widget.difficulty) {
      case MemoryDifficulty.easy:
        return 6;  // 6 par → 12 kart
      case MemoryDifficulty.medium:
        return 8;
      case MemoryDifficulty.hard:
        return 10;
      case MemoryDifficulty.advanced:
        return 12;
      case MemoryDifficulty.expert:
        return 15;
    }
  }
// 📐 Ile kolumn w siatce dla danego poziomu
  int _getCrossAxisCount() {
    switch (widget.difficulty) {
      case MemoryDifficulty.easy:
      case MemoryDifficulty.medium:
      case MemoryDifficulty.hard:
        return 4; // Poziomy 1-3: 4 kolumny
      case MemoryDifficulty.advanced:
        return 4; // Poziom 4: 4 kolumny
      case MemoryDifficulty.expert:
        return 5; // Poziom 5: 5 kolumn (mniej scrollu!)
    }
  }

// 📏 Proporcje karty dla danego poziomu
  double _getAspectRatio() {
    // Wykryj czy jesteśmy na telefonie czy w przeglądarce
    final isWeb = MediaQuery.of(context).size.width > 600;

    switch (widget.difficulty) {
      case MemoryDifficulty.easy:
      case MemoryDifficulty.medium:
        return isWeb ? 0.60 : 0.75; // Przeglądarka: niższe | Telefon: normalne
      case MemoryDifficulty.hard:
        return isWeb ? 0.65 : 0.80;
      case MemoryDifficulty.advanced:
        return isWeb ? 0.70 : 0.85;
      case MemoryDifficulty.expert:
        return isWeb ? 0.75 : 0.90; // Poziom 5: mniejsze w obu
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHighScores();
    _initializeGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final level = difficultyToLevel(widget.difficulty);

    setState(() {
      _bestTimesByLevel[level] = prefs.getInt('memory_best_time_level_$level') ?? 0;
      _bestMovesByLevel[level] = prefs.getInt('memory_best_moves_level_$level') ?? 0;
    });
  }

  Future<void> _saveHighScores() async {
    if (!_gameWon) return;

    final prefs = await SharedPreferences.getInstance();
    final level = difficultyToLevel(widget.difficulty);

    // Pobierz obecny rekord dla tego poziomu
    final currentBestTime = _bestTimesByLevel[level] ?? 0;
    final currentBestMoves = _bestMovesByLevel[level] ?? 0;

    // Zapisz nowy rekord czasu jeśli lepszy (lub pierwszy)
    if (currentBestTime == 0 || _seconds < currentBestTime) {
      await prefs.setInt('memory_best_time_level_$level', _seconds);
      setState(() {
        _bestTimesByLevel[level] = _seconds;
      });

      // Zapisz gwiazdki
      final stars = _calculateStars();
      await prefs.setInt('memory_stars_level_$level', stars);
    }

    // Zapisz nowy rekord ruchów jeśli lepszy (lub pierwszy)
    if (currentBestMoves == 0 || _moves < currentBestMoves) {
      await prefs.setInt('memory_best_moves_level_$level', _moves);
      setState(() {
        _bestMovesByLevel[level] = _moves;
      });
    }
  }

  void _initializeGame() {
    _timer?.cancel();

    final cards = <MemoryCard>[];

    // ile par ma być na tym poziomie
    final pairsCount = _pairsForDifficulty();

    // bierzemy tylko pierwsze N emoji z listy
    final availableEmojis = _getEmojisForLevel();

    for (int i = 0; i < availableEmojis.length; i++) {
      cards.add(MemoryCard(emoji: availableEmojis[i], id: i));
      cards.add(MemoryCard(emoji: availableEmojis[i], id: i));
    }

    cards.shuffle(Random());

    setState(() {
      _cards = cards;
      _flippedIndices.clear();
      _moves = 0;
      _seconds = 0;
      _gameStarted = false;
      _gameWon = false;
    });
  }


  void _startTimer() {
    if (_gameStarted) return;

    _gameStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _onCardTap(int index) {
    if (_flippedIndices.length >= 2) return;
    if (_cards[index].isFlipped || _cards[index].isMatched) return;
    if (_gameWon) return;

    if (!_gameStarted) {
      _startTimer();
    }

    setState(() {
      _cards[index].isFlipped = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      _moves++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    final index1 = _flippedIndices[0];
    final index2 = _flippedIndices[1];

    final card1 = _cards[index1];
    final card2 = _cards[index2];

    if (card1.id == card2.id) {
      setState(() {
        card1.isMatched = true;
        card2.isMatched = true;
        _flippedIndices.clear();
      });

      if (_cards.every((card) => card.isMatched)) {
        _timer?.cancel();
        setState(() {
          _gameWon = true;
        });
        _saveHighScores();

        // powiadomienie menu poziomów, że level ukończony
        widget.onLevelCompleted?.call();

        _showWinDialog();
      }

    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            card1.isFlipped = false;
            card2.isFlipped = false;
            _flippedIndices.clear();
          });
        }
      });
    }
  }

  void _showWinDialog() {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(loc.translate('congratulations')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('game_completed'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // ⭐ GWIAZDKI
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final stars = _calculateStars();
                  return Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text('⏱️ ${loc.translate('time')}: ${_formatTime(_seconds)}'),
              Text('🎯 ${loc.translate('moves')}: $_moves'),
              const SizedBox(height: 16),
                  () {
                final level = difficultyToLevel(widget.difficulty);
                final bestTime = _bestTimesByLevel[level] ?? 0;
                if (bestTime > 0 && _seconds == bestTime) {
                  return Text(
                    loc.translate('new_time_record'),
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  );
                }
                return const SizedBox();
              }(),
                  () {
                final level = difficultyToLevel(widget.difficulty);
                final bestMoves = _bestMovesByLevel[level] ?? 0;
                if (bestMoves > 0 && _moves == bestMoves) {
                  return Text(
                    loc.translate('new_moves_record'),
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  );
                }
                return const SizedBox();
              }(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _initializeGame();
              },
              child: Text(loc.translate('play_again')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  // ⭐ Oblicz ile gwiazdek za czas
  int _calculateStars() {
    // Progi czasowe zależne od poziomu
    int gold, silver;

    switch (widget.difficulty) {
      case MemoryDifficulty.easy:
        gold = 30;   // ⭐⭐⭐
        silver = 60; // ⭐⭐
        break;
      case MemoryDifficulty.medium:
        gold = 40;
        silver = 80;
        break;
      case MemoryDifficulty.hard:
        gold = 50;
        silver = 100;
        break;
      case MemoryDifficulty.advanced:
        gold = 60;
        silver = 120;
        break;
      case MemoryDifficulty.expert:
        gold = 75;
        silver = 150;
        break;
    }

    if (_seconds <= gold) return 3;
    if (_seconds <= silver) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text(loc.translate('memory_game_title')),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeGame,
            tooltip: loc.translate('new_game'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Statystyki
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox('⏱️ ${loc.translate('time')}', _formatTime(_seconds)),
                  _buildStatBox('🎯 ${loc.translate('moves')}', _moves.toString()),
                      () {
                    final level = difficultyToLevel(widget.difficulty);
                    final bestTime = _bestTimesByLevel[level] ?? 0;
                    if (bestTime > 0) {
                      return _buildStatBox('🏆 ${loc.translate('record')}', _formatTime(bestTime));
                    }
                    return const SizedBox();
                  }(),
                ],
              ),
            ),

            // Instrukcja
            if (!_gameStarted)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.translate('game_instructions'),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Plansza z kartami
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: null, // domyślne scrollowanie
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: _getAspectRatio(),
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      return _buildCard(card, index);
                    },
                  ),
                ),
              ),
            ),

            // High scores
                () {
              final level = difficultyToLevel(widget.difficulty);
              final bestTime = _bestTimesByLevel[level] ?? 0;
              final bestMoves = _bestMovesByLevel[level] ?? 0;

              if (bestTime > 0 || bestMoves > 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('your_records'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (bestTime > 0)
                        Text('${loc.translate('best_time')} ${_formatTime(bestTime)}'),
                      if (bestMoves > 0)
                        Text('${loc.translate('fewest_moves')} $bestMoves'),
                    ],
                  ),
                );
              }
              return const SizedBox();
            }(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(MemoryCard card, int index) {
    final isVisible = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isVisible
              ? (card.isMatched ? Colors.green.shade100 : Colors.white)
              : Colors.indigo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card.isMatched ? Colors.green : Colors.indigo.shade700,
            width: card.isMatched ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isVisible
              ? Text(
            card.emoji,
            style: const TextStyle(fontSize: 40),
          )
              : const Icon(
            Icons.question_mark,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Wrapper dla StatisticsPage który przekazuje historię z HomePage
class StatisticsPageWrapper extends StatelessWidget {
  const StatisticsPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Znajdź HomePage w drzewie widgetów i pobierz historię
    return StatisticsPageContent();
  }
}

class StatisticsPageContent extends StatefulWidget {
  const StatisticsPageContent({super.key});

  @override
  State<StatisticsPageContent> createState() => _StatisticsPageContentState();
}

class _StatisticsPageContentState extends State<StatisticsPageContent> {
  List<SessionEntry> _history = [];
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
    } catch (e) {
      debugPrint('Błąd podczas ładowania historii: $e');
    }
  }

  List<SessionEntry> get _filteredHistory {
    final now = DateTime.now();

    return _history.where((entry) {
      switch (_selectedPeriod) {
        case 'week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final entryDay = DateTime(entry.start.year, entry.start.month, entry.start.day);
          return !entryDay.isBefore(weekStart);

        case 'month':
          return entry.start.year == now.year && entry.start.month == now.month;

        case '30days':
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          return entry.start.isAfter(thirtyDaysAgo);

        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  Map<String, Duration> _getTotalByType() {
    final map = <String, Duration>{};

    for (final entry in _filteredHistory) {
      final key = entry.type;
      map[key] = (map[key] ?? Duration.zero) + entry.duration;
    }

    return map;
  }

  List<BarChartGroupData> _getBarChartData() {
    final now = DateTime.now();
    final last7Days = <DateTime>[];

    for (int i = 6; i >= 0; i--) {
      last7Days.add(DateTime(
        now.year,
        now.month,
        now.day - i,
      ));
    }

    final dataByDay = <DateTime, double>{};
    for (final day in last7Days) {
      dataByDay[day] = 0.0;
    }

    for (final entry in _filteredHistory) {
      final entryDay = DateTime(
        entry.start.year,
        entry.start.month,
        entry.start.day,
      );

      if (dataByDay.containsKey(entryDay)) {
        dataByDay[entryDay] = dataByDay[entryDay]! + entry.duration.inMinutes / 60.0;
      }
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < last7Days.length; i++) {
      final hours = dataByDay[last7Days[i]] ?? 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hours,
              color: Colors.indigo,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  List<PieChartSectionData> _getPieChartData() {
    final totalByType = _getTotalByType();
    if (totalByType.isEmpty) return [];

    final totalMinutes = totalByType.values
        .fold<int>(0, (sum, duration) => sum + duration.inMinutes);

    // Stała lista kolorów
    final colorList = [
      Colors.indigo,
      Colors.red,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    totalByType.forEach((type, duration) {
      final percentage = (duration.inMinutes / totalMinutes * 100);
      final color = colorList[colorIndex % colorList.length];
      colorIndex++;

      sections.add(
        PieChartSectionData(
          value: duration.inMinutes.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          color: color,
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return sections;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'nauka':
        return 'Nauka';
      case 'praca_platna':
        return 'Praca płatna';
      case 'praca_nieplatna':
        return 'Praca niepłatna';
      case 'sport':
        return 'Sport';
      case 'czas_wolny':
        return 'Czas wolny';
      default:
        return type;
    }
  }

  Color _getColorForType(String type) {
    final colorList = [
      Colors.indigo,
      Colors.red,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final keys = _getTotalByType().keys.toList();
    final index = keys.indexOf(type);
    if (index == -1) return Colors.grey;
    return colorList[index % colorList.length];
  }

  double _getMaxY(List<BarChartGroupData> data) {
    if (data.isEmpty) return 10;
    final maxValue = data
        .map((group) => group.barRods.first.toY)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final totalByType = _getTotalByType();
    final totalTime = totalByType.values
        .fold<Duration>(Duration.zero, (sum, duration) => sum + duration);

    final pieData = _getPieChartData();
    final barData = _getBarChartData();

    String mostProductiveDay = '-';
    if (_filteredHistory.isNotEmpty) {
      final dayTotals = <DateTime, Duration>{};
      for (final entry in _filteredHistory) {
        final day = DateTime(entry.start.year, entry.start.month, entry.start.day);
        dayTotals[day] = (dayTotals[day] ?? Duration.zero) + entry.duration;
      }
      if (dayTotals.isNotEmpty) {
        final maxDay = dayTotals.entries.reduce((a, b) =>
        a.value.inMinutes > b.value.inMinutes ? a : b);
        mostProductiveDay = '${maxDay.key.day}.${maxDay.key.month}.${maxDay.key.year}';
      }
    }

    final dayCount = _selectedPeriod == 'week' ? 7 :
    _selectedPeriod == 'month' ? 30 :
    _selectedPeriod == '30days' ? 30 :
    1;
    final avgPerDay = Duration(minutes: totalTime.inMinutes ~/ dayCount);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Statystyki'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież',
            onPressed: () {
              setState(() {
                _loadHistory();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statystyki odświeżone'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtry okresów
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPeriodChip('Ten tydzień', 'week'),
                    const SizedBox(width: 8),
                    _buildPeriodChip('Ten miesiąc', 'month'),
                    const SizedBox(width: 8),
                    _buildPeriodChip('Ostatnie 30 dni', '30days'),
                    const SizedBox(width: 8),
                    _buildPeriodChip('Wszystko', 'all'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Kluczowe statystyki
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Suma czasu',
                      _formatDuration(totalTime),
                      Icons.timer,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Sesji',
                      '${_filteredHistory.length}',
                      Icons.list_alt,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Średnio/dzień',
                      _formatDuration(avgPerDay),
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Najlepszy dzień',
                      mostProductiveDay,
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Wykres słupkowy
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ostatnie 7 dni',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: barData.isEmpty
                            ? const Center(child: Text('Brak danych'))
                            : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxY(barData),
                            barGroups: barData,
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}h',
                                      style: TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final now = DateTime.now();
                                    final day = now.subtract(Duration(days: 6 - value.toInt()));
                                    final weekdays = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];
                                    return Text(
                                      weekdays[(day.weekday - 1) % 7],
                                      style: TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Wykres kołowy
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Podział czasu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (pieData.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('Brak danych'),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: pieData,
                                    centerSpaceRadius: 0,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: totalByType.entries.map((entry) {
                                  final color = _getColorForType(entry.key);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _typeLabel(entry.key),
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Szczegółowe podsumowanie
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Szczegółowe podsumowanie',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (totalByType.isEmpty)
                        const Text('Brak danych')
                      else
                        ...totalByType.entries.map((entry) {
                          final percentage = totalTime.inMinutes > 0
                              ? (entry.value.inMinutes / totalTime.inMinutes * 100)
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _typeLabel(entry.key),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(entry.value),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[200],
                                  color: _getColorForType(entry.key),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% całkowitego czasu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = value;
          });
        }
      },
      selectedColor: Colors.indigo,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
  // NOWE - Lista celów
  final List<Goal> _goals = [];
  // NOWE - lista wydarzeń do backupu
  List<CalendarEvent> _events = [];


  final List<String> _savedDescriptions = [];

  String? _backgroundImagePath;
  final ImagePicker _picker = ImagePicker();
  Color _iconColor = Colors.white;
  double _iconHue = 0.0;

  DateTime? _activeStartTime;
  String _activeDescription = '';
  String _activeType = 'praca';

  final List<SessionEntry> _history = [];

  final TextEditingController _manualDescriptionController = TextEditingController();
  final TextEditingController _manualStartController = TextEditingController();
  final TextEditingController _manualEndController = TextEditingController();
  String _manualType = 'praca';

  DateTime _manualDate = DateTime.now();

  String _selectedRange = 'dzisiaj';
  String _searchText = '';
  bool _showManualFields = false;

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
    _loadGoals(); // NOWE
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


  // NOWE - Zarządzanie celami
  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('goals');
    if (encoded == null || encoded.isEmpty) return;
    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      setState(() {
        _goals.clear();
        for (var item in decoded) {
          _goals.add(Goal.fromJson(item as Map<String, dynamic>));
        }
      });
    } catch (e) {
      debugPrint('Błąd podczas ładowania celów: $e');
    }
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _goals.map((e) => e.toJson()).toList();
    final encoded = jsonEncode(jsonList);
    await prefs.setString('goals', encoded);
    // Auto-refresh - odświeża UI
    setState(() {});
  }

  void _addGoalDialog() async {
    final loc = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final hoursController = TextEditingController();
    String selectedPeriod = 'week';
    String? selectedType;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(loc.translate('add_goal')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: loc.translate('goal_name'),
                        hintText: loc.translate('goal_name_hint'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.translate('goal_hours'),
                        hintText: loc.translate('goal_hours_hint'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(loc.translate('goal_period') + ': '),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: selectedPeriod,
                          items: const [
                            DropdownMenuItem(value: 'week', child: Text('Tydzień')),
                            DropdownMenuItem(value: 'month', child: Text('Miesiąc')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setStateDialog(() {
                                selectedPeriod = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(loc.translate('goal_type') + ': '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String?>(
                            value: selectedType,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: null, child: Text(loc.translate('goal_all_types'))),
                              DropdownMenuItem(value: 'praca', child: Text(loc.translate('work'))),
                              DropdownMenuItem(value: 'sport', child: Text(loc.translate('sport'))),
                              DropdownMenuItem(value: 'czas_wolny', child: Text(loc.translate('free_time'))),
                              ..._customTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
                            ],
                            onChanged: (value) {
                              setStateDialog(() {
                                selectedType = value;
                              });
                            },
                          ),
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
                    final name = nameController.text.trim();
                    final hoursText = hoursController.text.trim();

                    if (name.isEmpty || hoursText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.translate('fill_all_fields'))),
                      );
                      return;
                    }

                    final hours = double.tryParse(hoursText);
                    if (hours == null || hours <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.translate('goal_invalid_hours'))),
                      );
                      return;
                    }

                    final newGoal = Goal(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      targetHours: hours,
                      period: selectedPeriod,
                      activityType: selectedType,
                      createdAt: DateTime.now(),
                    );

                    setState(() {
                      _goals.add(newGoal);
                    });
                    _saveGoals();

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.translate('goal_added'))),
                    );
                  },
                  child: Text(loc.translate('add_btn')),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    hoursController.dispose();
  }

  void _deleteGoal(String goalId) {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _goals.removeWhere((g) => g.id == goalId);
    });
    _saveGoals();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.translate('goal_deleted'))),
    );
  }

  double _calculateGoalProgress(Goal goal) {
    final now = DateTime.now();
    List<SessionEntry> relevantEntries = [];

    for (final entry in _history) {
      if (goal.activityType != null && entry.type != goal.activityType) {
        continue;
      }

      if (goal.period == 'week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final entryDay = DateTime(entry.start.year, entry.start.month, entry.start.day);
        if (entryDay.isBefore(weekStart)) continue;
      } else if (goal.period == 'month') {
        if (entry.start.year != now.year || entry.start.month != now.month) continue;
      }

      relevantEntries.add(entry);
    }

    final totalMinutes = relevantEntries.fold<int>(
      0,
          (sum, entry) => sum + entry.duration.inMinutes,
    );
    final totalHours = totalMinutes / 60.0;
    return totalHours;
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
    // Auto-refresh - odświeża statystyki
    setState(() {});
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

  // NOWE: eksport całej bazy (historia + cele + wydarzenia) do jednego pliku JSON
  Future<File?> _exportAllData() async {
    try {
      final loc = AppLocalizations.of(context)!;

      // 1. Katalog na backup (tak jak w starym exportHistory)
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/WorkStudyTimer');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 2. Budujemy strukturę JSON
      final backupData = {
        'history': _history.map((e) => e.toJson()).toList(),
        'goals': _goals.map((g) => g.toJson()).toList(),
        'events': _events.map((ev) => ev.toJson()).toList(),
      };

      final jsonString =
      const JsonEncoder.withIndent('  ').convert(backupData);

      // 3. Zapis do pliku
      final file = File('${backupDir.path}/backup.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('backup_saved'))),
        );
      }

      return file;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd eksportu: $e')),
        );
      }
      return null;
    }
  }

  // NOWE: import całej bazy (historia + cele + wydarzenia) z jednego pliku JSON
  Future<void> _importAllData() async {
    final loc = AppLocalizations.of(context)!;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/WorkStudyTimer');

      if (!await backupDir.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Brak folderu z backupem')),
        );
        return;
      }

      // Szukamy plików .json
      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Brak plików backupu (.json)')),
        );
        return;
      }

      // Na razie bierzemy pierwszy znaleziony plik
      File selectedFile = files.first;

      final content = await selectedFile.readAsString();
      final decoded = jsonDecode(content);

      // STARY FORMAT: lista historii (List)
      if (decoded is List) {
        final List<dynamic> list = decoded;
        setState(() {
          for (var item in list) {
            _history
                .add(SessionEntry.fromJson(item as Map<String, dynamic>));
          }
        });
        await _saveHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zaimportowano historię (stary format pliku)'),
            ),
          );
        }
        return;
      }

      // NOWY FORMAT: mapa z history/goals/events
      if (decoded is Map<String, dynamic>) {
        final List<dynamic> historyList = decoded['history'] ?? [];
        final List<dynamic> goalsList = decoded['goals'] ?? [];
        final List<dynamic> eventsList = decoded['events'] ?? [];

        setState(() {
          // Historia – DOKLEJAMY
          for (var item in historyList) {
            _history
                .add(SessionEntry.fromJson(item as Map<String, dynamic>));
          }

          // Cele – NADPISUJEMY
          _goals.clear();
          for (var item in goalsList) {
            _goals.add(Goal.fromJson(item as Map<String, dynamic>));
          }

          // Wydarzenia – NADPISUJEMY
          _events.clear();
          for (var item in eventsList) {
            _events
                .add(CalendarEvent.fromJson(item as Map<String, dynamic>));
          }
        });

        await _saveHistory();
        await _saveGoals();

        // Zapisz wydarzenia tak samo jak w EventsPage
        final prefs = await SharedPreferences.getInstance();
        final jsonList = _events.map((e) => e.toJson()).toList();
        final encoded = jsonEncode(jsonList);
        await prefs.setString('calendar_events', encoded);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zaimportowano historię, cele i wydarzenia'),
            ),
          );
        }
        return;

      }

      // Format nieznany
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nieznany format pliku backupu')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd importu: $e')),
      );
    }
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
        final type = prefs.getString('active_session_type') ?? 'praca';

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
    final description = _activeDescController.text.trim(); // ✅ POPRAWIONE!

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
      type: _activeType, // ✅ POPRAWIONE!
    );

    setState(() {
      _history.add(newEntry);
      _activeDescController.clear(); // ✅ POPRAWIONE!
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

    return InkWell(
      onTap: () async {
        // Pokaż dialog wyboru typu z zarządzaniem
        final selected = await showDialog<String>(
          context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setStateDialog) {
                return AlertDialog(
                  title: Text(loc.translate('type')),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        // 3 domyślne typy
                        _buildTypeOption(ctx, 'praca', loc.translate('work'), false),
                        _buildTypeOption(ctx, 'sport', loc.translate('sport'), false),
                        _buildTypeOption(ctx, 'czas_wolny', loc.translate('free_time'), false),

                        const Divider(height: 32),

                        // Własne typy z przyciskiem usuń
                        ..._customTypes.map((customType) {
                          return ListTile(
                            title: Text(customType),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setStateDialog(() {
                                  _customTypes.remove(customType);
                                });
                                setState(() {});
                                _saveCustomTypes();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(loc.translate('type_deleted'))),
                                );
                              },
                            ),
                            onTap: () => Navigator.of(ctx).pop(customType),
                          );
                        }),

                        const Divider(height: 32),

                        // Dodaj nowy typ
                        ListTile(
                          leading: null,  // ← USUŃ IKONĘ
                          title: Text(
                            loc.translate('add_new_type'),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () async {
                            final controller = TextEditingController();
                            final newType = await showDialog<String>(
                              context: ctx,
                              builder: (dialogCtx) {
                                return AlertDialog(
                                  title: Text(loc.translate('add_custom_type_title')),
                                  content: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: loc.translate('type_name_label'),
                                      hintText: loc.translate('custom_type_hint'),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogCtx).pop(),
                                      child: Text(loc.translate('cancel_btn')),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        final name = controller.text.trim();
                                        if (name.isNotEmpty) {
                                          Navigator.of(dialogCtx).pop(name);
                                        }
                                      },
                                      child: Text(loc.translate('add_btn')),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (newType != null && newType.isNotEmpty) {
                              if (_customTypes.contains(newType) ||
                                  newType == 'praca' ||
                                  newType == 'sport' ||
                                  newType == 'czas_wolny') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(loc.translate('type_exists'))),
                                );
                              } else {
                                setStateDialog(() {
                                  _customTypes.add(newType);
                                });
                                setState(() {});
                                _saveCustomTypes();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(loc.translate('type_added'))),
                                );
                              }
                            }

                            controller.dispose();
                          },
                        ),
                      ],
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
          },
        );

        if (selected != null) {
          onChanged(selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_typeLabel(value, context)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(BuildContext ctx, String typeValue, String label, bool showDelete) {
    return ListTile(
      title: Text(label),
      onTap: () => Navigator.of(ctx).pop(typeValue),
    );
  }

  String _getDayNameHome(int weekday) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isSpanish = languageCode == 'es';
    switch (weekday) {
      case 1: return isSpanish ? 'Lu' : 'Pn';
      case 2: return isSpanish ? 'Ma' : 'Wt';
      case 3: return isSpanish ? 'Mi' : 'Śr';
      case 4: return isSpanish ? 'Ju' : 'Cz';
      case 5: return isSpanish ? 'Vi' : 'Pt';
      case 6: return isSpanish ? 'Sá' : 'So';
      case 7: return isSpanish ? 'Do' : 'Nd';
      default: return '';
    }
  }



  String _typeLabel(String type, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      case 'praca':
        return loc.translate('work');
      case 'sport':
        return loc.translate('sport');
      case 'czas_wolny':
        return loc.translate('free_time');
      default:
        return type; // Własne typy wyświetlają swoją nazwę
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
      // 1. Katalog dokumentów aplikacji (prywatny, ale stały)
      final dir = await getApplicationDocumentsDirectory();

      // 2. Podkatalog na backupy
      final backupDir = Directory('${dir.path}/WorkStudyTimer');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 3. Jeden stały plik backup.json
      final file = File('${backupDir.path}/backup.json');

      // 4. JSON z całej historii
      final jsonList = _history.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(jsonList);

      // 5. Zapis do pliku
      await file.writeAsString(encoded);

      if (!mounted) return;

      // 6. Komunikat dla użytkownika – gdzie jest plik
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${loc.translate('export_success')}: ${file.path}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.translate('export_error')}: $e'),
        ),
      );
    }
  }

  // NOWA FUNKCJA – najpierw zapisuje backup.json, potem otwiera okno udostępniania
  Future<void> _shareHistoryBackup() async {
    final loc = AppLocalizations.of(context)!;

    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('history_empty'))),
      );
      return;
    }

    try {
      // 1. Najpierw zapisujemy backup tak jak w _exportHistory
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/WorkStudyTimer');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final file = File('${backupDir.path}/backup.json');

      final jsonList = _history.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await file.writeAsString(encoded);

      if (!mounted) return;

      // 2. Otwieramy systemowe okno „Udostępnij”
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
        'Backup historii z aplikacji Work Study Timer. Zapisz ten plik w bezpiecznym miejscu.',
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
      appBar: _activeStartTime != null
          ? AppBar(
        backgroundColor: Colors.green,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 8),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    if (_activeStartTime == null) return const SizedBox();
                    final duration = DateTime.now().difference(_activeStartTime!);
                    final hours = duration.inHours;
                    final minutes = duration.inMinutes.remainder(60);
                    final seconds = duration.inSeconds.remainder(60);
                    return Text(
                      '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (_activeDescController.text.isNotEmpty)
              Text(
                _activeDescController.text,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _stopActiveSession,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: Text(
              loc.translate('stop_btn').toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      )
          : AppBar(
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
              if (value == 'instructions') {
                // otwieramy ekran instrukcji
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InstructionsScreen(),
                  ),
                );
              } else if (value == 'change_bg') {
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
              }  // ← DODAJ TEN NAWIAS!
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

              // ⬇️ OSTATNIA POZYCJA – Instrukcja obsługi
              PopupMenuItem(
                value: 'instructions',
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, color: Colors.indigo),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context).translate('instructions_title'),
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


                  // PODSUMOWANIE
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate('summary_title'),
                            style: TextStyle(
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


                  const SizedBox(height: 16),

                  // SEKCJA CELÓW 🎯
                  Card(
                    color: Colors.indigo.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.flag, color: Colors.indigo),
                                  SizedBox(width: 8),
                                  Text(
                                    loc.translate('goals_title'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _addGoalDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(loc.translate('add_goal')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_goals.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  loc.translate('no_goals'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._goals.map((goal) {
                              final progress = _calculateGoalProgress(goal);
                              final percentage = (progress / goal.targetHours * 100).clamp(0, 100);
                              final isCompleted = progress >= goal.targetHours;

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  goal.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${goal.period == 'week' ? 'Tydzień' : 'Miesiąc'}'
                                                      '${goal.activityType != null ? ' • ${_typeLabel(goal.activityType!, context)}' : ' • Wszystkie'}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20),
                                            onPressed: () => _deleteGoal(goal.id),
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${progress.toStringAsFixed(1)}h / ${goal.targetHours.toStringAsFixed(0)}h',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '${percentage.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isCompleted ? Colors.green : Colors.indigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          minHeight: 10,
                                          backgroundColor: Colors.grey[300],
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isCompleted ? Colors.green : Colors.indigo,
                                          ),
                                        ),
                                      ),
                                      if (isCompleted)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              Icon(Icons.celebration, size: 16, color: Colors.green),
                                              const SizedBox(width: 4),
                                              Text(
                                                loc.translate('goal_completed') + ' 🎉',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Jeszcze ${(goal.targetHours - progress).toStringAsFixed(1)}h do celu',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 32),

// 🟢 WIELKI PRZYCISK START - NA SAMEJ GÓRZE!
                  if (_activeStartTime == null)
                    Container(
                      width: double.infinity,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _activeStartTime = DateTime.now();
                          });
                          _saveActiveSession();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_filled, size: 40),
                            const SizedBox(width: 12),
                            Text(
                              loc.translate('start_btn').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

// Nagłówek sekcji
                  Text(
                    loc.translate('new_activity_section'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 16),


                  // 📅 PRZYCISK "DODAJ ZA ZAKRES CZASU"
                  if (_activeStartTime == null)
                    Container(
                      width: double.infinity,
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showManualFields = !_showManualFields;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.indigo, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit_calendar, size: 28, color: Colors.indigo),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                loc.translate('add_time_range_btn'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_activeStartTime != null)

                    Text(
                      '${loc.translate('running_since')}: '
                          '${_activeStartTime!.hour.toString().padLeft(2, '0')}:'
                          '${_activeStartTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  // 📅 POLA MANUALNE - pokazują się po kliknięciu "DODAJ ZA ZAKRES"
                  if (_showManualFields && _activeStartTime == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Data
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

                        // Godziny
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
                        const SizedBox(height: 16),

                        // Przycisk DODAJ
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _addManualSession();
                              setState(() {
                                _showManualFields = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              loc.translate('add_session_btn'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),




                  const Divider(height: 32),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Zapisz na telefonie (pełny backup)
                      IconButton(
                        tooltip: loc.translate('export'),
                        icon: const Icon(Icons.upload_file),
                        onPressed: () {
                          _exportAllData(); // eksport: historia + cele + wydarzenia
                        },
                      ),
                      // 2. Udostępnij backup (np. e‑mail, WhatsApp)
                      IconButton(
                        tooltip: 'Udostępnij backup',
                        icon: const Icon(Icons.share),
                        onPressed: () async {
                          final file = await _exportAllData(); // najpierw zapisz plik
                          if (file != null) {
                            await Share.shareXFiles(
                              [XFile(file.path)],
                              text: 'Backup WorkStudyTimer',
                            );
                          }
                        },
                      ),
                      // 3. Import z pliku backupu
                      IconButton(
                        tooltip: loc.translate('import'),
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          _importAllData(); // import: historia + cele + wydarzenia
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Filtry przeniesione tutaj
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(loc.translate('today')),
                        selected: _selectedRange == 'dzisiaj',
                        selectedColor: Colors.indigo,
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
                        selectedColor: Colors.indigo,
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
                        selectedColor: Colors.indigo,
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
                        selectedColor: Colors.indigo,
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
                        final dayName = _getDayNameHome(entry.start.weekday);
                        final dateLabel =
                            '$dayName ${entry.start.year}-${entry.start.month.toString().padLeft(2, '0')}-${entry.start.day.toString().padLeft(2, '0')}';

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