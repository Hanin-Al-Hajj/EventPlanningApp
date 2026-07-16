import 'dart:async';

import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/user_profile.dart';
import 'package:event_planner/repositories/assistant_profile_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AssistantProfileScreen extends StatefulWidget {
  const AssistantProfileScreen({super.key});

  @override
  State<AssistantProfileScreen> createState() => _AssistantProfileScreenState();
}

class _AssistantProfileScreenState extends State<AssistantProfileScreen> {
  final _infoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserProfile? _profile;

  bool _isLoading = true;
  bool _isSavingInfo = false;
  bool _isUpdatingPassword = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    AssistantProfileRepository.profile.addListener(_onProfileChanged);

    final cachedProfile = AssistantProfileRepository.cachedProfile;
    if (cachedProfile != null) {
      _applyProfile(cachedProfile);
      _isLoading = false;
      unawaited(AssistantProfileRepository.refreshInBackground());
    } else {
      unawaited(_loadProfile());
    }
  }

  void _onProfileChanged() {
    if (!mounted) return;

    final cachedProfile = AssistantProfileRepository.cachedProfile;
    if (cachedProfile == null) return;

    setState(() {
      _applyProfile(cachedProfile);
      _isLoading = false;
    });
  }

  void _applyProfile(UserProfile profile) {
    _profile = profile;
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
  }

  Future<void> _loadProfile({bool forceRefresh = true}) async {
    final hasCache = AssistantProfileRepository.hasCache;

    if (!hasCache) {
      setState(() => _isLoading = true);
    }

    try {
      final profile = await AssistantProfileRepository.loadProfile(
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _applyProfile(profile);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load profile: $e', isError: true);
    }
  }

  Future<void> _savePersonalInfo() async {
    if (_infoFormKey.currentState?.validate() != true) return;

    setState(() => _isSavingInfo = true);

    try {
      final updatedProfile = await AssistantProfileRepository.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _applyProfile(updatedProfile);
      });

      _showSnackBar('Profile updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error updating profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingInfo = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordFormKey.currentState?.validate() != true) return;

    setState(() => _isUpdatingPassword = true);

    try {
      await AssistantProfileRepository.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showSnackBar('Password updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error updating password: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.darkpink,
      ),
    );
  }

  @override
  void dispose() {
    AssistantProfileRepository.profile.removeListener(_onProfileChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 20,
                      color: AppColors.darkpink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Assistant Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.darkpink),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _profileCard(profile),
                const SizedBox(height: 20),
                _personalInfoSection(),
                const SizedBox(height: 20),
                _passwordSection(),
              ],
            ),
    );
  }

  Widget _profileCard(UserProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.darkpink,
            child: Text(
              profile?.initials ?? '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name ?? '',
                  style: const TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkpink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile?.roleLabel ?? 'Assistant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile?.memberSinceLabel ?? 'Member since recently',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Form(
        key: _infoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.person_outline, 'Personal Information'),
            _textField(
              label: 'Full Name',
              controller: _nameController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _textField(
              label: 'Email Address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Email is required';
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _textField(
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            _button(
              label: 'Save Changes',
              icon: Icons.save_outlined,
              isLoading: _isSavingInfo,
              onPressed: _isSavingInfo ? null : _savePersonalInfo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.lock_outline, 'Change Password'),
            _passwordField(
              label: 'Current Password',
              controller: _currentPasswordController,
              obscure: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 16),
            _passwordField(
              label: 'New Password',
              controller: _newPasswordController,
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'New password is required';
                if (value.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _passwordField(
              label: 'Confirm New Password',
              controller: _confirmPasswordController,
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please confirm password';
                if (value != _newPasswordController.text)
                  return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _button(
              label: 'Update Password',
              icon: Icons.key_outlined,
              isLoading: _isUpdatingPassword,
              onPressed: _isUpdatingPassword ? null : _updatePassword,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.darkpink),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.burgundy,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.darkpink),
      decoration: _inputDecoration(label),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator:
          validator ??
          (value) =>
              value == null || value.isEmpty ? '$label is required' : null,
      style: const TextStyle(color: AppColors.darkpink),
      decoration: _inputDecoration(label).copyWith(
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.burgundy),
      filled: true,
      fillColor: AppColors.cream.withOpacity(0.55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkpink, width: 1.4),
      ),
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkpink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}
