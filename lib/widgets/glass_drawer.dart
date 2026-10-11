import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:h2orbit/screens/analytics_screen.dart';
import 'package:h2orbit/screens/notification_settings_screen.dart';
import 'package:h2orbit/screens/profile_screen.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/app_logo.dart';
import 'package:h2orbit/widgets/ocean_scaffold.dart';

/// Slide-in menu from the right edge of the home screen.
class GlassDrawer extends StatelessWidget {
  final int currentStreak;
  final String userName;
  final String email;

  const GlassDrawer({
    super.key,
    required this.currentStreak,
    this.userName = '',
    this.email = '',
  });

  void _open(BuildContext context, Widget screen) {
    final navigator = Navigator.of(context);
    navigator.pop(); // close the drawer
    navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final initial = userName.trim().isEmpty
        ? '?'
        : userName.trim()[0].toUpperCase();
    const radius = BorderRadius.only(
      topLeft: Radius.circular(30),
      bottomLeft: Radius.circular(30),
    );

    return Align(
      alignment: Alignment.topRight,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: (MediaQuery.of(context).size.width * 0.78).clamp(260.0, 340.0),
          height: MediaQuery.of(context).size.height,
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.deepCyan.withValues(alpha: 0.92),
                      AppTheme.darkBackground.withValues(alpha: 0.96),
                    ],
                  ),
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
                        child: Row(
                          children: [
                            const AppLogo(size: 40),
                            const SizedBox(width: 12),
                            const Expanded(child: BrandTitle(fontSize: 26)),
                            IconButton(
                              tooltip: 'Close menu',
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.lightCyan.withValues(
                                alpha: 0.25,
                              ),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName.isEmpty ? 'Welcome' : userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (email.isNotEmpty)
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currentStreak > 0)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.streak.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.streak.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppTheme.streak,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$currentStreak day streak',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Goal reached every day',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      _DrawerItem(
                        icon: Icons.bar_chart_rounded,
                        title: 'Analytics',
                        onTap: () => _open(context, const AnalyticsScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        onTap: () =>
                            _open(context, const NotificationSettingsScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile',
                        onTap: () => _open(context, const ProfileScreen()),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Stay hydrated, stay healthy',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.lightCyan, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
