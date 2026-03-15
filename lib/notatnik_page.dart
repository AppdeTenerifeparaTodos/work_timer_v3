import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'notification_service.dart';
import 'alarm_service.dart';
import 'alarm_picker_widget.dart';

class VoiceNote {
  final String id;
  final String text;
  final DateTime createdAt;
  DateTime? reminderAt;
  String reminderMode;

  VoiceNote({
    required this.id,
    required this.text,
    required this.createdAt,
    this.reminderAt,
    this.reminderMode = 'alarm',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
    'reminderMode': reminderMode,
  };

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
    id: json['id'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    reminderAt: json['reminderAt'] != null
        ? DateTime.parse(json['reminderAt'] as String)
        : null,
    reminderMode: json['reminderMode'] as String? ?? 'alarm',
  );
}

class NotatnikPage extends StatefulWidget {
  const NotatnikPage({super.key});

  @override
  State<NotatnikPage> createState() => _NotatnikPageState();
}

class _NotatnikPageState extends State<NotatnikPage> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final AlarmService _alarm = AlarmService();

  bool _speechEnabled = false;
  bool _isListening = false;
  String _liveText = '';
  List<VoiceNote> _notes = [];

  String _selectedSoundId = '1';
  late AlarmSound _selectedSound;

  @override
  void initState() {
    super.initState();
    _selectedSound = kAlarmSounds.first;
    _initSpeech();
    _loadNotes();
    _loadSelectedSound();
  }

