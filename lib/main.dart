import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const VendorPortalApp());
}

class VendorPortalApp extends StatelessWidget {
  const VendorPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vendor Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B7C5C)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
