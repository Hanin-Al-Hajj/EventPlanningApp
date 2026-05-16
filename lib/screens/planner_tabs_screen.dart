import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/screens/budget_tracker_screen.dart';
import 'package:event_planner/screens/vendors_screen.dart';
import 'package:event_planner/screens/messages_screen.dart';
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
      const VendorsScreen(),
      BudgetTrackerScreen(event: widget.event, onBudgetChanged: () async {}),
      const MessagesScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.clipboardList),
            label: 'Checklist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake),
            label: 'Vendors',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.moneyBillWave),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: 'Messages',
          ),
        ],
        onTap: _selectPage,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.darkpink,
        unselectedItemColor: AppColors.darkpink,
        backgroundColor: AppColors.cream,
      ),
    );
  }
}
