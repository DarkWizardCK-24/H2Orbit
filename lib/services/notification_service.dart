import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {}

  Future<bool> requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'h2orbit_channel',
      'H2Orbit Notifications',
      channelDescription: 'Hydration reminders and achievements',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF3E92CC),
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'h2orbit_channel',
      'H2Orbit Notifications',
      channelDescription: 'Hydration reminders and achievements',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF3E92CC),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> schedulePeriodicReminders({
    required int intervalHours,
    required int startHour,
    required int endHour,
  }) async {
    await cancelAllNotifications();

    final now = DateTime.now();
    int notificationId = 0;

    for (int day = 0; day < 2; day++) {
      for (int hour = startHour; hour < endHour; hour += intervalHours) {
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day + day,
          hour,
          0,
        );

        if (scheduledTime.isAfter(now)) {
          await scheduleNotification(
            id: notificationId++,
            title: 'Time to Hydrate!',
            body: 'Don\'t forget to drink water. Your body needs it!',
            scheduledTime: scheduledTime,
          );
        }
      }
    }
  }

  Future<void> showAchievementNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> showGoalAchievedNotification() async {
    await showNotification(
      id: 9999,
      title: 'Goal Achieved!',
      body: 'Congratulations! You\'ve reached your daily hydration goal!',
    );
  }

  Future<void> showStreakAchievement(int days) async {
    String title = '';
    String body = '';

    if (days == 3) {
      title = '🔥 3-Day Streak!';
      body = 'You\'re on fire! Keep up the great hydration habit!';
    } else if (days == 7) {
      title = '🔥 Week Warrior!';
      body = 'Amazing! 7 days of consistent hydration!';
    } else if (days == 14) {
      title = '🔥 Two Week Champion!';
      body = 'Incredible! Two weeks of dedication!';
    } else if (days == 30) {
      title = '🏆 Monthly Master!';
      body = 'Outstanding! 30 days of perfect hydration!';
    } else if (days == 60) {
      title = '💎 Diamond Hydrator!';
      body = 'Legendary! 60 days of unwavering commitment!';
    } else if (days == 100) {
      title = '👑 Hydration King/Queen!';
      body = 'Elite status! 100 days of excellence!';
    } else {
      return;
    }

    await showAchievementNotification(
      title: title,
      body: body,
      payload: 'streak_$days',
    );
  }

  Future<void> showMilestoneAchievement(int totalGlasses) async {
    String title = '';
    String body = '';

    if (totalGlasses == 50) {
      title = '💧 First 50 Glasses!';
      body = 'You\'ve tracked 50 glasses of water!';
    } else if (totalGlasses == 100) {
      title = '💧 Century Club!';
      body = '100 glasses tracked! You\'re doing amazing!';
    } else if (totalGlasses == 250) {
      title = '🌊 Quarter Thousand!';
      body = '250 glasses! Your body thanks you!';
    } else if (totalGlasses == 500) {
      title = '🌊 Half a Thousand!';
      body = '500 glasses! Absolutely incredible!';
    } else if (totalGlasses == 1000) {
      title = '🏆 Legendary Status!';
      body = '1000 glasses! You\'re a hydration legend!';
    } else {
      return;
    }

    await showAchievementNotification(
      title: title,
      body: body,
      payload: 'milestone_$totalGlasses',
    );
  }

  // Custom scheduled notification
  Future<void> scheduleCustomReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: 'custom',
    );
  }

  // Morning reminder
  Future<void> scheduleMorningReminder(int hour) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day + (now.hour >= hour ? 1 : 0),
      hour,
      0,
    );

    await scheduleNotification(
      id: 1000,
      title: '🌅 Good Morning!',
      body: 'Start your day with a glass of water!',
      scheduledTime: scheduledTime,
    );
  }

  // Evening reminder
  Future<void> scheduleEveningReminder(int hour) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day + (now.hour >= hour ? 1 : 0),
      hour,
      0,
    );

    await scheduleNotification(
      id: 1001,
      title: '🌙 Evening Check-in',
      body: 'Have you reached your hydration goal today?',
      scheduledTime: scheduledTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      return enabled ?? false;
    }

    return true;
  }
}
