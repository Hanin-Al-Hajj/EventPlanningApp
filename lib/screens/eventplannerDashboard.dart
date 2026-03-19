import 'package:flutter/material.dart';

class Eventplannerdashboard extends StatelessWidget {
  const Eventplannerdashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('this is the Event Planner Dashboard')),
    );
  }
}
