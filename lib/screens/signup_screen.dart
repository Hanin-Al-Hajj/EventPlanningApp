import 'package:event_planner/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/db/User_storage.dart';
import 'package:event_planner/screens/tab_bar_screen.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/screens/eventplanner_dashboard.dart';
import 'package:event_planner/screens/assistant/assistant_tabs_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

final _userRepo = User_storage();
bool _isLoading = false;

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool show_pass = true;
  String? _selectedRole;

  String? _passwordError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.burgundy, fontSize: 15),
      prefixIcon: Icon(icon, color: AppColors.coral, size: 20),

      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _roleCard({
    required String role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkpink : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.darkpink : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.darkpink.withOpacity(0.4),

                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : AppColors.darkpink,
            ),

            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.darkpink,

                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password.length < 8) {
      // changed from 6 to 8
      setState(() => _passwordError = 'Password must be at least 8 characters');
      return;
    }

    if (_selectedRole == null) return;

    setState(() => _isLoading = true);

    try {
      // Convert 'eventplanner' to 'planner' for the API
      String apiRole;
      switch (_selectedRole) {
        case 'eventplanner':
          apiRole = 'planner';
          break;
        case 'assistant':
          apiRole = 'assistant';
          break;
        default:
          apiRole = 'client';
      }

      final result = await ApiService.register(
        name: fullName,
        email: email,
        password: password,
        role: apiRole,
        phone: phone,
      );

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result['success'] == true) {
        final role = result['user']['role'];
        if (role == 'planner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EventPlannerDashboard()),
          );
        } else if (role == 'assistant') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AssistantTabsScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TabsScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/mobile.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // ignore: deprecated_member_use
          color: AppColors.coral.withOpacity(0.35),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Sign up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      Row(
                        children: [
                          Expanded(
                            child: _roleCard(
                              role: 'client',
                              label: 'Client',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _roleCard(
                              role: 'eventplanner',
                              label: 'Planner',
                              icon: Icons.event_note_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _roleCard(
                              role: 'assistant',
                              label: 'Assistant',
                              icon: Icons.work_outline,
                            ),
                          ),
                        ],
                      ),

                      if (_selectedRole == null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Please select a role to continue',
                          style: TextStyle(
                            color: Color(0xFFE8F0E8).withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Full Name
                      TextField(
                        controller: _fullNameController,
                        decoration: _inputDecoration(
                          'Full Name',
                          Icons.badge_outlined,
                        ),
                        style: const TextStyle(color: AppColors.burgundy),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          'Email',
                          Icons.email_outlined,
                        ),
                        style: const TextStyle(color: AppColors.burgundy),
                      ),
                      const SizedBox(height: 16),

                      // phone
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          'Phone Number',
                          Icons.phone_outlined,
                        ),
                        style: const TextStyle(color: AppColors.burgundy),
                      ),
                      SizedBox(height: 16),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: show_pass,
                        decoration:
                            _inputDecoration(
                              'Password',
                              Icons.lock_outline_rounded,
                            ).copyWith(
                              errorText: _passwordError,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  show_pass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => show_pass = !show_pass),
                              ),
                            ),
                        style: const TextStyle(color: AppColors.burgundy),

                        onChanged: (value) {
                          if (_passwordError != null && value.length >= 6) {
                            setState(() {
                              _passwordError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 28),

                      // Sign Up Button
                      ElevatedButton(
                        onPressed: (_selectedRole == null || _isLoading)
                            ? null
                            : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkpink,
                          disabledBackgroundColor: AppColors.darkpink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Login Link
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkpink,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
