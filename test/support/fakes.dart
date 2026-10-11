import 'dart:async';

import 'package:flutter/material.dart';
import 'package:h2orbit/main.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/models/water_intake_model.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/services/firebase_service.dart';
import 'package:h2orbit/services/notification_service.dart';
import 'package:h2orbit/services/weather_service.dart';
import 'package:h2orbit/utils/theme.dart';

/// In-memory [HydrationRepository].
class FakeHydrationRepository implements HydrationRepository {
  FakeHydrationRepository({
    Map<String, UserModel>? users,
    List<WaterIntakeModel>? intakes,
  }) : users = users ?? {},
       intakes = intakes ?? [];

  final Map<String, UserModel> users;
  final List<WaterIntakeModel> intakes;
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  /// When set, [saveUser] throws it.
  Object? saveUserError;

  /// When set, every intake read/write throws it.
  Object? intakeError;

  @override
  Future<UserModel?> getUser(String uid) async => users[uid];

  @override
  Future<void> saveUser(UserModel user) async {
    if (saveUserError != null) throw saveUserError!;
    users[user.uid] = user;
  }

  @override
  Future<WaterIntakeModel> addIntake(WaterIntakeModel intake) async {
    if (intakeError != null) throw intakeError!;
    final saved = intake.copyWith(
      id: intake.id.isEmpty ? 'intake-${_nextId++}' : intake.id,
    );
    intakes.add(saved);
    _changes.add(null);
    return saved;
  }

  @override
  Future<void> deleteIntake(String id) async {
    intakes.removeWhere((i) => i.id == id);
    _changes.add(null);
  }

  List<WaterIntakeModel> _between(String userId, DateTime start, DateTime end) {
    final list =
        intakes
            .where(
              (i) =>
                  i.userId == userId &&
                  !i.timestamp.isBefore(start) &&
                  i.timestamp.isBefore(end),
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  @override
  Stream<List<WaterIntakeModel>> watchDay(String userId, DateTime day) async* {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    yield _between(userId, start, end);
    await for (final _ in _changes.stream) {
      yield _between(userId, start, end);
    }
  }

  @override
  Future<List<WaterIntakeModel>> getIntakeBetween(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    if (intakeError != null) throw intakeError!;
    return _between(userId, start, end);
  }

  @override
  Future<IntakeTotals> getTotals(String userId) async {
    final mine = intakes.where((i) => i.userId == userId);
    return IntakeTotals(
      count: mine.length,
      milliliters: mine.fold(0, (sum, i) => sum + i.milliliters),
    );
  }

  @override
  Future<void> deleteAllUserData(String userId) async {
    intakes.removeWhere((i) => i.userId == userId);
    users.remove(userId);
    _changes.add(null);
  }
}

/// In-memory [AuthService] with a tiny account database.
class FakeAuthService extends AuthService {
  FakeAuthService({String? signedInUid, String? email})
    : _userId = signedInUid,
      _email = email;

  /// email -> password
  final Map<String, String> accounts = {};
  String? _userId;
  String? _email;
  int _counter = 1;

  final List<String> resetEmails = [];
  bool accountDeleted = false;

  @override
  String? get userId => _userId;

  @override
  String? get email => _email;

  @override
  Future<void> signIn({required String email, required String password}) async {
    final stored = accounts[email.trim()];
    if (stored == null || stored != password) {
      throw AuthFailure.fromCode('invalid-credential');
    }
    _userId = 'uid-${email.trim()}';
    _email = email.trim();
    notifyListeners();
  }

  @override
  Future<String> signUp({
    required String email,
    required String password,
  }) async {
    if (accounts.containsKey(email.trim())) {
      throw AuthFailure.fromCode('email-already-in-use');
    }
    accounts[email.trim()] = password;
    _userId = 'new-user-${_counter++}';
    _email = email.trim();
    notifyListeners();
    return _userId!;
  }

  @override
  Future<void> signOut() async {
    _userId = null;
    _email = null;
    notifyListeners();
  }

  @override
  Future<void> sendPasswordReset(String email) async => resetEmails.add(email);

  @override
  Future<void> reauthenticate(String password) async {
    if (accounts[_email] != password) {
      throw AuthFailure.fromCode('invalid-credential');
    }
  }

  @override
  Future<void> deleteAccount() async {
    accounts.remove(_email);
    accountDeleted = true;
    _userId = null;
    _email = null;
    notifyListeners();
  }

  @override
  Future<void> discardCurrentAccount() async {
    accounts.remove(_email);
    _userId = null;
    _email = null;
    notifyListeners();
  }
}

class FakeNotifications implements NotificationGateway, NotificationScheduler {
  @override
  bool isSupported = true;

  /// What the (pretend) phone allows.
  bool allowed = true;

  final List<String> shown = [];
  final List<NotificationPrefs> scheduled = [];
  int cancelAllCalls = 0;
  int testsSent = 0;

  @override
  Future<bool> requestPermissions() async => allowed;

  @override
  Future<bool> areNotificationsAllowed() async => allowed;

  @override
  Future<void> applyReminderSchedule(NotificationPrefs prefs) async =>
      scheduled.add(prefs);

  @override
  Future<void> cancelAll() async => cancelAllCalls++;

  @override
  Future<void> sendTest() async => testsSent++;

  @override
  Future<void> goalReached() async => shown.add('goal');

  @override
  Future<void> achievement({
    required String title,
    required String body,
    required String payload,
  }) async => shown.add(payload);
}

class FakeWeather implements WeatherProvider {
  FakeWeather(this.snapshot);

  final WeatherSnapshot? snapshot;

  @override
  bool get isConfigured => snapshot != null;

  @override
  Future<WeatherSnapshot?> fetch() async => snapshot;
}

UserModel sampleUser({
  String uid = 'u1',
  String name = 'Aarav Mehta',
  int glasses = 8,
  int weightKg = 70,
}) => UserModel(
  uid: uid,
  name: name,
  email: 'aarav@example.com',
  phone: '+91 98765 43210',
  dateOfBirth: DateTime(1998, 5, 14),
  age: 27,
  gender: 'Male',
  heightCm: 175,
  weightKg: weightKg,
  dailyGlassTarget: glasses,
);

WaterIntakeModel drink(
  DateTime when,
  int ml, {
  String type = 'water',
  String user = 'u1',
  String? id,
}) => WaterIntakeModel(
  id: id ?? 'seed-${when.microsecondsSinceEpoch}-$ml',
  userId: user,
  timestamp: when,
  milliliters: ml,
  beverageType: type,
  hydrationValue: ml.toDouble(),
);

/// Wraps [home] in the app's providers and theme, using fakes.
Widget testApp({
  required Widget home,
  required AuthService auth,
  required HydrationRepository repository,
  FakeNotifications? notifications,
  WeatherProvider? weather,
}) {
  final n = notifications ?? FakeNotifications();
  return AppProviders(
    auth: auth,
    repository: repository,
    notificationGateway: n,
    notificationScheduler: n,
    weather: weather,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: home,
    ),
  );
}
