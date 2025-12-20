import 'package:event_planner/screens/home_screen.dart';
import 'package:flutter/material.dart';

class NavigationBar extends StatefulWidget {
  const NavigationBar({super.key});

  @override
  State<NavigationBar> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<NavigationBar> {
  int _SelectedIndex = 0;

  final List<Widget> _Screens = [HomeScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _Screens[_SelectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _SelectedIndex,
        onTap: (index) {
          setState(() {
            _SelectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
        ],
      ),
    );
  }
}