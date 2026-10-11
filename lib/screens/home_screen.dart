import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:h2orbit/controllers/home_controller.dart';
import 'package:h2orbit/models/beverage_model.dart';
import 'package:h2orbit/models/water_intake_model.dart';
import 'package:h2orbit/services/achievement_manager.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/services/firebase_service.dart';
import 'package:h2orbit/services/notification_service.dart';
import 'package:h2orbit/services/weather_service.dart';
import 'package:h2orbit/utils/breakpoints.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:h2orbit/utils/snackbar.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/beverage_card.dart';
import 'package:h2orbit/widgets/custom_drink_sheet.dart';
import 'package:h2orbit/widgets/glass_container.dart';
import 'package:h2orbit/widgets/glass_drawer.dart';
import 'package:h2orbit/widgets/insight_card.dart';
import 'package:h2orbit/widgets/intake_log_tile.dart';
import 'package:h2orbit/widgets/ocean_scaffold.dart';
import 'package:h2orbit/widgets/side_rail.dart';
import 'package:h2orbit/widgets/water_wave_animation.dart';
import 'package:h2orbit/widgets/weather_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  /// Replaces `DateTime.now` (used by tests and screenshots).
  final DateTime Function()? clock;

  const HomeScreen({super.key, this.clock});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().userId!;

    return ChangeNotifierProvider(
      create: (context) => HomeController(
        userId: userId,
        repository: context.read<HydrationRepository>(),
        achievements: AchievementManager(
          userId: userId,
          notifications: context.read<NotificationGateway>(),
        ),
        weather: context.read<WeatherProvider?>(),
        clock: clock,
      )..start(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeController>().onResume();
    }
  }

  Future<void> _addDrink(int ml, String type) async {
    final home = context.read<HomeController>();
    final label = BeverageModel.labelFor(type).toLowerCase();
    try {
      final saved = await home.addDrink(ml, type);
      if (!mounted) return;
      showAppSnack(
        context,
        'Added $ml ml of $label',
        actionLabel: 'UNDO',
        onAction: () => home.removeDrink(saved),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        "Couldn't save that drink. Check your connection and try again.",
        isError: true,
      );
    }
  }

  Future<void> _removeDrink(WaterIntakeModel intake) async {
    final home = context.read<HomeController>();
    try {
      await home.removeDrink(intake);
      if (!mounted) return;
      showAppSnack(
        context,
        'Removed ${intake.milliliters} ml',
        actionLabel: 'UNDO',
        onAction: () => home.restoreDrink(intake),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, "Couldn't remove that entry.", isError: true);
    }
  }

  Future<void> _addCustom() async {
    final drink = await showCustomDrinkSheet(context);
    if (drink != null) await _addDrink(drink.ml, drink.type);
  }

  void _openDrawer() {
    final home = context.read<HomeController>();
    final auth = context.read<AuthService>();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: GlassDrawer(
          currentStreak: home.streak,
          userName: home.user?.name ?? '',
          email: auth.email ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();

    if (home.loading) {
      return const OceanScaffold(
        showBack: false,
        section: AppSection.home,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tips = home.tips.take(2).toList();
    final log = home.log;
    final wide = Breakpoints.isWide(context);

    final quickAdd = GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 124,
      ),
      children: [
        for (final drink in BeverageModel.quickAdd)
          BeverageCard(
            name: drink.name,
            icon: drink.icon,
            ml: drink.milliliters,
            onTap: () => _addDrink(drink.milliliters, drink.type),
          ),
      ],
    );
    final tipCards = [
      for (final tip in tips) ...[
        InsightCard.fromTip(tip),
        const SizedBox(height: 12),
      ],
    ];
    final logTitle = SectionTitle(
      "Today's log",
      trailing: log.isEmpty
          ? null
          : Text(
              '${log.length} ${log.length == 1 ? 'drink' : 'drinks'}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
    );
    final logTiles = [
      if (log.isEmpty)
        const _EmptyLog()
      else
        for (final intake in log) ...[
          IntakeLogTile(intake: intake, onDelete: () => _removeDrink(intake)),
          const SizedBox(height: 10),
        ],
    ];

    return OceanScaffold(
      showBack: false,
      section: AppSection.home,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustom,
        backgroundColor: AppTheme.deepCyan,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: StadiumBorder(
          side: BorderSide(
            color: AppTheme.lightCyan.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: AppTheme.lightCyan),
        label: const Text(
          'Custom',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: wide
          ? Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
              child: Column(
                children: [
                  const _Header(),
                  if (home.loadError != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: home.loadError!),
                  ],
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 400,
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 110),
                            children: [
                              const _HeroCard(),
                              if (home.weather != null) ...[
                                const SizedBox(height: 20),
                                WeatherCard(weather: home.weather!),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: home.refresh,
                            color: AppTheme.lightCyan,
                            backgroundColor: AppTheme.deepCyan,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 110),
                              children: [
                                const SectionTitle('Quick add'),
                                quickAdd,
                                const SizedBox(height: 28),
                                const SectionTitle('Smart tips'),
                                ...tipCards,
                                const SizedBox(height: 16),
                                logTitle,
                                ...logTiles,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: home.refresh,
              color: AppTheme.lightCyan,
              backgroundColor: AppTheme.deepCyan,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: [
                  _Header(onMenu: _openDrawer),
                  if (home.loadError != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: home.loadError!),
                  ],
                  const SizedBox(height: 20),
                  const _HeroCard(),
                  const SizedBox(height: 28),
                  const SectionTitle('Quick add'),
                  quickAdd,
                  if (home.weather != null) ...[
                    const SizedBox(height: 24),
                    WeatherCard(weather: home.weather!),
                  ],
                  const SizedBox(height: 28),
                  const SectionTitle('Smart tips'),
                  ...tipCards,
                  const SizedBox(height: 16),
                  logTitle,
                  ...logTiles,
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  /// Null on wide windows, where the side rail replaces the menu.
  final VoidCallback? onMenu;

  const _Header({this.onMenu});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${Fmt.greeting(home.now)},',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                ),
              ),
              Text(
                home.user?.firstName ?? 'there',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        if (home.streak > 0)
          Semantics(
            label: '${home.streak} day streak',
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.streak.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.streak.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppTheme.streak,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${home.streak}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (onMenu != null)
          Material(
            color: Colors.white.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: onMenu,
            ),
          ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => WaterOrb(
              progress: home.progress,
              size: math.min(constraints.maxWidth, 230),
              caption: home.goalReached ? 'goal reached' : 'of daily goal',
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _Stat(label: 'Drunk', value: Fmt.ml(home.totalMl)),
              _Divider(),
              _Stat(label: 'Goal', value: Fmt.ml(home.goalMl)),
              _Divider(),
              home.goalReached
                  ? const _Stat(
                      label: 'Status',
                      value: 'Done!',
                      color: AppTheme.success,
                    )
                  : _Stat(label: 'To go', value: Fmt.ml(home.remainingMl)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            home.goalReached
                ? (home.totalMl > home.goalMl
                      ? '${Fmt.ml(home.totalMl - home.goalMl)} over your goal'
                      : 'Right on your goal')
                : '${Fmt.glasses(home.totalMl)} of ${Fmt.glasses(home.goalMl)} glasses',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          if (home.weatherBonusMl > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wb_sunny_rounded,
                    color: AppTheme.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Goal includes +${Fmt.ml(home.weatherBonusMl)} for the heat',
                    style: const TextStyle(
                      color: AppTheme.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 30,
    color: Colors.white.withValues(alpha: 0.18),
  );
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 36,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nothing logged yet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a drink above to log your first sip.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
