import 'dart:async';

import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/planner_settings.dart';
import 'package:event_planner/repositories/client_settings_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ClientSetting extends StatefulWidget {
  const ClientSetting({super.key});

  @override
  State<ClientSetting> createState() => _ClientSettingState();
}

class _ClientSettingState extends State<ClientSetting> {
  bool alert = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ClientSettingsRepository.settings.addListener(_onSettingsChanged);

    if (ClientSettingsRepository.hasCache) {
      _applySettings(ClientSettingsRepository.cachedSettings);
      _loading = false;
      unawaited(ClientSettingsRepository.refreshInBackground());
    } else {
      unawaited(_loadSettings());
    }
  }

  @override
  void dispose() {
    ClientSettingsRepository.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;

    setState(() {
      _applySettings(ClientSettingsRepository.cachedSettings);
      _loading = false;
    });
  }

  void _applySettings(PlannerSettings settings) {
    alert = settings.inAppAlerts;
  }

  Future<void> _loadSettings({bool forceRefresh = true}) async {
    final hasCache = ClientSettingsRepository.hasCache;

    if (!hasCache) {
      setState(() => _loading = true);
    }

    try {
      final settings = await ClientSettingsRepository.loadSettings(
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _applySettings(settings);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _toggleAlert(bool value) async {
    final previousValue = alert;
    ClientSettingsRepository.setInAppAlertsLocally(value);

    try {
      await ClientSettingsRepository.updateNotificationSettings(
        inAppAlerts: value,
      );
    } catch (e) {
      ClientSettingsRepository.setInAppAlertsLocally(previousValue);

      if (!mounted) return;
      _showError(e.toString());
    }
  }

  Future<void> _handleLogout() async {
    Navigator.pop(context); // close bottom sheet
    try {
      await ClientSettingsRepository.logout();
      if (!mounted) return;
      ClientSettingsRepository.clear();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  Future<void> _handleDeleteAccount() async {
    Navigator.pop(context); // close bottom sheet
    try {
      await ClientSettingsRepository.deleteAccount();
      if (!mounted) return;
      ClientSettingsRepository.clear();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NOTIFICATIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.burgundy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'In-app alerts',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _loading
                              ? ''
                              : alert
                              ? 'Enabled'
                              : 'Disabled',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: alert ? AppColors.green : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _loading
                      ? const SizedBox(width: 48, height: 28)
                      : Switch(
                          value: alert,
                          onChanged: _toggleAlert,
                          activeColor: Colors.white,
                          activeTrackColor: AppColors.darkpink,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFD8D5CE),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ACCOUNT ACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        builder: (context) => logOut(),
                      );
                    },
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.coral,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.burgundy,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.cream,
                  ),
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        builder: (context) => _deleteDialoge(),
                      );
                    },
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.coral,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.burgundy,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkpink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteDialoge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE0DDD6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Delete Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.burgundy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This will permanently remove your account and all data.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleDeleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Yes, Delete My Account',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBEAEA),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.burgundy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget logOut() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE0DDD6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Log Out',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.burgundy,
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Yes, Log Out',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBEAEA),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.burgundy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
