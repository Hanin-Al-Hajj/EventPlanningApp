import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/screens/vendors_screen.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/screens/planner/task_screen.dart';

class Plannertabsscreen extends StatefulWidget {
  final Event event;

  const Plannertabsscreen({super.key, required this.event});

  @override
  State<Plannertabsscreen> createState() => _PlannertabsscreenState();
}

class _PlannertabsscreenState extends State<Plannertabsscreen> {
  int _selectedIndex = 0;
  final Set<int> _openedTabs = {0};

  int get _eventId => int.tryParse(widget.event.id) ?? 0;

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
      _openedTabs.add(index);
    });
  }

  Widget _buildPage(int index) {
    if (!_openedTabs.contains(index)) {
      return const SizedBox.shrink();
    }

    switch (index) {
      case 0:
        return PlannerTaskScreen(
          eventId: _eventId,
          eventName: widget.event.title,
        );
      case 1:
        return VendorsScreen(eventId: widget.event.id);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(2, _buildPage),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.listCheck, size: 20),
            label: 'Checklist',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.shop, size: 20),
            label: 'Vendors',
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
