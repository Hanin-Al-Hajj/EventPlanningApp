import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/screens/budget_tracker_screen.dart';
import 'package:event_planner/screens/vendors_screen.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/screens/check_list_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Plannertabsscreen extends StatefulWidget {
  final Event event;
  const Plannertabsscreen({super.key, required this.event});

  @override
  State<Plannertabsscreen> createState() => _PlannertabsscreenState();
}

class _PlannertabsscreenState extends State<Plannertabsscreen> {
  int _selectedIndex = 0;

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CheckListScreen(event: widget.event),
      VendorsScreen(eventId: widget.event.id),
      BudgetTrackerScreen(event: widget.event, onBudgetChanged: () async {}),
    ];

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
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.clipboardList, size: 20),
            label: 'Checklist',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.shop, size: 20),
            label: 'Vendors',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.moneyBillWave, size: 20),
            label: 'Budget',
          ),
        ],
        onTap: _selectPage,
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
