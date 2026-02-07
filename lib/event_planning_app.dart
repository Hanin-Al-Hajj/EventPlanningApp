import "package:event_planner/screens/home_screen.dart";
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';

class EventPlanningApp extends StatefulWidget {
  const EventPlanningApp({super.key});

  @override
  State<EventPlanningApp> createState() => _EventPlanningAppState();
}

class _EventPlanningAppState extends State<EventPlanningApp> {
  List<Event> registeredEvents = [];

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventFlow',
      theme: ThemeData(
        primarySwatch: Colors.green,

        scaffoldBackgroundColor: Color(0xFFF0F0D8),
      ),

      //home: const AppDrawer(),
      home: HomeScreen(
        onAddEvent: _addNewEvent,
        onDeleteEvent: _deleteEvent,
        onUpdateEvent: _updateEvent,
        registeredEvents: registeredEvents,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
