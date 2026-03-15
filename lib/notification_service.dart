import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await Alarm.init();
  }

  static void _onNotificationTapped(NotificationResponse response) async {
    // Tryb 'notification' = tylko krótki dźwięk systemowy
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime eventDateTime,
    required int reminderMinutes,
    String reminderMode = 'alarm',
    String? channelName,
    String? channelDescription,
    String? stopButton,
    String? notificationTitle,
  }) async {
    final reminderTime =
    eventDateTime.subtract(Duration(minutes: reminderMinutes));

    if (reminderTime.isBefore(DateTime.now())) return;

    final alarmId = eventId.hashCode.abs() % 100000;
    final alarmTime = tz.TZDateTime.from(reminderTime, tz.local);
    final dateLabel =
        '${eventDateTime.day}.${eventDateTime.month}.${eventDateTime.year} '
        '${eventDateTime.hour.toString().padLeft(2, '0')}:${eventDateTime.minute.toString().padLeft(2, '0')}';

    if (reminderMode == 'alarm') {
      final prefs = await SharedPreferences.getInstance();
      final soundKey = eventId.startsWith('note_')
          ? 'alarm_sound_notes'
          : 'alarm_sound_events';
      final soundId = prefs.getString(soundKey) ?? '1';
      final soundAsset = 'assets/sounds/alarm_$soundId.mp3';

      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: alarmId,
          dateTime: alarmTime,
          assetAudioPath: soundAsset,
          loopAudio: true,
          vibrate: true,
          volume: 1.0,
          fadeDuration: 3.0,
          warningNotificationOnKill: true,
          androidFullScreenIntent: true,
          notificationSettings: NotificationSettings(
            title: '🚨 $title',
            body: dateLabel,
            stopButton: stopButton ?? 'STOP',
          ),
        ),
      );
    } else if (reminderMode == 'vibration') {
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: alarmId,
          dateTime: alarmTime,
          assetAudioPath: 'assets/sounds/alarm_1.mp3',
          loopAudio: false,
          vibrate: true,
          volume: 0.0,
          fadeDuration: 0.0,
          warningNotificationOnKill: false,
          androidFullScreenIntent: false,
          notificationSettings: NotificationSettings(
            title: '📳 $title',
            body: dateLabel,
            stopButton: stopButton ?? 'STOP',
          ),
        ),
      );
    } else {
      final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

      final androidDetails = AndroidNotificationDetails(
        'event_reminders',
        channelName ?? 'Reminders',
        channelDescription: channelDescription ?? 'Event notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: false,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      await _plugin.zonedSchedule(
        eventId.hashCode,
        notificationTitle ?? '🔔 Reminder',
        title,
        tzTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelEventReminder(String eventId) async {
    await _plugin.cancel(eventId.hashCode);
    final alarmId = eventId.hashCode.abs() % 100000;
    await Alarm.stop(alarmId);
  }
}