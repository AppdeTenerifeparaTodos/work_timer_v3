import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dostępne alarmy — pliki w android/app/src/main/res/raw/
class AlarmSound {
  final String id;
  final String fileName; // bez rozszerzenia
  final String displayName;

  const AlarmSound({required this.id, required this.fileName, required this.displayName});
}

const List<AlarmSound> kAlarmSounds = [
  AlarmSound(id: '1', fileName: 'alarm_1', displayName: '🔔 Alarm 1'),
  AlarmSound(id: '2', fileName: 'alarm_2', displayName: '🔔 Alarm 2'),
  AlarmSound(id: '3', fileName: 'alarm_3', displayName: '🔔 Alarm 3'),
  AlarmSound(id: '4', fileName: 'alarm_4', displayName: '🔔 Alarm 4'),
  AlarmSound(id: '5', fileName: 'alarm_5', displayName: '🔔 Alarm 5'),
  AlarmSound(id: '6', fileName: 'alarm_6', displayName: '🔔 Alarm 6'),
  AlarmSound(id: '7', fileName: 'alarm_7', displayName: '🔔 Alarm 7'),
  AlarmSound(id: '8', fileName: 'alarm_8', displayName: '🔔 Alarm 8'),
];

const String _prefKeyNotes   = 'alarm_sound_notes';    // klucz dla notatnika
const String _prefKeyEvents  = 'alarm_sound_events';   // klucz dla wydarzeń

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  // ── Odtwarzanie w pętli ──────────────────────────────────────────────────

  Future<void> playLooping(String fileName) async {
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/$fileName.mp3'));
    _isPlaying = true;
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  // ── Podgląd (gra raz) ────────────────────────────────────────────────────

  Future<void> preview(String fileName) async {
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.release);
    await _player.play(AssetSource('sounds/$fileName.mp3'));
  }

  // ── Zapis/odczyt wybranego dźwięku ───────────────────────────────────────

  Future<void> saveSoundForNotes(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyNotes, soundId);
  }

  Future<String> loadSoundForNotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyNotes) ?? '1';
  }

  Future<void> saveSoundForEvents(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyEvents, soundId);
  }

  Future<String> loadSoundForEvents() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyEvents) ?? '1';
  }

  AlarmSound getSoundById(String id) {
    return kAlarmSounds.firstWhere(
          (s) => s.id == id,
      orElse: () => kAlarmSounds.first,
    );
  }
}