  Future<void> _loadSelectedSound() async {
    final id = await _alarm.loadSoundForNotes();
    final sound = _alarm.getSoundById(id);
    setState(() {
      _selectedSoundId = id;
      _selectedSound = sound;
    });
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' && _isListening) _restartListening();
      },
    );
    setState(() {});
  }

  void _restartListening() async {
    if (!_speechEnabled || !_isListening) return;
    final localeId = _getLocaleId(context);
    final previousText = _liveText;
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          final newWords = result.recognizedWords;
          _liveText = newWords.isNotEmpty
              ? '$previousText $newWords'.trim()
              : previousText;
        });
      },
      localeId: localeId,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 10),
      listenMode: stt.ListenMode.dictation,
    );
  }

  String _getLocaleId(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (lang) {
      case 'es': return 'es_ES';
      case 'en': return 'en_US';
      default:   return 'pl_PL';
    }
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    setState(() { _liveText = ''; _isListening = true; });
    final localeId = _getLocaleId(context);
    await _speechToText.listen(
      onResult: (result) => setState(() => _liveText = result.recognizedWords),
      localeId: localeId,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 10),
      listenMode: stt.ListenMode.dictation,
    );
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    await _speechToText.stop();
    if (_liveText.trim().isNotEmpty) {
      final note = VoiceNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _liveText.trim(),
        createdAt: DateTime.now(),
      );
      setState(() { _notes.insert(0, note); _liveText = ''; });
      await _saveNotes();
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'voice_notes', jsonEncode(_notes.map((n) => n.toJson()).toList()));
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('voice_notes');
    if (raw == null || raw.isEmpty) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      setState(() {
        _notes = decoded
            .map((e) => VoiceNote.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Błąd ładowania notatek: $e');
    }
  }

  void _deleteNote(String id) {
    // Prefiks note_ żeby cancelEventReminder wiedział że to notatka
    NotificationService().cancelEventReminder('note_$id');
    setState(() => _notes.removeWhere((n) => n.id == id));
    _saveNotes();
  }

  void _editNote(VoiceNote note) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController(text: note.text);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: Text(loc.translate('notes_edit_title'),
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.translate('notes_cancel'))),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(loc.translate('notes_save'))),
        ],
      ),
    );
    controller.dispose();
    if (saved != null && saved.isNotEmpty) {
      final idx = _notes.indexWhere((n) => n.id == note.id);
      if (idx != -1) {
        setState(() {
          _notes[idx] = VoiceNote(
            id: note.id,
            text: saved,
            createdAt: note.createdAt,
            reminderAt: note.reminderAt,
            reminderMode: note.reminderMode,
          );
        });
        await _saveNotes();
      }
    }
  }

  void _triggerAlarm(VoiceNote note) async {
    await _alarm.playLooping(_selectedSound.fileName);
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlarmStopScreen(
        title: '🔔 Przypomnienie',
        subtitle: note.text,
        onStop: () {
          _alarm.stop();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _setReminder(VoiceNote note) async {
    final loc = AppLocalizations.of(context);
    final now = DateTime.now();

    // 1. Wybór daty
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1), surface: Color(0xFF1A1A24)),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    // 2. Wybór godziny
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1), surface: Color(0xFF1A1A24)),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null || !mounted) return;

    // 3. Wybór trybu alarmu
    String reminderMode = 'alarm';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
        builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A24),
            title: Text(
              loc.translate('reminder_mode_title'),
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'notification',
                      icon: const Icon(Icons.notifications, size: 16),
                      label: Text(loc.translate('event_mode_notification'), style: const TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: 'vibration',
                      icon: const Icon(Icons.vibration, size: 16),
                      label: Text(loc.translate('event_mode_vibration'), style: const TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: 'alarm',
                      icon: const Icon(Icons.alarm, size: 16),
                      label: Text(loc.translate('event_mode_alarm'), style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {reminderMode},
                  onSelectionChanged: (val) =>
                      setStateDialog(() => reminderMode = val.first),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.translate('event_mode_desc_$reminderMode'),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.translate('cancel'),
                    style: const TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1)),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.translate('save')),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted) return;

    // 4. Zaplanuj przypomnienie
    final reminderDateTime = DateTime(
      pickedDate.year, pickedDate.month, pickedDate.day,
      pickedTime.hour, pickedTime.minute,
    );


    await NotificationService().scheduleEventReminder(
      eventId: 'note_${note.id}',
      title: '🔔 ${note.text}',
      eventDateTime: reminderDateTime,
      reminderMinutes: 0,
      reminderMode: reminderMode,
      channelName: loc.translate('notification_channel_reminders'),
      channelDescription: loc.translate('notification_channel_reminders_desc'),
      stopButton: loc.translate('alarm_stop'),
      notificationTitle: loc.translate('alarm_reminder_title'),
    );

    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      setState(() {
        _notes[idx] = VoiceNote(
          id: note.id,
          text: note.text,
          createdAt: note.createdAt,
          reminderAt: reminderDateTime,
          reminderMode: reminderMode,
        );
      });
      await _saveNotes();
    }

    if (mounted) {
      final modeIcon = reminderMode == 'alarm'
          ? '🚨'
          : reminderMode == 'vibration'
          ? '📳'
          : '🔔';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$modeIcon ${loc.translate('notes_reminder_set')} ${_formatDate(reminderDateTime)}'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _cancelReminder(VoiceNote note) async {
    final loc = AppLocalizations.of(context);
    // Prefiks note_ — ten sam co przy ustawianiu
    NotificationService().cancelEventReminder('note_${note.id}');
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      setState(() {
        _notes[idx] = VoiceNote(
          id: note.id,
          text: note.text,
          createdAt: note.createdAt,
          reminderAt: null,
          reminderMode: 'alarm',
        );
      });
      await _saveNotes();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.translate('notes_reminder_cancel')),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _openAlarmPicker() async {
    final result = await showAlarmPicker(
      context: context,
      currentSoundId: _selectedSoundId,
    );
    if (result != null) {
      await _alarm.saveSoundForNotes(result.id);
      setState(() {
        _selectedSoundId = result.id;
        _selectedSound = result;
      });
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _modeIcon(String mode) {
    switch (mode) {
      case 'vibration':   return '📳';
      case 'notification': return '🔔';
      default:            return '🚨';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text(loc.translate('notes_tab')),
        backgroundColor: const Color(0xFF0D0D14),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note, color: Color(0xFF6366F1)),
            tooltip: 'Dźwięk: ${_selectedSound.displayName}',
            onPressed: _openAlarmPicker,
          ),
          if (_notes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: loc.translate('notes_delete_all'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A24),
                    title: Text(loc.translate('notes_delete_all'),
                        style: const TextStyle(color: Colors.white)),
                    content: Text(loc.translate('notes_delete_confirm'),
                        style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(loc.translate('notes_cancel'))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(loc.translate('notes_delete_btn')),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  for (final n in _notes) {
                    NotificationService().cancelEventReminder('note_${n.id}');
                  }
                  setState(() => _notes.clear());
                  await _saveNotes();
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isListening
                    ? const Color(0xFF1A1A24)
                    : const Color(0xFF111118),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening
                      ? const Color(0xFF6366F1)
                      : Colors.white12,
                  width: _isListening ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (_isListening) ...[
                      const Icon(Icons.fiber_manual_record,
                          color: Colors.red, size: 14),
                      const SizedBox(width: 6),
                      Text(loc.translate('notes_recording'),
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ] else
                      Text(
                        _notes.isEmpty
                            ? loc.translate('notes_tap_to_record')
                            : loc.translate('notes_ready'),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                      ),
                  ]),
                  if (_liveText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_liveText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.4)),
                  ],
                ],
              ),
            ),

            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isListening
                      ? Colors.red.shade700
                      : const Color(0xFF6366F1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening
                          ? Colors.red
                          : const Color(0xFF6366F1))
                          .withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isListening
                  ? loc.translate('notes_tap_to_stop')
                  : loc.translate('notes_tap_to_start'),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _notes.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notes,
                        color: Colors.white12, size: 64),
                    const SizedBox(height: 12),
                    Text(loc.translate('notes_empty'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 14)),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _notes.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  final hasReminder = note.reminderAt != null;
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111118),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasReminder
                            ? const Color(0xFF6366F1).withOpacity(0.4)
                            : Colors.white10,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note.text,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.access_time,
                                size: 13, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(_formatDate(note.createdAt),
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12)),
                          ]),
                          if (hasReminder) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.notifications_active,
                                  size: 13,
                                  color: Color(0xFF6366F1)),
                              const SizedBox(width: 4),
                              Text(
                                '${_modeIcon(note.reminderMode)} ${_formatDate(note.reminderAt!)}',
                                style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ]),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (hasReminder) ...[
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.alarm,
                                      color: Colors.orange, size: 22),
                                  onPressed: () =>
                                      _triggerAlarm(note),
                                  tooltip: 'Testuj alarm',
                                ),
                                const SizedBox(width: 16),
                              ],
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  hasReminder
                                      ? Icons.notifications_active
                                      : Icons.notifications_none,
                                  color: hasReminder
                                      ? const Color(0xFF6366F1)
                                      : Colors.white38,
                                  size: 22,
                                ),
                                onPressed: () => hasReminder
                                    ? _cancelReminder(note)
                                    : _setReminder(note),
                                tooltip: hasReminder
                                    ? loc.translate(
                                    'notes_reminder_tooltip_cancel')
                                    : loc.translate(
                                    'notes_reminder_tooltip_set'),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.edit,
                                    color: Colors.white38, size: 22),
                                onPressed: () => _editNote(note),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 22),
                                onPressed: () =>
                                    _deleteNote(note.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}