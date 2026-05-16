import 'package:event_planner/screens/SignUp_screen.dart';
import 'package:event_planner/screens/login_screen.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/screens/planner_tabs_screen.dart';

class EventPlanningApp extends StatefulWidget {
  const EventPlanningApp({super.key});

  @override
  State<EventPlanningApp> createState() => _EventPlanningAppState();
}

class _EventPlanningAppState extends State<EventPlanningApp> {
  List<Event> registeredEvents = [];
  /*
  void _addNewEvent(Event event) {
    setState(() {
      registeredEvents.add(event);
    });
  }

  void _deleteEvent(Event event) {
    setState(() {
      registeredEvents.remove(event);
    });
  }

  void _updateEvent(Event updatedEvent) {
    setState(() {
      final index = registeredEvents.indexWhere((e) => e.id == updatedEvent.id);
      if (index != -1) {
        registeredEvents[index] = updatedEvent;
      }
    });
  }
*/
  final dummyEvent = Event(
    id: '1',
    eventType: 'Wedding',
    title: 'test event',
    guests: 0,
    date: DateTime.now(),
    location: 'beirut',
    budget: 0,
    progress: 0,
    status: 'pending',

    // other required fields
  );
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventFlow',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: AppColors.cream,
      ),
      home: Plannertabsscreen(event: dummyEvent),
      //initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
