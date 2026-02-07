import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:intl/intl.dart';
import 'package:event_planner/screens/event_detail_screen.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onDelete,
    this.onTap,
    this.onEventUpdated, // Add this
  });

  final Event event;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final Function(Event)? onEventUpdated; // Add this

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(event: event),
            ),
          );

          // 🔥 ALWAYS refresh when coming back
          if (onEventUpdated != null) {
            await onEventUpdated!(event);
          }
        },

        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Edit Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF151910),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Edit Button
                  GestureDetector(
                    onTap: () {
                      // Stop propagation to parent GestureDetector
                      if (onTap != null) {
                        onTap!();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF586041),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date and Location
              Text(
                '${DateFormat('MMM dd, yyyy').format(event.date)} • ${event.location}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),

              // Guests and Budget
              Row(
                children: [
                  Text(
                    '${event.guests} Guests',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '\$${event.budget.toStringAsFixed(0)} Budget',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(event.progress * 100).toInt()}% Complete',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: event.progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF586041),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
