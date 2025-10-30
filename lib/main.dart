import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:h2orbit/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();
  runApp(const H2OrbitApp());
}

class H2OrbitApp extends StatelessWidget {
  const H2OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'H₂Orbit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.cyan,
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: AppTheme.darkBackground,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}