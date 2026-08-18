import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  Future<void> scheduleNoteReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      await initNotification();
      await requestPermissions();

      if (scheduledDate.isBefore(DateTime.now())) return;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'echo_notes_reminders',
        'Note Reminders',
        channelDescription: 'Notifications for Echo Notes reminders',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );

      final tzScheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title.isEmpty ? 'Note Reminder' : title,
        body: body.isEmpty ? 'You have a scheduled note reminder.' : body,
        scheduledDate: tzScheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await initNotification();
      await flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
}
