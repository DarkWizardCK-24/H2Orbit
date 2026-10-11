import 'package:flutter/material.dart';
import 'package:h2orbit/domain/hydration_math.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/screens/auth_screen.dart';
import 'package:h2orbit/screens/notification_settings_screen.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/services/firebase_service.dart';
import 'package:h2orbit/utils/breakpoints.dart';
import 'package:h2orbit/utils/constants.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:h2orbit/utils/snackbar.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/animated_button.dart';
import 'package:h2orbit/widgets/glass_container.dart';
import 'package:h2orbit/widgets/ocean_scaffold.dart';
import 'package:h2orbit/widgets/side_rail.dart';
import 'package:h2orbit/widgets/scroll_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserModel? _user;
  bool _loading = true;
  bool _editing = false;
  bool _busy = false;
  String? _loadError;

  // Values being edited.
  int _height = 170;
  int _weight = 70;
  int _target = AppConstants.defaultWaterTarget;
  String _gender = 'Male';
  DateTime _birthDate = DateTime(2000);

  /// Bumped to rebuild the wheels when "Apply" jumps one to a new value.
  int _wheelResets = 0;

  String get _userId => context.read<AuthService>().userId!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final user = await context.read<HydrationRepository>().getUser(_userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        if (user != null) _fillEditor(user);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = "We couldn't load your profile.";
      });
    }
  }

  void _fillEditor(UserModel user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _height = user.heightCm;
    _weight = user.weightKg;
    _target = user.dailyGlassTarget;
    _gender = user.gender.isEmpty ? 'Male' : user.gender;
    _birthDate = user.dateOfBirth;
  }

  Future<void> _save() async {
    final user = _user;
    if (user == null || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final updated = user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _birthDate,
        gender: _gender,
        heightCm: _height,
        weightKg: _weight,
        dailyGlassTarget: _target,
      );
      await context.read<HydrationRepository>().saveUser(updated);
      if (!mounted) return;
      setState(() {
        _user = updated;
        _editing = false;
      });
      showAppSnack(context, 'Profile updated');
    } catch (e) {
      if (mounted) {
        showAppSnack(context, "Couldn't save your profile.", isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _cancelEdit() {
    final user = _user;
    setState(() {
      if (user != null) _fillEditor(user);
      _wheelResets++;
      _editing = false;
    });
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    await auth.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null || !mounted) return;

    final auth = context.read<AuthService>();
    final repo = context.read<HydrationRepository>();
    final navigator = Navigator.of(context);
    final uid = _userId;
    setState(() => _busy = true);
    try {
      // Order matters: data can only be deleted while still signed in.
      await auth.reauthenticate(password);
      await repo.deleteAllUserData(uid);
      await auth.deleteAccount();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } on AuthFailure catch (e) {
      if (mounted) showAppSnack(context, e.message, isError: true);
    } catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          "Couldn't delete your account. Please try again.",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OceanScaffold(
      title: 'Profile',
      section: AppSection.profile,
      actions: [
        if (_user != null && !_editing)
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => setState(() => _editing = true),
          ),
      ],
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final user = _user;
    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 56,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              Text(
                _loadError ?? 'No profile found for this account.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    if (Breakpoints.isWide(context)) {
      return Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
          children: [
            _Avatar(user: user),
            const SizedBox(height: 24),
            if (_editing)
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(children: _editSections()),
                ),
              )
            else
              _wideView(user),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _Avatar(user: user),
          const SizedBox(height: 24),
          if (_editing) ..._editSections() else ..._viewSections(user),
        ],
      ),
    );
  }

  // ---------------- view mode ----------------

  /// Wide windows: details on the left, settings and account actions on the
  /// right (the same sections as on a phone).
  Widget _wideView(UserModel user) {
    final sections = _viewSections(user);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sections.sublist(0, 5),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sections.sublist(6),
          ),
        ),
      ],
    );
  }

  List<Widget> _viewSections(UserModel user) {
    final bmi = HydrationMath.bmi(
      weightKg: user.weightKg,
      heightCm: user.heightCm,
    );
    final recommended = HydrationMath.recommendedDailyMl(
      weightKg: user.weightKg,
      age: user.age,
      gender: user.gender,
    );

    return [
      GlassContainer(
        child: Column(
          children: [
            _InfoRow(Icons.person_outline_rounded, 'Name', user.name),
            const SizedBox(height: 16),
            _InfoRow(Icons.email_outlined, 'Email', user.email),
            const SizedBox(height: 16),
            _InfoRow(
              Icons.phone_outlined,
              'Phone',
              user.phone.isEmpty ? 'Not set' : user.phone,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              Icons.cake_outlined,
              'Date of birth',
              '${Fmt.date(user.dateOfBirth)}  ·  ${user.age} years',
            ),
            const SizedBox(height: 16),
            _InfoRow(
              Icons.wc_rounded,
              'Gender',
              user.gender.isEmpty ? 'Not set' : user.gender,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _MetricCard(
              icon: Icons.straighten_rounded,
              label: 'Height',
              value: '${user.heightCm} cm',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: '${user.weightKg} kg',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              icon: Icons.favorite_border_rounded,
              label: 'BMI',
              value: bmi.toStringAsFixed(1),
              caption: HydrationMath.bmiCategory(bmi),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_rounded, color: AppTheme.lightCyan),
                const SizedBox(width: 10),
                const Text(
                  'Daily goal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${user.dailyGlassTarget} glasses',
                  style: const TextStyle(
                    color: AppTheme.lightCyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${Fmt.ml(user.dailyGoalMl)} a day. For your weight and age, '
              'about ${Fmt.ml(recommended)} is typical.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Reminders and achievement alerts',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ),
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.menu_book_rounded,
              title: 'How H2Orbit works',
              subtitle: 'Goals, streaks and tips explained',
              onTap: _showHowItWorks,
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy',
              subtitle: 'What is stored and where',
              onTap: _showPrivacy,
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle: 'Version ${AppConstants.appVersion}',
              onTap: _showAbout,
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      AnimatedButton(
        text: 'Sign out',
        icon: Icons.logout_rounded,
        onPressed: _busy ? null : _signOut,
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy ? null : _deleteAccount,
        style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
        child: const Text('Delete account'),
      ),
    ];
  }

  // ---------------- edit mode ----------------

  List<Widget> _editSections() {
    final age = UserModel.calculateAge(_birthDate);
    final recommended = HydrationMath.recommendedGlasses(
      weightKg: _weight,
      age: age,
      gender: _gender,
    );

    return [
      GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, 'Enter your name'),
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gender',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined, color: AppTheme.lightCyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Born ${Fmt.date(_birthDate)}  ·  $age years',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.edit_calendar_outlined,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Height (cm)'),
            ScrollPicker(
              key: ValueKey('h$_wheelResets'),
              initialValue: _height,
              minValue: 120,
              maxValue: 220,
              onChanged: (v) => _height = v,
            ),
            const SizedBox(height: 20),
            _label('Weight (kg)'),
            ScrollPicker(
              key: ValueKey('w$_wheelResets'),
              initialValue: _weight,
              minValue: 30,
              maxValue: 200,
              onChanged: (v) => setState(() => _weight = v),
            ),
            const SizedBox(height: 20),
            _label('Daily goal (glasses)'),
            ScrollPicker(
              key: ValueKey('t$_wheelResets'),
              initialValue: _target,
              minValue: AppConstants.minGlassTarget,
              maxValue: AppConstants.maxGlassTarget,
              onChanged: (v) => _target = v,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Suggested: $recommended glasses',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _target = recommended;
                    _wheelResets++;
                  }),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      AnimatedButton(text: 'Save changes', loading: _busy, onPressed: _save),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy ? null : _cancelEdit,
        child: const Text('Cancel'),
      ),
    ];
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );

  // ---------------- dialogs ----------------

  void _showInfo(String title, IconData icon, Widget content) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: AppTheme.lightCyan),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(child: content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHowItWorks() => _showInfo(
    'How H2Orbit works',
    Icons.menu_book_rounded,
    const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal: your daily goal is set in glasses of 250 ml. On hot days '
          '(with a weather key configured) a bonus is added automatically.',
        ),
        SizedBox(height: 12),
        Text(
          'Streak: a day counts when you reach your goal. Today does not '
          'break your streak until the day is over.',
        ),
        SizedBox(height: 12),
        Text(
          'Tips: suggestions come from the time of day, your progress, the '
          'weather and your profile.',
        ),
      ],
    ),
  );

  void _showPrivacy() => _showInfo(
    'Privacy',
    Icons.lock_outline_rounded,
    const Text(
      'Your profile and the drinks you log are stored in your account on '
      'Google Firebase. They are not shared with anyone else. Location is '
      "only used, if you allow it, to look up your area's weather. You can "
      'delete your account and all of its data at any time from this screen.',
    ),
  );

  void _showAbout() => _showInfo(
    'About H2Orbit',
    Icons.water_drop_rounded,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'H2Orbit - your smart hydration companion',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text('Version ${AppConstants.appVersion}'),
        const SizedBox(height: 8),
        const Text('Stay hydrated, stay healthy.'),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  final UserModel user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim()[0].toUpperCase();
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.buttonGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightCyan.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          user.name.isEmpty ? 'Your profile' : user.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          user.email,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lightCyan.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.lightCyan, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? caption;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.lightCyan, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            caption ?? label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppTheme.lightCyan.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.lightCyan, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
          SizedBox(width: 12),
          Expanded(child: Text('Delete account')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes your account and every drink you have '
            'logged. It cannot be undone. Enter your password to confirm.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: _obscure,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: _password.text.isEmpty
              ? null
              : () => Navigator.pop(context, _password.text),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
