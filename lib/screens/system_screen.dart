import 'package:flutter/material.dart';
import 'package:event_planner/widgets/app_drawer.dart';

class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = false;
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF586041),
        foregroundColor: Colors.white,
        title: const Text('System Settings'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Notifications Section
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151910),
            ),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive event reminders and updates',
            value: _notificationsEnabled,
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _notificationsEnabled = value;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Get event updates via email',
            value: _emailNotifications,
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _emailNotifications = value;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Appearance Section
          const Text(
            'Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151910),
            ),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            title: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            value: _darkMode,
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _darkMode = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dark mode coming soon!')),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Preferences Section
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151910),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            title: 'Language',
            subtitle: _language,
            icon: Icons.language,
            onTap: () {
              _showLanguageDialog();
            },
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            title: 'Date Format',
            subtitle: 'MM/DD/YYYY',
            icon: Icons.calendar_today,
            onTap: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Date format settings coming soon!'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            title: 'Currency',
            subtitle: 'USD (\$)',
            icon: Icons.attach_money,
            onTap: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Currency settings coming soon!'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Data & Privacy Section
          const Text(
            'Data & Privacy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151910),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            icon: Icons.cleaning_services,
            onTap: () {
              _showClearCacheDialog();
            },
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            icon: Icons.privacy_tip,
            onTap: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy policy coming soon!')),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            title: 'Terms of Service',
            subtitle: 'View terms and conditions',
            icon: Icons.description,
            onTap: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terms of service coming soon!'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // About Section
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151910),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            title: 'App Version',
            subtitle: '1.0.0',
            icon: Icons.info_outline,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF151910),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF586041),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF586041).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF586041), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF151910),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', dialogContext),
            _buildLanguageOption('Spanish', dialogContext),
            _buildLanguageOption('French', dialogContext),
            _buildLanguageOption('Arabic', dialogContext),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, BuildContext dialogContext) {
    return RadioListTile<String>(
      title: Text(language),
      value: language,
      groupValue: _language,
      onChanged: (value) {
        if (mounted) {
          setState(() {
            _language = value!;
          });
          Navigator.pop(dialogContext);
        }
      },
      activeColor: const Color(0xFF586041),
    );
  }

  void _showClearCacheDialog() {
    final scaffoldContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully!')),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
