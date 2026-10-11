import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:h2orbit/domain/hydration_math.dart';
import 'package:h2orbit/domain/streaks.dart';
import 'package:h2orbit/models/beverage_model.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/models/water_intake_model.dart';
import 'package:h2orbit/services/achievement_manager.dart';
import 'package:h2orbit/services/ai_prediction_service.dart';
import 'package:h2orbit/services/firebase_service.dart';
import 'package:h2orbit/services/weather_service.dart';
import 'package:h2orbit/utils/constants.dart';
import 'package:h2orbit/utils/helpers.dart';

/// State and logic behind the home screen.
class HomeController extends ChangeNotifier {
  HomeController({
    required this.userId,
    required HydrationRepository repository,
    required AchievementManager achievements,
    WeatherProvider? weather,
    DateTime Function()? clock,
  }) : _repo = repository,
       _achievements = achievements,
       _weatherProvider = weather,
       _clock = clock ?? DateTime.now;

  final String userId;
  final HydrationRepository _repo;
  final AchievementManager _achievements;
  final WeatherProvider? _weatherProvider;
  final DateTime Function() _clock;

  UserModel? user;
  WeatherSnapshot? weather;
  List<WaterIntakeModel> todayIntakes = const [];
  bool loading = true;
  String? loadError;

  /// Totals of the days *before* today, used for the streak.
  Map<DateTime, int> _history = {};
  IntakeTotals _allTime = IntakeTotals.zero;
  DateTime _day = DateTime(2000);
  StreamSubscription<List<WaterIntakeModel>>? _subscription;
  Timer? _midnightTimer;
  DateTime? _weatherFetchedAt;
  bool _disposed = false;
  bool _gotFirstSnapshot = false;

  /// The current time (injectable so tests and screenshots are repeatable).
  DateTime get now => _clock();

  // ---- derived values ----

  int get baseGoalMl =>
      (user?.dailyGlassTarget ?? AppConstants.defaultWaterTarget) *
      AppConstants.mlPerGlass;

  int get weatherBonusMl => weather?.bonusMl ?? 0;

  /// Today's goal: the profile goal plus extra for hot weather.
  int get goalMl => baseGoalMl + weatherBonusMl;

  int get totalMl => todayIntakes.fold(0, (sum, i) => sum + i.milliliters);

  double get progress =>
      goalMl > 0 ? (totalMl / goalMl).clamp(0.0, 1.0).toDouble() : 0;

  int get remainingMl => goalMl > totalMl ? goalMl - totalMl : 0;

  bool get goalReached => goalMl > 0 && totalMl >= goalMl;

  /// Goals reached on consecutive days, counting today once it is reached.
  int get streak => StreakCalculator.current(
    {..._history, _day: totalMl},
    goalMl: baseGoalMl,
    today: _day,
  );

  int get allTimeGlasses =>
      (_allTime.milliliters / AppConstants.mlPerGlass).floor();

  /// Most recent first.
  List<WaterIntakeModel> get log => todayIntakes.reversed.toList();

  List<CoachTip> get tips => HydrationCoach.tips(
    intakeMl: totalMl,
    goalMl: goalMl,
    now: _clock(),
    user: user,
    weather: weather,
    caffeineMg: HydrationMath.caffeineMg(todayIntakes),
  );

  // ---- lifecycle ----

  Future<void> start() async {
    _day = Dates.startOfDay(_clock());
    try {
      user = await _repo.getUser(userId);
      await _loadHistory();
      _listenToToday();
      _scheduleMidnight();
      unawaited(_loadWeather());
    } catch (e) {
      debugPrint('Could not load home data: $e');
      loadError = 'Could not load your data. Pull down to retry.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    try {
      loadError = null;
      user = await _repo.getUser(userId);
      await _loadHistory();
      await _loadWeather(force: true);
    } catch (e) {
      debugPrint('Refresh failed: $e');
      loadError = 'Could not refresh. Check your connection.';
    }
    _notify();
  }

