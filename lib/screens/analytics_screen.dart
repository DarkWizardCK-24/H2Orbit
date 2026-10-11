import 'package:flutter/material.dart';
import 'package:h2orbit/domain/achievements.dart';
import 'package:h2orbit/domain/trend_insights.dart';
import 'package:h2orbit/models/analytics_model.dart';
import 'package:h2orbit/models/beverage_model.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/services/firebase_service.dart';
import 'package:h2orbit/utils/breakpoints.dart';
import 'package:h2orbit/utils/constants.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/glass_container.dart';
import 'package:h2orbit/widgets/goal_bar_chart.dart';
import 'package:h2orbit/widgets/insight_card.dart';
import 'package:h2orbit/widgets/ocean_scaffold.dart';
import 'package:h2orbit/widgets/progress_ring.dart';
import 'package:h2orbit/widgets/side_rail.dart';
import 'package:h2orbit/widgets/stat_tile.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  /// Replaces `DateTime.now` (used by tests and screenshots).
  final DateTime Function()? clock;

  const AnalyticsScreen({super.key, this.clock});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  AnalyticsSummary? _summary;
  Set<String> _unlocked = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = context.read<HydrationRepository>();
    final userId = context.read<AuthService>().userId!;
    try {
      final now = (widget.clock ?? DateTime.now)();
      final today = Dates.startOfDay(now);
      final user = await repo.getUser(userId);
      final intakes = await repo.getIntakeBetween(
        userId,
        Dates.addDays(today, -AppConstants.historyDays),
        Dates.nextMidnight(now),
      );
      final totals = await repo.getTotals(userId);
      final goalMl =
          (user?.dailyGlassTarget ?? AppConstants.defaultWaterTarget) *
          AppConstants.mlPerGlass;
      final summary = AnalyticsSummary.from(intakes, goalMl: goalMl, now: now);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _unlocked = AchievementCatalog.unlocked(
          summary,
          allTimeMl: totals.milliliters,
        );
        _loading = false;
      });
    } catch (e) {
      debugPrint('Could not load analytics: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "We couldn't load your analytics. Check your connection.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OceanScaffold(
      title: 'Analytics',
      section: AppSection.analytics,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loading ? null : _load,
        ),
      ],
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Breakpoints.isWide(context) ? 460 : double.infinity,
              ),
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  Breakpoints.isWide(context) ? 28 : 20,
                  4,
                  20,
                  12,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabs,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.lightCyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: AppTheme.darkBackground,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Week'),
                    Tab(text: 'Trends'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final summary = _summary;
    if (_error != null || summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white70,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    return TabBarView(
      controller: _tabs,
      children: [
        _OverviewTab(summary: summary, unlocked: _unlocked),
        _WeekTab(summary: summary),
        _TrendsTab(summary: summary),
      ],
    );
  }
}

const _tabPadding = EdgeInsets.fromLTRB(20, 4, 20, 32);
const _wideTabPadding = EdgeInsets.fromLTRB(28, 4, 28, 32);

/// Two scrolling-free columns used by the tabs on wide windows.
Widget _twoColumns(List<Widget> left, List<Widget> right, {int leftFlex = 1}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: leftFlex,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: left,
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: right,
        ),
      ),
    ],
  );
}

class _OverviewTab extends StatelessWidget {
  final AnalyticsSummary summary;
  final Set<String> unlocked;

