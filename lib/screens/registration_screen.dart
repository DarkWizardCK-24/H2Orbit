import 'package:flutter/material.dart';
import 'package:h2orbit/domain/hydration_math.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/screens/home_screen.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/services/firebase_service.dart';
import 'package:h2orbit/utils/constants.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:h2orbit/utils/snackbar.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/animated_button.dart';
import 'package:h2orbit/widgets/glass_container.dart';
import 'package:h2orbit/widgets/ocean_scaffold.dart';
import 'package:h2orbit/widgets/scroll_picker.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const int _steps = 3;

  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _step = 0;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  DateTime _birthDate = DateTime(DateTime.now().year - 25, 1, 1);
  String _gender = 'Male';
  int _height = 170;
  int _weight = 70;
  int _dailyTarget = AppConstants.defaultWaterTarget;

  /// Bumped to rebuild the goal wheel when "Use" jumps it to the suggestion.
  int _targetWheelResets = 0;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int get _recommendedGlasses => HydrationMath.recommendedGlasses(
    weightKg: _weight,
    age: UserModel.calculateAge(_birthDate),
    gender: _gender,
  );

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_step == 0 && !(_formKey.currentState?.validate() ?? false)) return;
    if (_step < _steps - 1) {
      _goToStep(_step + 1);
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    if (_saving) return;
    setState(() => _saving = true);

    final auth = context.read<AuthService>();
    final repo = context.read<HydrationRepository>();
    String? uid;
    try {
      uid = await auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await repo.saveUser(
        UserModel(
          uid: uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          dateOfBirth: _birthDate,
          age: UserModel.calculateAge(_birthDate),
          gender: _gender,
          heightCm: _height,
          weightKg: _weight,
          dailyGlassTarget: _dailyTarget,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message, isError: true);
      // A taken email or weak password is fixed on the first step.
      if (e.code == 'email-already-in-use' ||
          e.code == 'weak-password' ||
          e.code == 'invalid-email') {
        _goToStep(0);
      }
    } catch (e) {
      // The account exists but the profile could not be saved. Remove the
      // account so the user can simply try again instead of being stuck.
      if (uid != null) await auth.discardCurrentAccount();
      if (!mounted) return;
      showAppSnack(
        context,
        "We couldn't finish setting up your profile. Please try again.",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToStep(_step - 1);
      },
      child: OceanScaffold(
        title: 'Create account',
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / _steps,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Step ${_step + 1} of $_steps',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_accountStep(), _aboutStep(), _goalStep()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepScaffold({
    required String title,
    required String subtitle,
    required Widget card,
    required Widget button,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 24),
          card,
          const SizedBox(height: 28),
          button,
        ],
      ),
    );
  }

  Widget _accountStep() {
    return _stepScaffold(
      title: 'Your account',
      subtitle: "Let's get to know you.",
      card: GlassContainer(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Enter your name'),
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: Validators.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                validator: Validators.password,
                onFieldSubmitted: (_) => _next(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least 6 characters',
                  helperStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      button: AnimatedButton(text: 'Continue', onPressed: _next),
    );
  }

  Widget _aboutStep() {
    return _stepScaffold(
      title: 'About you',
      subtitle: 'Used to suggest a daily water goal that fits you.',
      card: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _birthDate = date);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined, color: AppTheme.lightCyan),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date of birth',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            '${Fmt.date(_birthDate)}  ·  '
                            '${UserModel.calculateAge(_birthDate)} years',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 28),
            Text(
              'Gender',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'Male', label: Text('Male')),
                  ButtonSegment(value: 'Female', label: Text('Female')),
                  ButtonSegment(value: 'Other', label: Text('Other')),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
                style: SegmentedButton.styleFrom(
                  foregroundColor: Colors.white,
                  selectedBackgroundColor: AppTheme.lightCyan,
                  selectedForegroundColor: AppTheme.darkBackground,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                ),
              ),
            ),
          ],
        ),
      ),
      button: AnimatedButton(text: 'Continue', onPressed: _next),
    );
  }

  Widget _goalStep() {
    final recommended = _recommendedGlasses;
    return _stepScaffold(
      title: 'Your goal',
      subtitle: 'You can change these any time in your profile.',
      card: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PickerBlock(
              label: 'Height (cm)',
              child: ScrollPicker(
                initialValue: _height,
                minValue: 120,
                maxValue: 220,
                onChanged: (v) => setState(() => _height = v),
              ),
            ),
            const SizedBox(height: 20),
            _PickerBlock(
              label: 'Weight (kg)',
              child: ScrollPicker(
                initialValue: _weight,
                minValue: 30,
                maxValue: 200,
                onChanged: (v) => setState(() => _weight = v),
              ),
            ),
            const SizedBox(height: 20),
            _PickerBlock(
              label: 'Daily goal (glasses of 250 ml)',
              child: ScrollPicker(
                key: ValueKey('target_$_targetWheelResets'),
                initialValue: _dailyTarget,
                minValue: AppConstants.minGlassTarget,
                maxValue: AppConstants.maxGlassTarget,
                onChanged: (v) => _dailyTarget = v,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_rounded,
                    color: AppTheme.lightCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Suggested for you: $recommended glasses '
                      '(${Fmt.ml(recommended * AppConstants.mlPerGlass)})',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _dailyTarget == recommended
                        ? null
                        : () => setState(() {
                            _dailyTarget = recommended;
                            _targetWheelResets++;
                          }),
                    child: const Text('Use'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      button: AnimatedButton(
        text: 'Create account',
        loading: _saving,
        onPressed: _next,
      ),
    );
  }
}

class _PickerBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _PickerBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
