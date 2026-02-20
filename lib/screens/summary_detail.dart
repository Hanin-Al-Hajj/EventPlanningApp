import 'package:flutter/material.dart';

class SummaryDetail extends StatelessWidget {
  const SummaryDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: const Center(child: Text('this is the Summary Detailed Screen')),
    );
  }
}
