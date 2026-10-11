import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:h2orbit/firebase_options.dart';
import 'package:h2orbit/screens/splash_screen.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/services/firebase_service.dart';
import 'package:h2orbit/services/notification_service.dart';
import 'package:h2orbit/services/weather_service.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Never throws, so an unsupported platform can't stop the app from starting.
  final notifications = NotificationService();
  await notifications.initialize();

  runApp(
    H2OrbitApp(
      auth: FirebaseAuthService(),
      repository: FirestoreHydrationRepository(),
      notificationService: notifications,
      weather: OpenWeatherProvider(),
    ),
  );
}

/// The app with its services passed in, so tests can supply fakes.
class H2OrbitApp extends StatelessWidget {
  final AuthService auth;
  final HydrationRepository repository;
  final NotificationService notificationService;
  final WeatherProvider? weather;

  const H2OrbitApp({
    super.key,
    required this.auth,
    required this.repository,
    required this.notificationService,
    this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      auth: auth,
      repository: repository,
      notificationGateway: notificationService,
      notificationScheduler: notificationService,
      weather: weather,
      child: MaterialApp(
        title: 'H2Orbit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const SplashScreen(),
      ),
    );
  }
}

/// Makes the app's services available to every screen.
class AppProviders extends StatelessWidget {
  final AuthService auth;
  final HydrationRepository repository;
  final NotificationGateway notificationGateway;
  final NotificationScheduler notificationScheduler;
  final WeatherProvider? weather;
  final Widget child;

  const AppProviders({
    super.key,
    required this.auth,
    required this.repository,
    required this.notificationGateway,
    required this.notificationScheduler,
    required this.child,
    this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        Provider<HydrationRepository>.value(value: repository),
        Provider<NotificationGateway>.value(value: notificationGateway),
        Provider<NotificationScheduler>.value(value: notificationScheduler),
        Provider<WeatherProvider?>.value(value: weather),
      ],
      child: child,
    );
  }
}
