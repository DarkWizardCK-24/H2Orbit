import 'package:flutter/material.dart';
import 'package:h2orbit/screens/auth_screen.dart';
import 'package:h2orbit/screens/home_screen.dart';
import 'package:h2orbit/screens/onboarding_screen.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/app_logo.dart';
import 'package:h2orbit/widgets/ocean_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1400),
    vsync: this,
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.6,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show the logo for a moment while the first-run flag loads.
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);
    final prefs = results.first as SharedPreferences;
    if (!mounted) return;

    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final signedIn = context.read<AuthService>().isSignedIn;

    final Widget next = !hasSeenOnboarding
        ? const OnboardingScreen()
        : signedIn
        ? const HomeScreen()
        : const AuthScreen(); // seen onboarding before: go straight to sign-in

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OceanScaffold(
      showBack: false,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 150, glow: AppTheme.lightCyan),
                const SizedBox(height: 24),
                const BrandTitle(fontSize: 46),
                const SizedBox(height: 10),
                Text(
                  'Smart water tracking',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.lightCyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
