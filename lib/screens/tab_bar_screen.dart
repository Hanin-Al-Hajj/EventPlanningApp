import 'package:event_planner/models/event.dart';
import 'package:event_planner/screens/Messages_screen.dart';
import 'package:event_planner/screens/profile_screen.dart';
import 'package:event_planner/screens/summary_detail.dart';
import 'package:event_planner/screens/home_screen.dart';
import 'package:event_planner/screens/system_screen.dart';
import 'package:flutter/material.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedIndex = 0;

  List<Event> registeredEvents = [];

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
    Widget activePage = HomeScreen(
      onAddEvent: _addNewEvent,
      onDeleteEvent: _deleteEvent,
      onUpdateEvent: _updateEvent,
      registeredEvents: registeredEvents,
    );

    if (_selectedIndex == 1) {
      activePage = const SummaryDetail();
    } else if (_selectedIndex == 2) {
      activePage = const MessagesScreen();
    } else if (_selectedIndex == 3) {
      activePage = const SystemScreen();
    } else if (_selectedIndex == 4) {
      activePage = const ProfileScreen();
    }

    return Scaffold(
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.cottage), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_rounded),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'System',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
        onTap: _selectPage,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 72, 78, 53),
        unselectedItemColor: const Color.fromARGB(255, 162, 165, 162),
        backgroundColor: const Color.fromARGB(255, 250, 247, 234),
      ),
    );
  }
}
