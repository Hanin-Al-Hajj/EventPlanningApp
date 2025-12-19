import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text('EventFlow', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text('Welcome to EventFlow!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