  const _OverviewTab({required this.summary, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final elapsedDays = s.week.where((d) => !d.isFuture).length;

    final items = <Widget>[
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: [
          StatTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Current streak',
            value: '${s.currentStreak}',
            unit: s.currentStreak == 1 ? 'day' : 'days',
            color: AppTheme.streak,
          ),
          StatTile(
            icon: Icons.emoji_events_rounded,
            label: 'Longest streak',
            value: '${s.longestStreak}',
            unit: s.longestStreak == 1 ? 'day' : 'days',
            color: Colors.amber,
          ),
          StatTile(
            icon: Icons.calendar_month_rounded,
            label: 'This month',
            value: Fmt.liters(s.monthTotalMl).replaceAll(' L', ''),
            unit: 'litres',
            color: AppTheme.lightCyan,
          ),
          StatTile(
            icon: Icons.show_chart_rounded,
            label: 'Daily average',
            value: Fmt.glasses(s.dailyAverageMl),
            unit: 'glasses',
            color: AppTheme.success,
          ),
        ],
      ),
      const SizedBox(height: 20),
      GlassContainer(
        child: Row(
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: ProgressRing(
                progress: elapsedDays == 0
                    ? 0
                    : s.goalDaysThisWeek / elapsedDays,
                strokeWidth: 8,
                showLabel: false,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Goal days this week',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.goalDaysThisWeek} of $elapsedDays '
                    '${elapsedDays == 1 ? 'day' : 'days'} reached',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    '${Fmt.liters(s.weekTotalMl)} in total',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      SectionTitle(
        'Achievements',
        trailing: Text(
          '${unlocked.length} / ${AchievementCatalog.all.length}',
          style: const TextStyle(
            color: AppTheme.lightCyan,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          for (final def in AchievementCatalog.all)
            _Badge(def: def, unlocked: unlocked.contains(def.id)),
        ],
      ),
    ];
    if (Breakpoints.isWide(context)) {
      return ListView(
        padding: _wideTabPadding,
        children: [
          _twoColumns(items.sublist(0, 3), items.sublist(4), leftFlex: 1),
        ],
      );
    }
    return ListView(padding: _tabPadding, children: items);
  }
}

class _Badge extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;

  const _Badge({required this.def, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? Colors.amber : Colors.white38;
    return Semantics(
      label:
          '${def.title}, ${unlocked ? 'unlocked' : 'locked'}. ${def.description}',
      excludeSemantics: true,
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: unlocked ? 0.22 : 0.12),
                  ),
                  child: Icon(def.icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(
                  unlocked
                      ? Icons.check_circle_rounded
                      : Icons.lock_outline_rounded,
                  size: 18,
                  color: unlocked ? AppTheme.success : Colors.white30,
                ),
              ],
            ),
            const Spacer(),
            Text(
              def.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              def.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: unlocked ? 0.7 : 0.4),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekTab extends StatelessWidget {
  final AnalyticsSummary summary;

  const _WeekTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final best = s.bestDayThisWeek;

    final items = <Widget>[
      GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "This week's progress",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Goal ${Fmt.liters(s.goalMl)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (!s.weekHasData)
              const _NoData(message: 'No drinks logged this week yet.')
            else
              GoalBarChart(days: s.week, goalMl: s.goalMl),
            if (s.weekHasData) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _Legend(color: AppTheme.success, label: 'Goal reached'),
                  const SizedBox(width: 16),
                  _Legend(color: AppTheme.lightCyan, label: 'Below goal'),
                ],
              ),
            ],
          ],
        ),
      ),
      if (s.weekHasData) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.water_drop_rounded,
                label: 'Week total',
                value: Fmt.liters(s.weekTotalMl).replaceAll(' L', ''),
                unit: 'litres',
                color: AppTheme.lightCyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.star_rounded,
                label: 'Best day',
                value: best == null ? '-' : Fmt.weekday(best.day),
                unit: best == null ? null : Fmt.liters(best.ml),
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily breakdown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              for (final d in s.week.where((d) => !d.isFuture))
                _DayRow(day: d, goalMl: s.goalMl),
            ],
          ),
        ),
      ],
    ];
    if (Breakpoints.isWide(context)) {
      return ListView(
        padding: _wideTabPadding,
        children: [
          _twoColumns(
            [items.first],
            items.length > 1 ? items.sublist(2) : const [],
            leftFlex: 3,
          ),
        ],
      );
    }
    return ListView(padding: _tabPadding, children: items);
  }
}

class _DayRow extends StatelessWidget {
  final DayTotal day;
  final int goalMl;

  const _DayRow({required this.day, required this.goalMl});

  @override
  Widget build(BuildContext context) {
    final ratio = goalMl > 0
        ? (day.ml / goalMl).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final reached = goalMl > 0 && day.ml >= goalMl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                day.isToday ? 'Today' : Fmt.weekday(day.day),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (reached) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: AppTheme.success,
                ),
              ],
              const Spacer(),
              Text(
                Fmt.liters(day.ml, decimals: 2),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                reached ? AppTheme.success : AppTheme.lightCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendsTab extends StatelessWidget {
  final AnalyticsSummary summary;

  const _TrendsTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final observations = TrendInsights.observations(s);
    final suggestions = TrendInsights.suggestions(s);
    final totalBeverage = s.byBeverage.values.fold<int>(0, (a, b) => a + b);
    final beverages = s.byBeverage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final habits = <Widget>[
      if (observations.isNotEmpty) ...[
        const SizedBox(height: 24),
        const SectionTitle('Your habits'),
        for (final tip in observations) ...[
          InsightCard.fromTip(tip),
          const SizedBox(height: 12),
        ],
      ],
    ];
    final drinks = <Widget>[
      if (beverages.isNotEmpty) ...[
        const SizedBox(height: 12),
        const SectionTitle('What you drink'),
        GlassContainer(
          child: Column(
            children: [
              for (final entry in beverages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Icon(
                        beverageIcon(entry.key),
                        color: AppTheme.lightCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 64,
                        child: Text(
                          BeverageModel.labelFor(entry.key),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalBeverage == 0
                                ? 0
                                : entry.value / totalBeverage,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.lightCyan,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 40,
                        child: Text(
                          totalBeverage == 0
                              ? '0%'
                              : '${(entry.value / totalBeverage * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
    final suggest = <Widget>[
      const SizedBox(height: 24),
      const SectionTitle('Suggestions'),
      for (final tip in suggestions) ...[
        InsightCard.fromTip(tip),
        const SizedBox(height: 12),
      ],
    ];
    final items = <Widget>[
      GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 30 days',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Green bars reached your ${Fmt.liters(s.goalMl)} goal.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 18),
            if (s.daysTracked30 == 0)
              const _NoData(message: 'Nothing logged in the last 30 days.')
            else
              GoalBarChart(
                days: s.last30,
                goalMl: s.goalMl,
                compact: true,
                height: 130,
              ),
          ],
        ),
      ),
      ...habits,
      ...drinks,
      ...suggest,
    ];
    if (Breakpoints.isWide(context)) {
      return ListView(
        padding: _wideTabPadding,
        children: [
          items.first,
          const SizedBox(height: 8),
          _twoColumns([...habits, ...suggest], [...drinks]),
        ],
      );
    }
    return ListView(padding: _tabPadding, children: items);
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  final String message;

  const _NoData({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 44,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
