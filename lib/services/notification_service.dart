import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The user's notification choices, saved on the device.
class NotificationPrefs {
  /// Master switch (the user asked for notifications *and* allowed them).
  final bool enabled;
  final bool remindersEnabled;
  final int intervalHours;
  final int startMinutes; // minutes after midnight
  final int endMinutes;
  final bool goalNotifications;
  final bool achievementNotifications;

  const NotificationPrefs({
    this.enabled = false,
    this.remindersEnabled = false,
    this.intervalHours = 2,
    this.startMinutes = 8 * 60,
    this.endMinutes = 22 * 60,
    this.goalNotifications = true,
    this.achievementNotifications = true,
  });

  NotificationPrefs copyWith({
    bool? enabled,
    bool? remindersEnabled,
    int? intervalHours,
    int? startMinutes,
    int? endMinutes,
    bool? goalNotifications,
    bool? achievementNotifications,
  }) => NotificationPrefs(
    enabled: enabled ?? this.enabled,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    intervalHours: intervalHours ?? this.intervalHours,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    goalNotifications: goalNotifications ?? this.goalNotifications,
    achievementNotifications:
        achievementNotifications ?? this.achievementNotifications,
  );

  // Key names are unchanged from earlier versions so settings carry over.
  static const _enabled = 'notifications_enabled';
  static const _reminders = 'periodic_reminders';
  static const _interval = 'reminder_interval';
  static const _startHour = 'start_hour';
  static const _startMinute = 'start_minute';
  static const _endHour = 'end_hour';
  static const _endMinute = 'end_minute';
  static const _goal = 'goal_achieved_notif';
  static const _achievement = 'achievement_notif';

  static Future<NotificationPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    const d = NotificationPrefs();
    return NotificationPrefs(
      enabled: p.getBool(_enabled) ?? d.enabled,
      remindersEnabled: p.getBool(_reminders) ?? d.remindersEnabled,
      intervalHours: p.getInt(_interval) ?? d.intervalHours,
      startMinutes:
          (p.getInt(_startHour) ?? 8) * 60 + (p.getInt(_startMinute) ?? 0),
      endMinutes: (p.getInt(_endHour) ?? 22) * 60 + (p.getInt(_endMinute) ?? 0),
      goalNotifications: p.getBool(_goal) ?? d.goalNotifications,
      achievementNotifications:
          p.getBool(_achievement) ?? d.achievementNotifications,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enabled, enabled);
    await p.setBool(_reminders, remindersEnabled);
    await p.setInt(_interval, intervalHours);
    await p.setInt(_startHour, startMinutes ~/ 60);
    await p.setInt(_startMinute, startMinutes % 60);
    await p.setInt(_endHour, endMinutes ~/ 60);
    await p.setInt(_endMinute, endMinutes % 60);
    await p.setBool(_goal, goalNotifications);
    await p.setBool(_achievement, achievementNotifications);
  }
}

/// Works out at which times of day reminders should fire.
class ReminderPlanner {
  ReminderPlanner._();

  static const int maxPerDay = 24;

  /// Minutes after midnight from [startMinutes] to [endMinutes] (inclusive),
  /// every [intervalHours]. Empty if the window is empty or backwards.
  static List<int> slots({
    required int startMinutes,
    required int endMinutes,
    required int intervalHours,
  }) {
    if (intervalHours < 1 || endMinutes < startMinutes) return const [];
    final result = <int>[];
    for (
      var m = startMinutes;
      m <= endMinutes && result.length < maxPerDay;
      m += intervalHours * 60
    ) {
      result.add(m);
    }
    return result;
  }
}

/// What the rest of the app can ask the notification layer to do.
abstract class NotificationGateway {
  Future<void> goalReached();

  /// A one-off "you unlocked something" notification.
  Future<void> achievement({
    required String title,
    required String body,
    required String payload,
  });
}

/// What the notification settings screen needs.
abstract class NotificationScheduler {
  /// `false` on platforms without local notifications (web, desktop).
  bool get isSupported;

