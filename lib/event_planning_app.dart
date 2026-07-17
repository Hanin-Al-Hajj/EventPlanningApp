import 'package:event_planner/screens/SignUp_screen.dart';
import 'package:event_planner/screens/login_screen.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';

class EventPlanningApp extends StatefulWidget {
  const EventPlanningApp({super.key});

  @override
  State<EventPlanningApp> createState() => _EventPlanningAppState();
}

class _EventPlanningAppState extends State<EventPlanningApp> {
  List<Event> registeredEvents = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventFlow',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: AppColors.cream,
      ),

      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
