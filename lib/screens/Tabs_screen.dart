import 'package:event_planner/db/event_storage.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/screens/Events_screen.dart';
import 'package:event_planner/screens/Messages_screen.dart';
import 'package:event_planner/screens/Reports_screen.dart';
import 'package:event_planner/screens/home_screen.dart';
import 'package:flutter/material.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedIndex = 0;

  bool _isloading = true;
  List<Event> registeredEvents = [];
  @override
  void initState() {
    super.initState();
    _LoadFromDataBase();
  }

  Future<void> _LoadFromDataBase() async {
    setState(() {
      _isloading = true;
    });
    try {
      final events = await loadEvents();
      setState(() {
        registeredEvents = events;
        _isloading = false;
      });
    } catch (e) {
      print('Error loading events:$e');
      setState(() {
        _isloading = false;
      });
    }
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  
  void _addNewEvent(Event event) {
    setState(() {
      registeredEvents.add(event);
      
    });
    insertEvent(event);
  }

  
  void _deleteEvent(Event event) {
    setState(() {
      registeredEvents.remove(event);
      
    });
    deleteEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    if (_isloading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF586041)),
        ),
      );
    }

    //go to witch screen based on taped index
    Widget activePage = HomeScreen(
      registeredEvents: registeredEvents,
      onAddEvent: _addNewEvent,
      onDeleteEvent: _deleteEvent,
    );

    if (_selectedIndex == 1) {
      activePage = EventsScreen(
        registeredEvents: registeredEvents,
        onDeleteEvent: _deleteEvent,
      );
    } else if (_selectedIndex == 2) {
      activePage = const ReportsScreen();
    } else if (_selectedIndex == 3) {
      activePage = const MessagesScreen();
    }

    return Scaffold(
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        ],
        onTap: _selectPage,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF545A3B),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
    );
  }
}
