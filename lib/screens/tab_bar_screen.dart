import 'package:event_planner/models/event.dart';
import 'package:event_planner/screens/Messages_screen_client.dart';
import 'package:event_planner/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      activePage = const MessagesScreenClient();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey(_selectedIndex), child: activePage),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.houseChimneyUser, size: 20),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.solidMessage, size: 20),
            label: 'Messages',
          ),
        ],
        onTap: _selectPage,
        currentIndex: _selectedIndex.clamp(
          0,
          1,
        ), // Ensure index is within bounds
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.darkpink,
        unselectedItemColor: AppColors.darkpink.withOpacity(0.75),
        backgroundColor: AppColors.cream,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}
