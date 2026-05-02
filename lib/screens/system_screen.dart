import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_planner/constants/app_colors.dart';

class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _taskReminders = false;
  bool _budgetAlerts = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _smsNotifications = prefs.getBool('sms_notifications') ?? false;
      _taskReminders = prefs.getBool('task_reminders') ?? true;
      _budgetAlerts = prefs.getBool('budget_alerts') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings updated successfully'),
          backgroundColor: AppColors.darkpink,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? 'user@example.com';
  }

  Future<String> _getMemberSince() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString('member_since');
    if (timestamp != null) {
      final date = DateTime.parse(timestamp);
      return '${_monthName(date.month)} ${date.day}, ${date.year}';
    }
    return 'January 1, 2025';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.darkpink,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Manage your preferences and notifications',
              style: TextStyle(color: AppColors.burgundy, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.burgundy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.darkpink,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing ??
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.burgundy,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkpink, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.burgundy,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.darkpink),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Preferences Section
                    _buildSectionHeader(
                      icon: Icons.notifications_outlined,
                      title: 'Notification Preferences',
                    ),
                    _buildSettingToggle(
                      title: 'Email Notifications',
                      subtitle: 'Receive updates and alerts via email',
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() => _emailNotifications = value);
                        _savePreference('email_notifications', value);
                      },
                    ),
                    _buildSettingToggle(
                      title: 'SMS Notifications',
                      subtitle: 'Get text messages for important updates',
                      value: _smsNotifications,
                      onChanged: (value) {
                        setState(() => _smsNotifications = value);
                        _savePreference('sms_notifications', value);
                      },
                    ),
                    _buildSettingToggle(
                      title: 'Task Reminders',
                      subtitle: 'Get notified about upcoming task deadlines',
                      value: _taskReminders,
                      onChanged: (value) {
                        setState(() => _taskReminders = value);
                        _savePreference('task_reminders', value);
                      },
                    ),
                    _buildSettingToggle(
                      title: 'Budget Alerts',
                      subtitle: 'Receive alerts when budget limits are reached',
                      value: _budgetAlerts,
                      onChanged: (value) {
                        setState(() => _budgetAlerts = value);
                        _savePreference('budget_alerts', value);
                      },
                    ),

                    const SizedBox(height: 32),

                    // Account Information Section
                    _buildSectionHeader(
                      icon: Icons.info_outline,
                      title: 'Account Information',
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildInfoItem(
                            label: 'Account Type',
                            value: '',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkpink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: AppColors.darkpink,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Client',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkpink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(color: Colors.grey.shade300),
                          FutureBuilder<String>(
                            future: _getMemberSince(),
                            builder: (context, snapshot) {
                              return _buildInfoItem(
                                label: 'Member Since',
                                value: snapshot.data ?? 'Loading...',
                              );
                            },
                          ),
                          Divider(color: Colors.grey.shade300),
                          _buildInfoItem(
                            label: 'Total Events',
                            value: '0', // TODO: Get from database
                          ),
                          Divider(color: Colors.grey.shade300),
                          _buildInfoItem(
                            label: 'Account Status',
                            value: '',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: AppColors.green,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Logout Section
                    _buildSectionHeader(
                      icon: Icons.logout,
                      title: 'Account Actions',
                    ),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: AppColors.burgundy),
                            ),
                            content: const Text(
                              'Are you sure you want to logout?',
                              style: TextStyle(color: AppColors.burgundy),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: AppColors.burgundy),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkpink,
                                  foregroundColor: Colors.white,
                                  
                                ),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && mounted) {
                          _logout(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.darkpink),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: AppColors.darkpink),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkpink,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Danger Zone Section
                    _buildSectionHeader(
                      icon: Icons.warning_amber_rounded,
                      title: 'Danger Zone',
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Permanently delete your account and all associated data. This action cannot be undone.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Delete Account',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                    content: const Text(
                                      'Account deletion feature coming soon. Please contact support for assistance.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_forever, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Version
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'App Version 1.0',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.burgundy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
