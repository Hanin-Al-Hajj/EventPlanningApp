import 'package:event_planner/screens/Tabs_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const EventFlowApp());
}

class EventFlowApp extends StatelessWidget {
  const EventFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TabsScreen());
  }
}
