import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/screens/auth_screen.dart';
import 'package:h2orbit/screens/notification_settings_screen.dart';
import 'package:h2orbit/services/auth_service.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/animated_button.dart';
import 'package:h2orbit/widgets/glass_container.dart';
import 'package:h2orbit/widgets/scroll_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  UserModel? currentUser;
  bool isEditing = false;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Editable values
  int selectedHeight = 170;
  int selectedWeight = 70;
  int selectedTarget = 8;
  String selectedGender = 'Male';
  DateTime selectedDate = DateTime.now().subtract(const Duration(days: 7300));

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.exists) {
      setState(() {
        currentUser = UserModel.fromFirestore(doc);
        _nameController.text = currentUser!.name;
        _phoneController.text = currentUser!.phone;
        selectedHeight = currentUser!.heightCm;
        selectedWeight = currentUser!.weightKg;
        selectedTarget = currentUser!.dailyGlassTarget;
        selectedGender = currentUser!.gender;
        selectedDate = currentUser!.dateOfBirth;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => isEditing = false);

    final updatedData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'heightCm': selectedHeight,
      'weightKg': selectedWeight,
      'dailyGlassTarget': selectedTarget,
      'gender': selectedGender,
      'dateOfBirth': Timestamp.fromDate(selectedDate),
      'age': UserModel.calculateAge(selectedDate),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update(updatedData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully! ✓'),
        backgroundColor: AppTheme.oceanBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.lightCyan),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.oceanGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.oceanBlue.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (!isEditing)
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => setState(() => isEditing = true),
                    ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Avatar
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.lightCyan, AppTheme.oceanBlue],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.lightCyan.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          FontAwesomeIcons.user,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Basic Info
                    GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (isEditing)
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Name',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppTheme.lightCyan,
                                  ),
                                ),
                              ),
                            )
                          else
                            _buildInfoRow(
                              FontAwesomeIcons.user,
                              'Name',
                              currentUser!.name,
                            ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            FontAwesomeIcons.envelope,
                            'Email',
                            currentUser!.email,
                          ),
                          const SizedBox(height: 15),
                          if (isEditing)
                            TextField(
                              controller: _phoneController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppTheme.lightCyan,
                                  ),
                                ),
                              ),
                            )
                          else
                            _buildInfoRow(
                              FontAwesomeIcons.phone,
                              'Phone',
                              currentUser!.phone,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Personal Details
                    GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildInfoRow(
                            FontAwesomeIcons.cakeCandles,
                            'Age',
                            '${currentUser!.age} years',
                          ),
                          const SizedBox(height: 15),
                          if (isEditing)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                FontAwesomeIcons.personDress,
                                color: AppTheme.lightCyan,
                                size: 20,
                              ),
                              title: Text(
                                'Gender: $selectedGender',
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                                size: 16,
                              ),
                              onTap: () => _showGenderPicker(),
                            )
                          else
                            _buildInfoRow(
                              FontAwesomeIcons.personDress,
                              'Gender',
                              currentUser!.gender,
                            ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            FontAwesomeIcons.calendar,
                            'Date of Birth',
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Health Metrics
                    if (isEditing)
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Health Metrics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Height (cm)',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            ScrollPicker(
                              initialValue: selectedHeight,
                              minValue: 120,
                              maxValue: 220,
                              onChanged: (v) =>
                                  setState(() => selectedHeight = v),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Weight (kg)',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            ScrollPicker(
                              initialValue: selectedWeight,
                              minValue: 30,
                              maxValue: 200,
                              onChanged: (v) =>
                                  setState(() => selectedWeight = v),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Daily Target (glasses)',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            ScrollPicker(
                              initialValue: selectedTarget,
                              minValue: 4,
                              maxValue: 16,
                              onChanged: (v) =>
                                  setState(() => selectedTarget = v),
                            ),
                          ],
                        ),
                      )
                    else
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Health Metrics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(
                              FontAwesomeIcons.ruler,
                              'Height',
                              '${currentUser!.heightCm} cm',
                            ),
                            const SizedBox(height: 15),
                            _buildInfoRow(
                              FontAwesomeIcons.weightScale,
                              'Weight',
                              '${currentUser!.weightKg} kg',
                            ),
                            const SizedBox(height: 15),
                            _buildInfoRow(
                              FontAwesomeIcons.glassWater,
                              'Daily Target',
                              '${currentUser!.dailyGlassTarget} glasses',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Settings & Preferences (Only shown when not editing)
                    if (!isEditing)
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Settings & Preferences',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Notifications
                            _buildSettingsTile(
                              icon: FontAwesomeIcons.bell,
                              title: 'Notifications',
                              subtitle: 'Manage reminders and alerts',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationSettingsScreen(),
                                  ),
                                );
                              },
                            ),

                            const Divider(color: Colors.white24, height: 24),

                            // Privacy
                            _buildSettingsTile(
                              icon: FontAwesomeIcons.lock,
                              title: 'Privacy',
                              subtitle: 'Data and security settings',
                              onTap: () {
                                _showPrivacyDialog();
                              },
                            ),

                            const Divider(color: Colors.white24, height: 24),

                            // Help & Support
                            _buildSettingsTile(
                              icon: FontAwesomeIcons.circleQuestion,
                              title: 'Help & Support',
                              subtitle: 'Get help and contact us',
                              onTap: () {
                                _showHelpDialog();
                              },
                            ),

                            const Divider(color: Colors.white24, height: 24),

                            // About
                            _buildSettingsTile(
                              icon: FontAwesomeIcons.circleInfo,
                              title: 'About H₂Orbit',
                              subtitle: 'Version 1.0.0',
                              onTap: () {
                                _showAboutDialog();
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    if (isEditing)
                      Column(
                        children: [
                          AnimatedButton(
                            text: 'Save Changes',
                            onPressed: _updateProfile,
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              setState(() => isEditing = false);
                              _loadUserData();
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          AnimatedButton(
                            text: 'Sign Out',
                            onPressed: () async {
                              await AuthService().signOut();
                              if (!mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const AuthScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              _showDeleteAccountDialog();
                            },
                            child: const Text(
                              'Delete Account',
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lightCyan.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.lightCyan, size: 18),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.lightCyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FaIcon(icon, color: AppTheme.lightCyan, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.deepCyan,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Male', 'Female', 'Other'].map((gender) {
              return ListTile(
                title: Text(
                  gender,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: selectedGender == gender
                    ? const Icon(Icons.check, color: AppTheme.lightCyan)
                    : null,
                onTap: () {
                  setState(() => selectedGender = gender);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.lock, color: AppTheme.lightCyan, size: 24),
            SizedBox(width: 12),
            Text('Privacy', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Your data is securely stored and encrypted. We never share your personal information with third parties.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: AppTheme.lightCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(
              FontAwesomeIcons.circleQuestion,
              color: AppTheme.lightCyan,
              size: 24,
            ),
            SizedBox(width: 12),
            Text('Help & Support', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help? Contact us at:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              '📧 support@h2orbit.com',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '🌐 www.h2orbit.com/help',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.lightCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(
              FontAwesomeIcons.droplet,
              color: AppTheme.lightCyan,
              size: 24,
            ),
            SizedBox(width: 12),
            Text('About H₂Orbit', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'H₂Orbit - Your Smart Hydration Companion',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text('Version: 1.0.0', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 8),
            Text(
              'Stay hydrated, stay healthy! 💧',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.lightCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text('Delete Account', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AuthService().deleteAccount();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to delete account. Please try again.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