  /// Call when the app returns to the foreground: the day may have changed.
  void onResume() {
    if (_disposed) return;
    if (!Dates.isSameDay(_day, _clock())) {
      unawaited(_rollOver());
    } else {
      unawaited(_loadWeather());
    }
  }

  Future<void> _rollOver() async {
    _day = Dates.startOfDay(_clock());
    _gotFirstSnapshot = false;
    todayIntakes = const [];
    _notify();
    try {
      await _loadHistory();
      _listenToToday();
    } catch (e) {
      debugPrint('Day rollover failed: $e');
    }
    _scheduleMidnight();
    _notify();
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final wait = Dates.nextMidnight(_clock()).difference(_clock());
    _midnightTimer = Timer(wait + const Duration(seconds: 1), () {
      if (!_disposed) unawaited(_rollOver());
    });
  }

  Future<void> _loadHistory() async {
    final today = Dates.startOfDay(_clock());
    final from = Dates.addDays(today, -AppConstants.historyDays);
    final past = await _repo.getIntakeBetween(userId, from, today);
    _history = HydrationMath.totalsByDay(past);
    _allTime = await _repo.getTotals(userId);
  }

  void _listenToToday() {
    _subscription?.cancel();
    _subscription = _repo
        .watchDay(userId, _day)
        .listen(
          (intakes) {
            final previous = totalMl;
            todayIntakes = intakes;
            final firstSnapshot = !_gotFirstSnapshot;
            _gotFirstSnapshot = true;
            _notify();
            // Don't celebrate what was already true when the app opened.
            if (!firstSnapshot || totalMl != previous) {
              unawaited(_checkAchievements());
            }
          },
          onError: (Object e) {
            debugPrint('Intake stream error: $e');
            loadError = 'Lost connection to your data.';
            _notify();
          },
        );
  }

  Future<void> _checkAchievements() => _achievements.onProgress(
    intakeMl: totalMl,
    goalMl: goalMl,
    streak: streak,
    allTimeGlasses: allTimeGlasses,
    now: _clock(),
  );

  Future<void> _loadWeather({bool force = false}) async {
    final provider = _weatherProvider;
    if (provider == null || !provider.isConfigured) return;
    final fetchedAt = _weatherFetchedAt;
    if (!force &&
        fetchedAt != null &&
        _clock().difference(fetchedAt) < const Duration(minutes: 30)) {
      return;
    }
    final result = await provider.fetch();
    if (result != null) {
      weather = result;
      _weatherFetchedAt = _clock();
      _notify();
    }
  }

  // ---- actions ----

  /// Logs a drink. Throws if it could not be saved.
  Future<WaterIntakeModel> addDrink(int ml, String type) async {
    final intake = WaterIntakeModel(
      id: '',
      userId: userId,
      timestamp: _clock(),
      milliliters: ml,
      beverageType: type,
      hydrationValue: ml * BeverageModel.multiplierFor(type),
    );
    final saved = await _repo.addIntake(intake);
    _allTime = IntakeTotals(
      count: _allTime.count + 1,
      milliliters: _allTime.milliliters + ml,
    );
    unawaited(_achievements.onDrinkLogged(_clock()));
    return saved;
  }

  Future<void> removeDrink(WaterIntakeModel intake) async {
    await _repo.deleteIntake(intake.id);
    _allTime = IntakeTotals(
      count: (_allTime.count - 1).clamp(0, _allTime.count).toInt(),
      milliliters: (_allTime.milliliters - intake.milliliters)
          .clamp(0, _allTime.milliliters)
          .toInt(),
    );
  }

  /// Puts a removed drink back (same time and amount).
  Future<void> restoreDrink(WaterIntakeModel intake) async {
    await _repo.addIntake(intake);
    _allTime = IntakeTotals(
      count: _allTime.count + 1,
      milliliters: _allTime.milliliters + intake.milliliters,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }
}
