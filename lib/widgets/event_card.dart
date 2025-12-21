import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onDelete;

  const EventCard({super.key, required this.event, required this.onDelete});

  Color get statusColor {
    switch (event.status) {
      case 'In Progress':
      case 'in progress':
      case 'inProgress':
        return const Color(0xFF545A3B);
      case 'Planning':
      case 'planning':
        return const Color(0xFFFCFFF2);
      case 'Completed':
      case 'completed':
        return const Color(0xFFCFD2C3);
      default:
        return Colors.grey;
    }
  }

  Color get statusTextColor {
    if (event.status == 'In Progress' ||
        event.status == 'in progress' ||
        event.status == 'inProgress') {
      return Colors.white;
    }
    return const Color(0xFF151910);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0D8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.status.toString(),
                    style: TextStyle(fontSize: 12, color: statusTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${event.date.day}/${event.date.month}/${event.date.year} • ${event.location}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${event.guests} Guests',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  '\$${event.budget.toStringAsFixed(0)} Budget',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: event.progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF545A3B),
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(event.progress * 100).toInt()}% Complete',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
