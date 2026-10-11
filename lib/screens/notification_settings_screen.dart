import 'package:flutter/material.dart';
import 'package:h2orbit/services/notification_service.dart';
import 'package:h2orbit/utils/breakpoints.dart';
import 'package:h2orbit/utils/snackbar.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/glass_container.dart';
import 'package:h2orbit/widgets/ocean_scaffold.dart';
import 'package:h2orbit/widgets/side_rail.dart';
import 'package:provider/provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationPrefs _prefs = const NotificationPrefs();
  bool _loading = true;
  bool _osAllowed = false;

  NotificationScheduler get _scheduler => context.read<NotificationScheduler>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await NotificationPrefs.load();
    final allowed = await _scheduler.areNotificationsAllowed();
    if (!mounted) return;
    setState(() {
      // Switching notifications off in the phone's settings turns us off too.
      _prefs = prefs.copyWith(enabled: prefs.enabled && allowed);
      _osAllowed = allowed;
      _loading = false;
    });
  }

  /// Saves [next] and re-applies the reminder schedule.
  Future<void> _update(NotificationPrefs next) async {
    setState(() => _prefs = next);
    await next.save();
    await _scheduler.applyReminderSchedule(next);
  }

  Future<void> _toggleMaster(bool on) async {
    if (!on) {
      await _update(_prefs.copyWith(enabled: false));
      await _scheduler.cancelAll();
      return;
    }
    final granted = await _scheduler.requestPermissions();
    if (!mounted) return;
    if (!granted) {
      setState(() => _osAllowed = false);
      showAppSnack(
        context,
        _scheduler.isSupported
            ? 'Notifications are blocked. Allow them in your phone settings.'
            : 'Notifications are not available on this device.',
        isError: true,
      );
      return;
    }
    setState(() => _osAllowed = true);
    await _update(_prefs.copyWith(enabled: true));
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _prefs.startMinutes : _prefs.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    await _update(
      start
          ? _prefs.copyWith(startMinutes: minutes)
          : _prefs.copyWith(endMinutes: minutes),
    );
  }

  String _format(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

  @override
  Widget build(BuildContext context) {
    return OceanScaffold(
      title: 'Notifications',
      section: AppSection.notifications,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _wideAware(
              context,
              ListView(
                padding: EdgeInsets.fromLTRB(
                  Breakpoints.isWide(context) ? 28 : 20,
                  8,
                  20,
                  32,
                ),
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _prefs.enabled,
                          onChanged: _toggleMaster,
                          secondary: const Icon(
                            Icons.notifications_active_outlined,
                            color: AppTheme.lightCyan,
                          ),
                          title: const _Title('Enable notifications'),
                          subtitle: _Sub(
                            !_scheduler.isSupported
                                ? 'Not available on this device'
                                : _osAllowed
                                ? 'Allow H2Orbit to send you reminders'
                                : 'Allow notifications to get reminders',
                          ),
                        ),
                        if (_prefs.enabled) ...[
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.send_rounded,
                              color: AppTheme.lightCyan,
                            ),
                            title: const _Title('Send a test notification'),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white54,
                            ),
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await _scheduler.sendTest();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Test notification sent'),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_prefs.enabled) ...[
                    const SizedBox(height: 24),
                    const SectionTitle('Hydration reminders'),
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _prefs.remindersEnabled,
                            onChanged: (v) =>
                                _update(_prefs.copyWith(remindersEnabled: v)),
                            secondary: const Icon(
                              Icons.alarm_rounded,
                              color: AppTheme.lightCyan,
                            ),
                            title: const _Title('Daily reminders'),
                            subtitle: const _Sub('A nudge to drink, every day'),
                          ),
                          if (_prefs.remindersEnabled) ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _Title('Remind me every'),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      for (final hours in [1, 2, 3, 4])
                                        ChoiceChip(
                                          label: Text('$hours h'),
                                          selected:
                                              _prefs.intervalHours == hours,
                                          showCheckmark: false,
                                          selectedColor: AppTheme.lightCyan,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.08),
                                          side: BorderSide.none,
                                          labelStyle: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _prefs.intervalHours == hours
                                                ? AppTheme.darkBackground
                                                : Colors.white,
                                          ),
                                          onSelected: (_) => _update(
                                            _prefs.copyWith(
                                              intervalHours: hours,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _TimeButton(
                                          label: 'From',
                                          value: _format(_prefs.startMinutes),
                                          onTap: () => _pickTime(start: true),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _TimeButton(
                                          label: 'Until',
                                          value: _format(_prefs.endMinutes),
                                          onTap: () => _pickTime(start: false),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _ScheduleSummary(
                                    prefs: _prefs,
                                    format: _format,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Celebrations'),
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _prefs.goalNotifications,
                            onChanged: (v) =>
                                _update(_prefs.copyWith(goalNotifications: v)),
                            secondary: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.amber,
                            ),
                            title: const _Title('Daily goal reached'),
                            subtitle: const _Sub('When you hit your target'),
                          ),
                          const Divider(),
                          SwitchListTile(
                            value: _prefs.achievementNotifications,
                            onChanged: (v) => _update(
                              _prefs.copyWith(achievementNotifications: v),
                            ),
                            secondary: const Icon(
                              Icons.military_tech_rounded,
                              color: Colors.amber,
                            ),
                            title: const _Title('Milestones'),
                            subtitle: const _Sub('Streaks and total glasses'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  /// On wide windows the settings stay a readable column next to the rail.
  Widget _wideAware(BuildContext context, Widget list) {
    if (!Breakpoints.isWide(context)) return list;
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: list,
      ),
    );
  }
}

class _ScheduleSummary extends StatelessWidget {
  final NotificationPrefs prefs;
  final String Function(int) format;

  const _ScheduleSummary({required this.prefs, required this.format});

  @override
  Widget build(BuildContext context) {
    final slots = ReminderPlanner.slots(
      startMinutes: prefs.startMinutes,
      endMinutes: prefs.endMinutes,
      intervalHours: prefs.intervalHours,
    );
    final invalid = slots.isEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (invalid ? AppTheme.danger : AppTheme.lightCyan).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            invalid ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 18,
            color: invalid ? AppTheme.danger : AppTheme.lightCyan,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              invalid
                  ? '"Until" must be later than "From".'
                  : '${slots.length} ${slots.length == 1 ? 'reminder' : 'reminders'} a day, '
                        'from ${format(slots.first)} to ${format(slots.last)}.',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: AppTheme.lightCyan,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    ),
  );
}

class _Sub extends StatelessWidget {
  final String text;

  const _Sub(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.65),
      fontSize: 12.5,
    ),
  );
}
