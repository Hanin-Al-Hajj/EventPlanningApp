import 'package:event_planner/screens/home_screen.dart';
import 'package:flutter/material.dart';

class EventPlanningApp extends StatefulWidget {
  const EventPlanningApp({super.key});

  @override
  State<EventPlanningApp> createState() => _EventPlanningAppState();
}

class _EventPlanningAppState extends State<EventPlanningApp> {
  @override
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventFlow',
      theme: ThemeData(
        primarySwatch: Colors.green,

        scaffoldBackgroundColor: Color(0xFFF0F0D8),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
