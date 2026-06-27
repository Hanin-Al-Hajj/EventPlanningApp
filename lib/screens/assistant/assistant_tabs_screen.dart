import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/screens/assistant/assistant_task_screen.dart';
import 'package:event_planner/screens/assistant/my_orders_screen.dart';

class AssistantTabsScreen extends StatefulWidget {
  const AssistantTabsScreen({super.key});

  @override
  State<AssistantTabsScreen> createState() => _AssistantTabsScreenState();
}

class _AssistantTabsScreenState extends State<AssistantTabsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget activePage = const AssistantTaskScreen();

    if (_selectedIndex == 1) {
      activePage = const MyOrdersScreen();
    } else if (_selectedIndex == 2) {
      // activePage = const AssistantMessagesScreen();
      activePage = const Center(child: Text('Messages'));
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
        items: [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.listCheck, size: 20),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.clipboardList, size: 20),
            label: 'Orders',
          ),
        ],
        onTap: (index) => setState(() => _selectedIndex = index),
        currentIndex: _selectedIndex,
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
