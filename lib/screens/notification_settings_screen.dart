import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:h2orbit/services/notification_service.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/glass_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = false;
  bool _periodicReminders = false;
  int _reminderInterval = 2; // hours
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  bool _goalAchievedNotif = true;
  bool _achievementNotif = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = await _notificationService.areNotificationsEnabled();

    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _periodicReminders = prefs.getBool('periodic_reminders') ?? false;
        _reminderInterval = prefs.getInt('reminder_interval') ?? 2;
        _startTime = TimeOfDay(
          hour: prefs.getInt('start_hour') ?? 8,
          minute: 0,
        );
        _endTime = TimeOfDay(hour: prefs.getInt('end_hour') ?? 22, minute: 0);
        _goalAchievedNotif = prefs.getBool('goal_achieved_notif') ?? true;
        _achievementNotif = prefs.getBool('achievement_notif') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('periodic_reminders', _periodicReminders);
    await prefs.setInt('reminder_interval', _reminderInterval);
    await prefs.setInt('start_hour', _startTime.hour);
    await prefs.setInt('end_hour', _endTime.hour);
    await prefs.setBool('goal_achieved_notif', _goalAchievedNotif);
    await prefs.setBool('achievement_notif', _achievementNotif);

    if (_periodicReminders) {
      await _notificationService.schedulePeriodicReminders(
        intervalHours: _reminderInterval,
        startHour: _startTime.hour,
        endHour: _endTime.hour,
      );
    } else {
      await _notificationService.cancelAllNotifications();
    }
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationService.requestPermissions();
    if (granted) {
      await _notificationService.initialize();
      final enabled = await _notificationService.areNotificationsEnabled();
      if (mounted) {
        setState(() => _notificationsEnabled = enabled);
      }
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showNotification(
      id: 99999,
      title: '💧 Test Notification',
      body: 'Notifications are working perfectly!',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.oceanGradient),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.lightCyan),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.oceanGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enable Notifications
                      GlassContainer(
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _notificationsEnabled,
                              onChanged: (value) async {
                                if (value) {
                                  await _requestPermission();
                                } else {
                                  setState(() => _notificationsEnabled = false);
                                }
                              },
                              title: const Text(
                                'Enable Notifications',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                'Allow H₂Orbit to send you reminders',
                                style: TextStyle(color: Colors.white70),
                              ),
                              activeColor: AppTheme.lightCyan,
                            ),
                            if (_notificationsEnabled) ...[
                              const Divider(color: Colors.white24),
                              ListTile(
                                leading: const FaIcon(
                                  FontAwesomeIcons.vial,
                                  color: AppTheme.lightCyan,
                                ),
                                title: const Text(
                                  'Test Notification',
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailing: const Icon(
                                  Icons.send,
                                  color: Colors.white70,
                                ),
                                onTap: _testNotification,
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (_notificationsEnabled) ...[
                        const SizedBox(height: 24),

                        // Periodic Reminders
                        const Text(
                          'Hydration Reminders',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassContainer(
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: _periodicReminders,
                                onChanged: (value) {
                                  setState(() => _periodicReminders = value);
                                  _saveSettings();
                                },
                                title: const Text(
                                  'Periodic Reminders',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Get regular hydration reminders',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                activeColor: AppTheme.lightCyan,
                              ),
                              if (_periodicReminders) ...[
                                const Divider(color: Colors.white24),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Reminder Interval',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [1, 2, 3, 4].map((hours) {
                                          return ChoiceChip(
                                            label: Text(
                                              '$hours hr${hours > 1 ? 's' : ''}',
                                            ),
                                            selected:
                                                _reminderInterval == hours,
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(
                                                  () =>
                                                      _reminderInterval = hours,
                                                );
                                                _saveSettings();
                                              }
                                            },
                                            selectedColor: AppTheme.lightCyan,
                                            labelStyle: TextStyle(
                                              color: _reminderInterval == hours
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Start Time',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                InkWell(
                                                  onTap: () async {
                                                    final time =
                                                        await showTimePicker(
                                                          context: context,
                                                          initialTime:
                                                              _startTime,
                                                        );
                                                    if (time != null) {
                                                      setState(
                                                        () => _startTime = time,
                                                      );
                                                      _saveSettings();
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const FaIcon(
                                                          FontAwesomeIcons
                                                              .clock,
                                                          color: AppTheme
                                                              .lightCyan,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          _startTime.format(
                                                            context,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'End Time',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                InkWell(
                                                  onTap: () async {
                                                    final time =
                                                        await showTimePicker(
                                                          context: context,
                                                          initialTime: _endTime,
                                                        );
                                                    if (time != null) {
                                                      setState(
                                                        () => _endTime = time,
                                                      );
                                                      _saveSettings();
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const FaIcon(
                                                          FontAwesomeIcons
                                                              .clock,
                                                          color: AppTheme
                                                              .lightCyan,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          _endTime.format(
                                                            context,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Achievement Notifications
                        const Text(
                          'Achievement Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassContainer(
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: _goalAchievedNotif,
                                onChanged: (value) {
                                  setState(() => _goalAchievedNotif = value);
                                  _saveSettings();
                                },
                                title: const Text(
                                  'Daily Goal Achieved',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Get notified when you reach your daily target',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                secondary: const FaIcon(
                                  FontAwesomeIcons.trophy,
                                  color: Colors.amber,
                                ),
                                activeColor: AppTheme.lightCyan,
                              ),
                              const Divider(color: Colors.white24),
                              SwitchListTile(
                                value: _achievementNotif,
                                onChanged: (value) {
                                  setState(() => _achievementNotif = value);
                                  _saveSettings();
                                },
                                title: const Text(
                                  'Milestone Achievements',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Celebrate streaks and special achievements',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                secondary: const FaIcon(
                                  FontAwesomeIcons.medal,
                                  color: Colors.amber,
                                ),
                                activeColor: AppTheme.lightCyan,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Info Card
                        GlassContainer(
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.circleInfo,
                                color: AppTheme.lightCyan,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Notifications help you stay on track with your hydration goals throughout the day.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
