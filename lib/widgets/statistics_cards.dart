import 'package:flutter/material.dart';

class Statcard extends StatelessWidget {
  const Statcard({
    super.key,
    required this.count,
    required this.color,
    required this.label,
    required this.textColor,
  });
  final int count;
  final String label;
  final Color color;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }
}