  Future<bool> requestPermissions();

  Future<bool> areNotificationsAllowed();

  /// Replaces the repeating reminders with the schedule in [prefs].
  Future<void> applyReminderSchedule(NotificationPrefs prefs);

  Future<void> cancelAll();

  Future<void> sendTest();
}

class NotificationService
    implements NotificationGateway, NotificationScheduler {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Notification ids 100-199 are reserved for the repeating reminders.
  static const int _reminderIdBase = 100;
  static const String _channelId = 'h2orbit_channel';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Local notifications are only implemented for phones.
  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Never throws: the app must still start where notifications don't work.
  Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    try {
      tz_data.initializeTimeZones();
      try {
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
      } catch (e) {
        debugPrint('Could not read the device time zone, using UTC: $e');
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is asked for from the settings screen, not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    await initialize();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('Could not request notification permission: $e');
    }
    return false;
  }

  @override
  Future<bool> areNotificationsAllowed() async {
    if (!isSupported) return false;
    await initialize();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return (await ios.checkPermissions())?.isEnabled ?? false;
      }
    } catch (e) {
      debugPrint('Could not check notification permission: $e');
    }
    return false;
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'H2Orbit Notifications',
      channelDescription: 'Hydration reminders and achievements',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF3E92CC),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isSupported) return;
    await initialize();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Could not show notification: $e');
    }
  }

  /// Replaces the repeating reminders with the schedule in [prefs].
  ///
  /// Each reminder repeats every day at its time, so the user keeps getting
  /// them without having to reopen the app.
  @override
  Future<void> applyReminderSchedule(NotificationPrefs prefs) async {
    if (!isSupported) return;
    await initialize();
    try {
      for (var i = 0; i < ReminderPlanner.maxPerDay; i++) {
        await _plugin.cancel(id: _reminderIdBase + i);
      }
      if (!prefs.enabled || !prefs.remindersEnabled) return;

      final slots = ReminderPlanner.slots(
        startMinutes: prefs.startMinutes,
        endMinutes: prefs.endMinutes,
        intervalHours: prefs.intervalHours,
      );
      for (var i = 0; i < slots.length; i++) {
        await _plugin.zonedSchedule(
          id: _reminderIdBase + i,
          title: 'Time to hydrate',
          body: "A glass of water now keeps you on track for today's goal.",
          scheduledDate: _nextOccurrence(slots[i]),
          notificationDetails: _details,
          // Inexact alarms need no special permission and are fine for
          // reminders that may arrive a few minutes late.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'reminder',
        );
      }
    } catch (e) {
      debugPrint('Could not schedule reminders: $e');
    }
  }

  tz.TZDateTime _nextOccurrence(int minutesOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutesOfDay ~/ 60,
      minutesOfDay % 60,
    );
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  @override
  Future<void> cancelAll() async {
    if (!isSupported) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Could not cancel notifications: $e');
    }
  }

  @override
  Future<void> sendTest() => showNow(
    id: 99999,
    title: 'Test notification',
    body: 'Notifications are working. Stay hydrated!',
  );

  // ---- NotificationGateway: respects the user's choices ----

  Future<NotificationPrefs> _prefs() => NotificationPrefs.load();

  @override
  Future<void> goalReached() async {
    final prefs = await _prefs();
    if (!prefs.enabled || !prefs.goalNotifications) return;
    await showNow(
      id: 9999,
      title: 'Goal achieved!',
      body: "Congratulations! You've reached your daily hydration goal.",
      payload: 'goal',
    );
  }

  @override
  Future<void> achievement({
    required String title,
    required String body,
    required String payload,
  }) async {
    final prefs = await _prefs();
    if (!prefs.enabled || !prefs.achievementNotifications) return;
    await showNow(
      // The same achievement always uses the same id, so it can't stack up.
      id: 1000 + (payload.hashCode & 0xFFFFF),
      title: title,
      body: body,
      payload: payload,
    );
  }
}
