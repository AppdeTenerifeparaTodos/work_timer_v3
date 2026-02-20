import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime eventDateTime,
    required int reminderMinutes,
  }) async {
    final reminderTime =
    eventDateTime.subtract(Duration(minutes: reminderMinutes));

    if (reminderTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Przypomnienia',
      channelDescription: 'Powiadomienia o wydarzeniach',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _plugin.zonedSchedule(
      eventId.hashCode,
      'Przypomnienie',
      title,
      tzTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelEventReminder(String eventId) async {
    await _plugin.cancel(eventId.hashCode);
  }
}