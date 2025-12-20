import 'package:event_planner/event_planning_app.dart';
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
      
      home: EventPlanningApp(),
    );
  }
}
