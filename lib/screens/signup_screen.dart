import 'package:event_planner/screens/eventplannerDashboard.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/db/User_storage.dart';
import 'package:event_planner/screens/tab_bar_screen.dart';

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
  bool show_pass = true;
  String? _selectedRole;
  String? _passwordError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Color.fromARGB(255, 44, 77, 44),
        fontSize: 15,
      ),
      prefixIcon: Icon(icon, color: Color.fromARGB(255, 61, 104, 61), size: 20),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color.fromARGB(255, 36, 58, 36) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Color.fromARGB(255, 36, 58, 36)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2D4A2D).withOpacity(0.3),
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
              color: isSelected ? Colors.white : Color(0xFF4A7C4A),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Color.fromARGB(255, 29, 53, 29),
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

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (password.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters';
      });
      return;
    } else {
      setState(() {
        _passwordError = null;
      });
    }

    setState(() => _isLoading = true);

    final userId = await _userRepo.createUser(
      fullName: fullName,
      email: email,
      password: password,
      role: _selectedRole!,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email already in use. Please try another.'),
        ),
      );
      return;
    }
    if (_selectedRole == 'eventplanner') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Eventplannerdashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TabsScreen()),
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
          color: Color.fromARGB(255, 81, 91, 53).withOpacity(0.4),
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: _roleCard(
                              role: 'eventplanner',
                              label: 'Event Planner',
                              icon: Icons.event_note_rounded,
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
                        style: const TextStyle(color: Color(0xFF1A2E1A)),
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
                        style: const TextStyle(color: Color(0xFF1A2E1A)),
                      ),
                      const SizedBox(height: 16),

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
                        style: const TextStyle(color: Color(0xFF1A2E1A)),

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
                          backgroundColor: const Color.fromARGB(
                            255,
                            36,
                            58,
                            36,
                          ),
                          disabledBackgroundColor: const Color.fromARGB(
                            255,
                            25,
                            46,
                            25,
                          ),
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
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF1A3A1A),
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
