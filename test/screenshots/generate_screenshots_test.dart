// Generates the README screenshots from the real screens using sample data
// (no Firebase needed). Skipped during a normal `flutter test`; run with:
//
//   flutter test test/screenshots --dart-define=SCREENSHOTS=true
//
// PNGs are written to docs/screenshots/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h2orbit/screens/analytics_screen.dart';
import 'package:h2orbit/screens/auth_screen.dart';
import 'package:h2orbit/screens/home_screen.dart';
import 'package:h2orbit/screens/notification_settings_screen.dart';
import 'package:h2orbit/screens/onboarding_screen.dart';
import 'package:h2orbit/screens/profile_screen.dart';
import 'package:h2orbit/screens/registration_screen.dart';
import 'package:h2orbit/services/weather_service.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';

const bool _enabled = bool.fromEnvironment('SCREENSHOTS');
final _boundaryKey = GlobalKey();

/// Tuesday 13 Oct 2026, mid-afternoon: every screenshot "happens" now.
final DateTime _now = DateTime(2026, 10, 13, 15, 40);
DateTime clock() => _now;

const _weather = WeatherSnapshot(
  temperatureC: 31,
  feelsLikeC: 35,
  humidity: 62,
  description: 'sunny',
  iconCode: '01d',
  city: 'Pune',
);

/// A month of believable history: the last 6 days reached the goal.
FakeHydrationRepository seededRepo() {
  final today = Dates.startOfDay(_now);
  const totals = [
    2150, 2300, 2050, 2400, 2000, 2200, // days -1 .. -6 (the streak)
    1400, 2100, 1750, 2000, 1500, 2250, 1900, 1200, 2050, 2000,
    1650, 2300, 1800, 2100, 1300, 2000, 1950, 2200, 1700, 2050,
  ];
  const times = [8, 11, 15, 19];
  final intakes = <_Seed>[];

  for (var i = 0; i < totals.length; i++) {
    final date = Dates.addDays(today, -(i + 1));
    // Split each day over four drinks (the last one takes the remainder so
    // the day adds up exactly); the first is often tea or coffee.
    final water = (totals[i] - 150) ~/ 3;
    final amounts = [150, water, water, totals[i] - 150 - 2 * water];
    for (var j = 0; j < 4; j++) {
      final type = j == 0 ? (i.isEven ? 'coffee' : 'tea') : 'water';
      intakes.add(
        _Seed(
          date.add(Duration(hours: times[j], minutes: i % 40)),
          amounts[j],
          type,
        ),
      );
    }
  }

  // Today so far: 1,250 ml.
  for (final d in [
    (DateTime(2026, 10, 13, 7, 40), 250, 'water'),
    (DateTime(2026, 10, 13, 9, 10), 150, 'coffee'),
    (DateTime(2026, 10, 13, 11, 20), 500, 'water'),
    (DateTime(2026, 10, 13, 13, 5), 200, 'juice'),
    (DateTime(2026, 10, 13, 14, 30), 150, 'tea'),
  ]) {
    intakes.add(_Seed(d.$1, d.$2, d.$3));
  }

  return FakeHydrationRepository(
    users: {'u1': sampleUser(glasses: 8)},
    intakes: [for (final s in intakes) drink(s.time, s.ml, type: s.type)],
  );
}

class _Seed {
  final DateTime time;
  final int ml;
  final String type;

  _Seed(this.time, this.ml, this.type);
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(430, 932),
  double dpr = 2,
  FakeAuthService? auth,
  FakeHydrationRepository? repo,
  FakeNotifications? notifications,
  WeatherProvider? weather,
  bool settle = true,
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: testApp(
        home: home,
        auth:
            auth ??
            FakeAuthService(signedInUid: 'u1', email: 'aarav@example.com'),
        repository: repo ?? seededRepo(),
        notifications: notifications,
        weather: weather,
      ),
    ),
  );
  // Images decode asynchronously, so load the logo before the first frame
  // is captured (otherwise it would be drawn as an empty box).
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/logo.png'),
      tester.element(find.byType(MaterialApp)),
    );
  });
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _shot(
  WidgetTester tester,
  String name, {
  double dpr = 2,
  bool settle = true,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  ScaffoldMessenger.of(
    tester.element(find.byType(Scaffold).first),
  ).clearSnackBars();
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }

  await tester.runAsync(() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/screenshots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${file.path} (${image.width}x${image.height})');
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (_enabled) await loadAppFonts();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('sign in and onboarding', skip: !_enabled, (tester) async {
    await _pump(tester, const AuthScreen(), auth: FakeAuthService());
    await _shot(tester, '01-sign-in');
  });

  testWidgets('registration', skip: !_enabled, (tester) async {
    await _pump(tester, const RegistrationScreen(), auth: FakeAuthService());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Meera Iyer',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'meera@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone number'),
      '9876543210',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.pumpAndSettle();
    await _shot(tester, '02-register-account');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await _shot(tester, '03-register-goal');
  });

  testWidgets('home', skip: !_enabled, (tester) async {
    await _pump(
      tester,
      HomeScreen(clock: clock),
      weather: FakeWeather(_weather),
    );
    await _shot(tester, '04-home');

    await tester.drag(find.byType(ListView).first, const Offset(0, -620));
    await tester.pumpAndSettle();
    await _shot(tester, '05-home-log');

    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await _shot(tester, '06-menu');
  });

  testWidgets('home, goal reached', skip: !_enabled, (tester) async {
    final repo = seededRepo()
      ..intakes.addAll([
        drink(DateTime(2026, 10, 13, 15, 0), 750),
        drink(DateTime(2026, 10, 13, 15, 30), 800),
      ]);
    await _pump(tester, HomeScreen(clock: clock), repo: repo);
    await _shot(tester, '07-home-goal-reached');
  });

  testWidgets('analytics', skip: !_enabled, (tester) async {
    await _pump(tester, AnalyticsScreen(clock: clock));
    await _shot(tester, '08-analytics-overview');

    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await _shot(tester, '09-analytics-achievements');

    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    await _shot(tester, '10-analytics-week');

    await tester.tap(find.text('Trends'));
    await tester.pumpAndSettle();
    await _shot(tester, '11-analytics-trends');
  });

  testWidgets('profile and notifications', skip: !_enabled, (tester) async {
    await _pump(tester, const ProfileScreen());
    await _shot(tester, '12-profile');

    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'periodic_reminders': true,
    });
    await _pump(tester, const NotificationSettingsScreen());
    await _shot(tester, '13-notifications');
  });

  testWidgets('onboarding', skip: !_enabled, (tester) async {
    // The Lottie animation loops forever, so never wait for it to "settle".
    await _pump(tester, const OnboardingScreen(), settle: false);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(seconds: 1));
    await _shot(tester, '14-onboarding', settle: false);
  });

  testWidgets('wide screen', skip: !_enabled, (tester) async {
    await _pump(
      tester,
      HomeScreen(clock: clock),
      size: const Size(1100, 900),
      dpr: 1.5,
      weather: FakeWeather(_weather),
    );
    await _shot(tester, '15-home-wide', dpr: 1.5);

    await _pump(
      tester,
      AnalyticsScreen(clock: clock),
      size: const Size(1100, 900),
      dpr: 1.5,
    );
    await _shot(tester, '16-analytics-wide', dpr: 1.5);

    await _pump(
      tester,
      const ProfileScreen(),
      size: const Size(1100, 900),
      dpr: 1.5,
    );
    await _shot(tester, '17-profile-wide', dpr: 1.5);
  });
}
