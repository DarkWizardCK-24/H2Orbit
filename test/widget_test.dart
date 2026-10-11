import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h2orbit/screens/analytics_screen.dart';
import 'package:h2orbit/screens/auth_screen.dart';
import 'package:h2orbit/screens/home_screen.dart';
import 'package:h2orbit/screens/notification_settings_screen.dart';
import 'package:h2orbit/screens/profile_screen.dart';
import 'package:h2orbit/screens/registration_screen.dart';
import 'package:h2orbit/services/weather_service.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:h2orbit/widgets/side_rail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';
import 'support/fonts.dart';

/// Phone-sized, tall enough that every list item is built, with the looping
/// wave animation switched off (so `pumpAndSettle` can finish).
void prepare(WidgetTester tester, {Size size = const Size(430, 1700)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
}

const _hot = WeatherSnapshot(
  temperatureC: 33,
  feelsLikeC: 37,
  humidity: 65,
  description: 'sunny',
  iconCode: '01d',
  city: 'Pune',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Home', () {
    late FakeHydrationRepository repo;
    late FakeAuthService auth;

    setUp(() {
      repo = FakeHydrationRepository(users: {'u1': sampleUser()});
      auth = FakeAuthService(signedInUid: 'u1', email: 'aarav@example.com');
    });

    Future<void> openHome(
      WidgetTester tester, {
      FakeNotifications? notifications,
      WeatherProvider? weather,
    }) async {
      prepare(tester);
      await tester.pumpWidget(
        testApp(
          home: const HomeScreen(),
          auth: auth,
          repository: repo,
          notifications: notifications,
          weather: weather,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('greets the user and starts empty', (tester) async {
      await openHome(tester);

      expect(find.text('Aarav'), findsOneWidget);
      expect(find.text('Nothing logged yet'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('2,000 ml'), findsWidgets); // goal
    });

    testWidgets('one tap logs a drink and updates progress', (tester) async {
      await openHome(tester);

      await tester.tap(find.text('Glass'));
      await tester.pumpAndSettle();

      expect(repo.intakes, hasLength(1));
      expect(repo.intakes.single.milliliters, 250);
      expect(find.text('13%'), findsOneWidget); // 250 / 2000 = 12.5 %
      expect(find.text('Nothing logged yet'), findsNothing);
      expect(find.text('1 drink'), findsOneWidget);
    });

    testWidgets('undo takes the drink back out', (tester) async {
      await openHome(tester);
      await tester.tap(find.text('Bottle'));
      await tester.pumpAndSettle();
      expect(repo.intakes, hasLength(1));

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      expect(repo.intakes, isEmpty);
      expect(find.text('Nothing logged yet'), findsOneWidget);
    });

    testWidgets('deleting a log entry can be undone', (tester) async {
      repo.intakes.add(drink(DateTime.now(), 300, id: 'a'));
      await openHome(tester);
      expect(find.text('300 ml'), findsWidgets);

      await tester.tap(find.byTooltip('Delete entry'));
      await tester.pumpAndSettle();
      expect(repo.intakes, isEmpty);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(repo.intakes, hasLength(1));
      expect(repo.intakes.single.milliliters, 300);
    });

    testWidgets('reaching the goal shows it and sends one notification', (
      tester,
    ) async {
      final notifications = FakeNotifications();
      repo.intakes.add(drink(DateTime.now(), 1900, id: 'a'));
      await openHome(tester, notifications: notifications);

      await tester.tap(find.text('Glass'));
      await tester.pumpAndSettle();

      expect(find.text('Done!'), findsOneWidget);
      expect(find.text('Goal reached'), findsWidgets);
      expect(notifications.shown.where((e) => e == 'goal'), hasLength(1));

      // More drinks on the same day don't celebrate again.
      await tester.tap(find.text('Glass'));
      await tester.pumpAndSettle();
      expect(notifications.shown.where((e) => e == 'goal'), hasLength(1));
    });

    testWidgets('does not celebrate a goal that was already met on launch', (
      tester,
    ) async {
      final notifications = FakeNotifications();
      repo.intakes.add(drink(DateTime.now(), 2500, id: 'a'));
      await openHome(tester, notifications: notifications);

      // The first run only records what's already true (silently for
      // milestones), but today's goal is genuinely new information.
      expect(notifications.shown.where((e) => e.startsWith('streak')), isEmpty);
    });

    testWidgets('hot weather raises the goal', (tester) async {
      await openHome(tester, weather: FakeWeather(_hot));

      expect(find.textContaining('Pune'), findsWidgets);
      expect(find.text('2,750 ml'), findsWidgets); // 2000 + 750
      expect(find.textContaining('+750 ml'), findsWidgets);
    });

    testWidgets('shows the streak from previous days', (tester) async {
      final today = Dates.startOfDay(DateTime.now());
      for (var i = 1; i <= 3; i++) {
        repo.intakes.add(
          drink(Dates.addDays(today, -i).add(const Duration(hours: 12)), 2000),
        );
      }
      final semantics = tester.ensureSemantics();
      await openHome(tester);

      expect(find.bySemanticsLabel(RegExp('3 day streak')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a failed save shows an error and logs nothing', (
      tester,
    ) async {
      await openHome(tester);
      repo.intakeError = Exception('offline');

      await tester.tap(find.text('Glass'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't save"), findsOneWidget);
      expect(repo.intakes, isEmpty);
    });

    testWidgets('custom amount sheet logs the chosen drink', (tester) async {
      await openHome(tester);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coffee').last);
      await tester.pump();
      await tester.tap(find.text('Add drink'));
      await tester.pumpAndSettle();

      expect(repo.intakes.single.beverageType, 'coffee');
      expect(repo.intakes.single.milliliters, 250);
    });
  });

  group('Sign in', () {
    late FakeAuthService auth;
    late FakeHydrationRepository repo;

    setUp(() {
      auth = FakeAuthService()..accounts['aarav@example.com'] = 'secret1';
      repo = FakeHydrationRepository(
        users: {
          'uid-aarav@example.com': sampleUser(uid: 'uid-aarav@example.com'),
        },
      );
    });

    Future<void> openAuth(WidgetTester tester) async {
      prepare(tester);
      await tester.pumpWidget(
        testApp(home: const AuthScreen(), auth: auth, repository: repo),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('validates before signing in', (tester) async {
      await openAuth(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows a friendly message for a wrong password', (
      tester,
    ) async {
      await openAuth(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'aarav@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrong-pass',
      );

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('signs in and opens the home screen', (tester) async {
      await openAuth(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'aarav@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'secret1',
      );

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Aarav'), findsOneWidget);
    });

    testWidgets('forgot password sends a reset email', (tester) async {
      await openAuth(tester);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        'aarav@example.com',
      );
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();

      expect(auth.resetEmails, ['aarav@example.com']);
      expect(find.textContaining('reset link'), findsOneWidget);
    });
  });

  group('Registration', () {
    late FakeAuthService auth;
    late FakeHydrationRepository repo;

    setUp(() {
      auth = FakeAuthService();
      repo = FakeHydrationRepository();
    });

    Future<void> openRegistration(WidgetTester tester) async {
      prepare(tester);
      await tester.pumpWidget(
        testApp(home: const RegistrationScreen(), auth: auth, repository: repo),
      );
      await tester.pumpAndSettle();
    }

    Future<void> fillAccount(
      WidgetTester tester, {
      String email = 'new@example.com',
    }) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        'Meera Iyer',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        email,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone number'),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'secret1',
      );
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.tap(find.text('Continue')); // account -> about
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue')); // about -> goal
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();
    }

    testWidgets('does not move on until the account step is valid', (
      tester,
    ) async {
      await openRegistration(tester);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('creates the account and the profile', (tester) async {
      await openRegistration(tester);
      await fillAccount(tester);

      await finish(tester);

      expect(auth.accounts.keys, contains('new@example.com'));
      final profile = repo.users.values.single;
      expect(profile.name, 'Meera Iyer');
      expect(profile.email, 'new@example.com');
      expect(profile.dailyGlassTarget, 8);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('rolls the account back if the profile cannot be saved', (
      tester,
    ) async {
      repo.saveUserError = Exception('firestore unavailable');
      await openRegistration(tester);
      await fillAccount(tester);

      await finish(tester);

      expect(auth.accounts, isEmpty); // so the user can simply try again
      expect(find.textContaining("couldn't finish setting up"), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('an email already in use sends the user back to step 1', (
      tester,
    ) async {
      auth.accounts['taken@example.com'] = 'x';
      await openRegistration(tester);
      await fillAccount(tester, email: 'taken@example.com');

      await finish(tester);

      expect(find.text('This email is already registered.'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('suggests a goal from weight, age and gender', (tester) async {
      await openRegistration(tester);
      await fillAccount(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Suggested for you: 10 glasses'),
        findsOneWidget,
      );
    });
  });

  group('Notification settings', () {
    Future<FakeNotifications> openSettings(
      WidgetTester tester, {
      bool allowed = true,
    }) async {
      prepare(tester);
      final notifications = FakeNotifications()..allowed = allowed;
      await tester.pumpWidget(
        testApp(
          home: const NotificationSettingsScreen(),
          auth: FakeAuthService(signedInUid: 'u1'),
          repository: FakeHydrationRepository(),
          notifications: notifications,
        ),
      );
      await tester.pumpAndSettle();
      return notifications;
    }

    testWidgets('turning notifications on asks for permission', (tester) async {
      final n = await openSettings(tester);
      expect(find.text('Hydration reminders'), findsNothing);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.text('Hydration reminders'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notifications_enabled'), isTrue);
      expect(n.scheduled, isNotEmpty);
    });

    testWidgets('explains when permission is refused', (tester) async {
      await openSettings(tester, allowed: false);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('blocked'), findsOneWidget);
      expect(find.text('Hydration reminders'), findsNothing);
    });

    testWidgets('daily reminders are scheduled from the chosen window', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
      final n = await openSettings(tester);

      await tester.tap(find.byType(Switch).at(1)); // daily reminders
      await tester.pumpAndSettle();

      expect(n.scheduled.last.remindersEnabled, isTrue);
      expect(
        find.textContaining('8 reminders a day'),
        findsOneWidget,
      ); // 8, 10 ... 22
      await tester.tap(find.text('3 h'));
      await tester.pumpAndSettle();
      expect(n.scheduled.last.intervalHours, 3);
      expect(find.textContaining('5 reminders a day'), findsOneWidget);
    });

    testWidgets('turning notifications off cancels everything', (tester) async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
      final n = await openSettings(tester);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(n.cancelAllCalls, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notifications_enabled'), isFalse);
    });
  });

  group('Analytics', () {
    testWidgets('shows stats, the weekly chart and trends', (tester) async {
      prepare(tester);
      final today = Dates.startOfDay(DateTime.now());
      final repo = FakeHydrationRepository(
        users: {'u1': sampleUser()},
        intakes: [
          for (var i = 0; i < 5; i++)
            drink(Dates.addDays(today, -i).add(const Duration(hours: 9)), 2200),
          for (var i = 0; i < 5; i++)
            drink(
              Dates.addDays(today, -i).add(const Duration(hours: 15)),
              300,
              type: 'coffee',
            ),
        ],
      );
      await tester.pumpWidget(
        testApp(
          home: const AnalyticsScreen(),
          auth: FakeAuthService(signedInUid: 'u1'),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current streak'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('First Sip'), findsOneWidget);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text("This week's progress"), findsOneWidget);

      await tester.tap(find.text('Trends'));
      await tester.pumpAndSettle();
      expect(find.text('Last 30 days'), findsOneWidget);
      expect(find.text('What you drink'), findsOneWidget);
    });

    testWidgets('shows an empty state without data', (tester) async {
      prepare(tester);
      await tester.pumpWidget(
        testApp(
          home: const AnalyticsScreen(),
          auth: FakeAuthService(signedInUid: 'u1'),
          repository: FakeHydrationRepository(users: {'u1': sampleUser()}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('No drinks logged this week yet.'), findsOneWidget);
    });

    testWidgets('offers a retry when loading fails', (tester) async {
      prepare(tester);
      final repo = FakeHydrationRepository(users: {'u1': sampleUser()})
        ..intakeError = Exception('boom');
      await tester.pumpWidget(
        testApp(
          home: const AnalyticsScreen(),
          auth: FakeAuthService(signedInUid: 'u1'),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);

      repo.intakeError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Current streak'), findsOneWidget);
    });
  });

  group('Profile', () {
    late FakeHydrationRepository repo;
    late FakeAuthService auth;

    setUp(() {
      repo = FakeHydrationRepository(
        users: {'u1': sampleUser()},
        intakes: [drink(DateTime.now(), 250)],
      );
      auth = FakeAuthService(signedInUid: 'u1', email: 'aarav@example.com')
        ..accounts['aarav@example.com'] = 'secret1';
    });

    Future<void> openProfile(WidgetTester tester) async {
      prepare(tester);
      await tester.pumpWidget(
        testApp(home: const ProfileScreen(), auth: auth, repository: repo),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the profile with BMI and goal', (tester) async {
      await openProfile(tester);

      expect(find.text('Aarav Mehta'), findsWidgets);
      expect(find.text('aarav@example.com'), findsWidgets);
      expect(find.text('22.9'), findsOneWidget);
      expect(find.text('8 glasses'), findsOneWidget);
    });

    testWidgets('editing validates and saves', (tester) async {
      await openProfile(tester);

      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), '');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your name'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Aarav M',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.users['u1']!.name, 'Aarav M');
      expect(find.text('Profile updated'), findsOneWidget);
    });

    testWidgets('deleting the account needs the right password', (
      tester,
    ) async {
      await openProfile(tester);
      await tester.scrollUntilVisible(
        find.text('Delete account'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'nope',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(auth.accountDeleted, isFalse);
      expect(repo.users, isNotEmpty);
    });

    testWidgets('deleting the account removes the data and signs out', (
      tester,
    ) async {
      await openProfile(tester);
      await tester.scrollUntilVisible(
        find.text('Delete account'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'secret1',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(auth.accountDeleted, isTrue);
      expect(repo.users, isEmpty);
      expect(repo.intakes, isEmpty);
      expect(find.byType(AuthScreen), findsOneWidget);
    });
  });

  group('Wide layout', () {
    Future<void> open(WidgetTester tester, Widget home, Size size) async {
      prepare(tester, size: size);
      await tester.pumpWidget(
        testApp(
          home: home,
          auth: FakeAuthService(signedInUid: 'u1', email: 'aarav@example.com'),
          repository: FakeHydrationRepository(users: {'u1': sampleUser()}),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('home shows the side rail instead of the menu', (tester) async {
      await open(tester, const HomeScreen(), const Size(1100, 900));
      expect(find.byType(SideRail), findsOneWidget);
      expect(find.byTooltip('Menu'), findsNothing);
      expect(find.text('Quick add'), findsOneWidget);
    });

    testWidgets('phone width keeps the menu and no rail', (tester) async {
      await open(tester, const HomeScreen(), const Size(430, 900));
      expect(find.byType(SideRail), findsNothing);
      expect(find.byTooltip('Menu'), findsOneWidget);
    });

    testWidgets('the rail navigates between sections', (tester) async {
      await open(tester, const HomeScreen(), const Size(1100, 900));
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsScreen), findsOneWidget);
      expect(find.byType(SideRail), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('profile and analytics lay out wide without errors', (
      tester,
    ) async {
      await open(tester, const ProfileScreen(), const Size(1100, 900));
      expect(find.text('Sign out'), findsOneWidget);
      await open(tester, const AnalyticsScreen(), const Size(1100, 900));
      for (final tab in ['Week', 'Trends', 'Overview']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('notification settings show the rail', (tester) async {
      await open(
        tester,
        const NotificationSettingsScreen(),
        const Size(1100, 900),
      );
      expect(find.byType(SideRail), findsOneWidget);
    });
  });
}
