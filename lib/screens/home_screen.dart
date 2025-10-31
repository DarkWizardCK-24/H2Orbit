import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/models/water_intake_model.dart';
import 'package:h2orbit/services/ai_prediction_service.dart';
import 'package:h2orbit/services/firebase_service.dart';
import 'package:h2orbit/services/achievement_manager.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/beverage_card.dart';
import 'package:h2orbit/widgets/glass_container.dart';
import 'package:h2orbit/widgets/glass_drawer.dart';
import 'package:h2orbit/widgets/insight_card.dart';
import 'package:h2orbit/widgets/progress_ring.dart';
import 'package:h2orbit/widgets/water_wave_animation.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseService _firebaseService = FirebaseService();
  final AchievementManager _achievementManager = AchievementManager();

  StreamSubscription? _intakeSubscription;

  int totalIntakeToday = 0;
  int targetGlasses = 8;
  int dailyGoalMl = 2000;
  UserModel? currentUser;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _aiPrediction = '';
  int _currentStreak = 0;
  int _totalGlassesAllTime = 0;

  final List<Map<String, dynamic>> beverages = [
    {
      'name': 'Water',
      'icon': FontAwesomeIcons.glassWater,
      'ml': 250,
      'type': 'water',
    },
    {
      'name': 'Juice',
      'icon': FontAwesomeIcons.wineGlass,
      'ml': 200,
      'type': 'juice',
    },
    {'name': 'Tea', 'icon': FontAwesomeIcons.mugHot, 'ml': 150, 'type': 'tea'},
    {
      'name': 'Coffee',
      'icon': FontAwesomeIcons.mugSaucer,
      'ml': 150,
      'type': 'coffee',
    },
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _initialize();
  }

  Future<void> _initialize() async {
    await _achievementManager.initialize();
    await _loadUserData();
    _listenToIntakeChanges();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _firebaseService.getUser(userId);
      if (user != null && mounted) {
        setState(() {
          currentUser = user;
          targetGlasses = user.dailyGlassTarget;
          dailyGoalMl = targetGlasses * 250;
        });
        debugPrint(
          'Loaded user data: targetGlasses=$targetGlasses, dailyGoalMl=$dailyGoalMl',
        );
        await _updateAIPrediction();
        await _loadStreakData();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStreakData() async {
    try {
      final streak = await _firebaseService.getCurrentStreak(userId);
      if (mounted) {
        setState(() => _currentStreak = streak);
      }
    } catch (e) {
      debugPrint('Error loading streak data: $e');
    }
  }

  void _listenToIntakeChanges() {
    _intakeSubscription?.cancel();
    _intakeSubscription = _firebaseService
        .getTodayIntakeStream(userId)
        .listen(
          (intakes) async {
            if (!mounted) return;

            int total = 0;
            int totalGlasses = intakes.length;

            for (var intake in intakes) {
              total += intake.milliliters;
            }

            final previousTotal = totalIntakeToday;

            debugPrint(
              'Stream update: total=$total ml, glasses=$totalGlasses, dailyGoal=$dailyGoalMl ml',
            );

            // Force setState to update UI
            if (mounted) {
              setState(() {
                totalIntakeToday = total;
                _totalGlassesAllTime = totalGlasses;
              });
            }

            // Check achievements
            await _checkAllAchievements(
              previousTotal: previousTotal,
              currentTotal: total,
              totalGlasses: totalGlasses,
            );

            await _updateAIPrediction();
          },
          onError: (error) {
            debugPrint('Error listening to intake changes: $error');
          },
        );
  }

  Future<void> _checkAllAchievements({
    required int previousTotal,
    required int currentTotal,
    required int totalGlasses,
  }) async {
    try {
      if (currentTotal >= dailyGoalMl && previousTotal < dailyGoalMl) {
        await _achievementManager.checkDailyGoal(currentTotal, dailyGoalMl);
      }

      await _achievementManager.checkOverachiever(currentTotal, dailyGoalMl);
      await _loadStreakData();
      await _achievementManager.checkStreakAchievement(_currentStreak);
      await _achievementManager.checkGlassMilestone(totalGlasses);
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  Future<void> _updateAIPrediction() async {
    if (currentUser == null) return;

    try {
      final prediction = await AIPredictionService.getPrediction(
        currentUser,
        totalIntakeToday,
        dailyGoalMl,
      );
      if (mounted) {
        setState(() {
          _aiPrediction = prediction;
        });
      }
    } catch (e) {
      debugPrint('Error updating AI prediction: $e');
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await _loadUserData();
      await _loadStreakData();
      await _updateAIPrediction();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Data refreshed successfully!'),
              ],
            ),
            backgroundColor: AppTheme.oceanBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Failed to refresh data'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _addWaterIntake(int ml, String beverageType) async {
    try {
      const multipliers = {
        'water': 1.0,
        'juice': 0.9,
        'tea': 0.8,
        'coffee': 0.7,
      };
      final hydrationValue = ml * (multipliers[beverageType] ?? 1.0);

      final intake = WaterIntakeModel(
        id: '',
        userId: userId,
        timestamp: DateTime.now(),
        milliliters: ml,
        beverageType: beverageType,
        hydrationValue: hydrationValue,
      );

      debugPrint('Adding water intake: $ml ml of $beverageType');
      await _firebaseService.addWaterIntake(intake);
      debugPrint('Water intake added successfully');

      await _achievementManager.checkEarlyBird();
      await _achievementManager.checkNightOwl();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Added $ml ml of $beverageType!',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.oceanBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error adding water intake: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to add intake. Please try again.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _openDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Drawer',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: GlassDrawer(currentStreak: _currentStreak),
        );
      },
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _intakeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.oceanGradient),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.lightCyan,
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final progress = dailyGoalMl > 0
        ? (totalIntakeToday / dailyGoalMl).clamp(0.0, 1.0)
        : 0.0;
    final glassesConsumed = (totalIntakeToday / 250).floor();

    debugPrint(
      'UI Render: totalIntake=$totalIntakeToday, progress=$progress, glasses=$glassesConsumed',
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.oceanGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'H₂Orbit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        if (_currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_currentStreak',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _openDrawer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppTheme.lightCyan,
                  backgroundColor: AppTheme.deepCyan,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassContainer(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Today\'s Progress',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$glassesConsumed / $targetGlasses',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'glasses',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${totalIntakeToday}ml / ${dailyGoalMl}ml',
                                          style: const TextStyle(
                                            color: AppTheme.lightCyan,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: ProgressRing(
                                      progress: progress,
                                      key: ValueKey(
                                        'progress_$totalIntakeToday',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              WaterWaveAnimation(
                                progress: progress,
                                controller: _waveController,
                                key: ValueKey('wave_$totalIntakeToday'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quick Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isRefreshing)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.lightCyan,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.3,
                              ),
                          itemCount: beverages.length,
                          itemBuilder: (context, index) {
                            final beverage = beverages[index];
                            return BeverageCard(
                              name: beverage['name'],
                              icon: beverage['icon'],
                              ml: beverage['ml'],
                              onTap: () => _addWaterIntake(
                                beverage['ml'],
                                beverage['type'],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'AI Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_aiPrediction.isNotEmpty) ...[
                          InsightCard(
                            icon: FontAwesomeIcons.lightbulb,
                            title: 'Smart Recommendation',
                            description: _aiPrediction,
                          ),
                          const SizedBox(height: 12),
                        ],
                        InsightCard(
                          icon: progress >= 1.0
                              ? FontAwesomeIcons.trophy
                              : progress >= 0.5
                              ? FontAwesomeIcons.fire
                              : FontAwesomeIcons.droplet,
                          title: progress >= 1.0
                              ? 'Goal Achieved! 🎉'
                              : progress >= 0.5
                              ? 'Keep It Up!'
                              : 'Let\'s Start!',
                          description: progress >= 1.0
                              ? 'Amazing! You\'ve reached your daily goal!'
                              : progress >= 0.5
                              ? 'You\'re doing great! Keep hydrating!'
                              : 'Let\'s boost your hydration today!',
                        ),
                        if (_currentStreak >= 3 ||
                            _totalGlassesAllTime >= 50) ...[
                          const SizedBox(height: 12),
                          GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Achievements',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_currentStreak >= 3)
                                  _buildAchievementChip(
                                    '🔥 $_currentStreak Day Streak',
                                    Colors.orange,
                                  ),
                                if (_totalGlassesAllTime >= 50)
                                  _buildAchievementChip(
                                    '💧 $_totalGlassesAllTime Glasses',
                                    AppTheme.lightCyan,
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomIntakeDialog,
        backgroundColor: AppTheme.lightCyan,
        elevation: 6,
        icon: const Icon(FontAwesomeIcons.plus, color: Colors.white, size: 20),
        label: const Text(
          'Custom',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  void _showCustomIntakeDialog() {
    int customMl = 250;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.deepCyan,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Add Custom Amount',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                '$customMl ml',
                style: const TextStyle(
                  color: AppTheme.lightCyan,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.lightCyan,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: Colors.white,
                  overlayColor: AppTheme.lightCyan.withOpacity(0.2),
                  valueIndicatorColor: AppTheme.lightCyan,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: customMl.toDouble(),
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  label: '$customMl ml',
                  onChanged: (v) {
                    setDialogState(() => customMl = v.toInt());
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '≈ ${(customMl / 250).toStringAsFixed(1)} glasses',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _addWaterIntake(customMl, 'water');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightCyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
