import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:h2orbit/services/firebase_service.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/glass_container.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseService _firebaseService = FirebaseService();

  late TabController _tabController;
  Map<String, int> weeklyData = {};
  int monthlyTotal = 0;
  int currentStreak = 0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final weekly = await _firebaseService.getWeeklyStats(userId);
      final monthly = await _firebaseService.getMonthlyTotal(userId);
      final streak = await _firebaseService.getCurrentStreak(userId);

      if (mounted) {
        setState(() {
          weeklyData = weekly;
          monthlyTotal = monthly;
          currentStreak = streak;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load analytics. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _loadAnalytics,
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.lightCyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Trends'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppTheme.lightCyan,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading analytics...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.white70,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _loadAnalytics,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.lightCyan,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOverviewTab(),
                              _buildWeeklyTab(),
                              _buildTrendsTab(),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: FontAwesomeIcons.fire,
                  title: 'Current Streak',
                  value: '$currentStreak',
                  subtitle: currentStreak == 1 ? 'day' : 'days',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  icon: FontAwesomeIcons.calendarDays,
                  title: 'This Month',
                  value: (monthlyTotal / 1000).toStringAsFixed(1),
                  subtitle: 'liters',
                  color: AppTheme.lightCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: FontAwesomeIcons.chartLine,
                  title: 'Daily Avg',
                  value: (monthlyTotal / DateTime.now().day / 250)
                      .toStringAsFixed(1),
                  subtitle: 'glasses',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  icon: FontAwesomeIcons.trophy,
                  title: 'Best Day',
                  value: _getBestDay(),
                  subtitle: 'this week',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Achievements
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.trophy,
                      color: Colors.amber,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Achievements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildAchievement(
                  FontAwesomeIcons.medal,
                  'First Drop',
                  'Started your hydration journey',
                  true,
                ),
                const SizedBox(height: 15),
                _buildAchievement(
                  FontAwesomeIcons.fire,
                  '7 Day Streak',
                  'Maintained consistency for a week',
                  currentStreak >= 7,
                ),
                const SizedBox(height: 15),
                _buildAchievement(
                  FontAwesomeIcons.chartLine,
                  'Hydration Hero',
                  'Reached target for 30 days',
                  currentStreak >= 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab() {
    final hasData = weeklyData.values.any((v) => v > 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Week\'s Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                if (!hasData)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            color: Colors.white38,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No data yet this week',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start tracking your water intake!',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(height: 250, child: _buildBarChart()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (hasData)
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...weeklyData.entries.map((entry) {
                    final progress = entry.value / 2000; // Target 2L per day
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${(entry.value / 1000).toStringAsFixed(1)}L',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 1.0
                                    ? Colors.green
                                    : AppTheme.lightCyan,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final weeklyAvg = weeklyData.values.isEmpty
        ? 0
        : weeklyData.values.reduce((a, b) => a + b) / weeklyData.length;
    final weeklyAvgGlasses = (weeklyAvg / 250).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.lightbulb,
                      color: Colors.amber,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInsightItem(
                  FontAwesomeIcons.glassWater,
                  'Weekly Average',
                  'You\'re drinking $weeklyAvgGlasses glasses per day on average',
                  AppTheme.lightCyan,
                ),
                const SizedBox(height: 15),
                _buildInsightItem(
                  FontAwesomeIcons.fire,
                  'Consistency',
                  currentStreak > 0
                      ? 'Great job maintaining a $currentStreak day streak!'
                      : 'Start building your streak today!',
                  Colors.orange,
                ),
                const SizedBox(height: 15),
                _buildInsightItem(
                  FontAwesomeIcons.trophy,
                  'Best Performance',
                  'Your best day this week was ${_getBestDay()}',
                  Colors.amber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: Colors.lightBlue,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Recommendations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildRecommendation(
                  '💧 Try drinking a glass right after waking up',
                ),
                const SizedBox(height: 12),
                _buildRecommendation(
                  '⏰ Set reminders for afternoon hydration',
                ),
                const SizedBox(height: 12),
                _buildRecommendation(
                  '🎯 Increase target by 1 glass for better results',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: FaIcon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(
    IconData icon,
    String title,
    String description,
    bool isUnlocked,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? Colors.amber.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
          ),
          child: FaIcon(
            icon,
            color: isUnlocked ? Colors.amber : Colors.white38,
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: isUnlocked ? Colors.white70 : Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (isUnlocked)
          const Icon(Icons.check_circle, color: Colors.white, size: 24),
      ],
    );
  }

  Widget _buildBarChart() {
    final maxValue = weeklyData.values.isEmpty
        ? 2000.0
        : weeklyData.values.reduce((a, b) => a > b ? a : b).toDouble();
    final safeMaxValue = maxValue > 0 ? maxValue : 2000.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weeklyData.entries.map((entry) {
        final height = (entry.value / safeMaxValue * 180).clamp(20.0, 180.0);
        final isGoalMet = entry.value >= 2000;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${(entry.value / 1000).toStringAsFixed(1)}L',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 32,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: isGoalMet
                      ? [Colors.green.shade700, Colors.green.shade400]
                      : [AppTheme.oceanBlue, AppTheme.lightCyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isGoalMet ? Colors.green : AppTheme.lightCyan)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: FaIcon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lightbulb,
            color: Colors.amber,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _getBestDay() {
    if (weeklyData.isEmpty || weeklyData.values.every((v) => v == 0)) {
      return 'N/A';
    }

    var bestEntry = weeklyData.entries.first;
    for (var entry in weeklyData.entries) {
      if (entry.value > bestEntry.value) {
        bestEntry = entry;
      }
    }
    return bestEntry.key;
  }
}