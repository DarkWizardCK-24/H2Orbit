import 'package:flutter/material.dart';
import 'package:h2orbit/screens/analytics_screen.dart';
import 'package:h2orbit/screens/notification_settings_screen.dart';
import 'package:h2orbit/screens/profile_screen.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/app_logo.dart';
import 'package:h2orbit/widgets/ocean_scaffold.dart';
import 'package:provider/provider.dart';

/// The top-level destinations of the app.
enum AppSection { home, analytics, notifications, profile }

/// Persistent navigation shown on wide windows instead of the slide-in menu.
class SideRail extends StatelessWidget {
  final AppSection selected;

  const SideRail({super.key, required this.selected});

  static const _items = [
    (AppSection.home, Icons.water_drop_rounded, 'Home'),
    (AppSection.analytics, Icons.bar_chart_rounded, 'Analytics'),
    (
      AppSection.notifications,
      Icons.notifications_none_rounded,
      'Notifications',
    ),
    (AppSection.profile, Icons.person_outline_rounded, 'Profile'),
  ];

  Widget _screenFor(AppSection s) => switch (s) {
    AppSection.analytics => const AnalyticsScreen(),
    AppSection.notifications => const NotificationSettingsScreen(),
    AppSection.profile => const ProfileScreen(),
    AppSection.home => const SizedBox.shrink(),
  };

  void _go(BuildContext context, AppSection target) {
    if (target == selected) return;
    final navigator = Navigator.of(context);
    if (target == AppSection.home) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    final route = PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => _screenFor(target),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
    if (selected == AppSection.home) {
      navigator.push(route);
    } else {
      navigator.pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<AuthService>().email ?? '';

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.55),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 16, 28),
              child: Row(
                children: [
                  AppLogo(size: 38),
                  SizedBox(width: 12),
                  Expanded(child: BrandTitle(fontSize: 24)),
                ],
              ),
            ),
            for (final (section, icon, label) in _items)
              _RailItem(
                icon: icon,
                label: label,
                selected: section == selected,
                onTap: () => _go(context, section),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                email.isEmpty ? 'Stay hydrated, stay healthy' : email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected
              ? AppTheme.lightCyan.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected ? AppTheme.lightCyan : Colors.white70,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
