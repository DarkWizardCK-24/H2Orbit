import 'package:flutter/material.dart';
import 'package:h2orbit/screens/auth_screen.dart';
import 'package:h2orbit/widgets/animated_button.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      animation: 'assets/animations/water2.json',
      title: 'Stay hydrated',
      description:
          'Log every glass in one tap and build a daily hydration habit.',
      gradient: LinearGradient(
        colors: [Color(0xFF0A1828), Color(0xFF178582)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    _OnboardingPage(
      animation: 'assets/animations/brain.json',
      title: 'Smart tips',
      description:
          'Suggestions based on the time of day, your progress and the weather.',
      gradient: LinearGradient(
        colors: [Color(0xFF178582), Color(0xFF1565C0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    _OnboardingPage(
      animation: 'assets/animations/bell.json',
      title: 'Gentle reminders',
      description: 'Choose when to be nudged, and celebrate your streaks.',
      gradient: LinearGradient(
        colors: [Color(0xFF1565C0), Color(0xFF4DD0E1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
  ];

  bool get _isLast => _currentPage == _pages.length - 1;

  Future<void> _complete() async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _PageView(page: _pages[index]),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _pages.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 8,
                                width: _currentPage == i ? 26 : 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == i
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        if (_isLast)
                          AnimatedButton(
                            text: 'Get started',
                            onPressed: _complete,
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _complete,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                ),
                                child: const Text('Skip'),
                              ),
                              AnimatedButton(
                                text: 'Next',
                                width: 130,
                                onPressed: () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final _OnboardingPage page;

  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: page.gradient),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Lottie.asset(
                    page.animation,
                    width: 270,
                    height: 270,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 36),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.55,
                    ),
                  ),
                  const Spacer(flex: 3),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String animation;
  final String title;
  final String description;
  final Gradient gradient;

  const _OnboardingPage({
    required this.animation,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
