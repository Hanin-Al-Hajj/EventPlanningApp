import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:intl/intl.dart';
import 'package:event_planner/screens/guestlist_screen.dart';
import 'package:event_planner/constants/app_colors.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onDelete,
    this.onTap,
    this.onEventUpdated,
  });

  final Event event;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final Function(Event)? onEventUpdated;

  Color _getStatusColor() {
    switch (event.status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'in progress':
        return const Color(0xFFFFA726); // Orange
      case 'planning':
        return const Color(0xFF42A5F5); // Blue
      default:
        return Colors.grey;
    }
  }

  String getEventBackgroundImage() {
    switch (event.eventType) {
      case "Wedding":
        return "assets/images/wedding.jpeg";
      case "Birthday":
        return "assets/images/birthday.jpg";
      case "Corporate":
        return "assets/images/corporate.jpeg";
      case "Anniversary":
        return "assets/images/anniversary.jpeg";
      case "Gender Reveal":
        return "assets/images/gender.jpeg";
      case "Graduation":
        return "assets/images/grad.jpg";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Edit
          if (onTap != null) {
            onTap!();
          }
          return false; // Don't dismiss
        } else {
          // Swipe left - Delete
          return true; // Allow dismiss for delete
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.coral,

          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: AppColors.burgundy, size: 28),
            SizedBox(width: 8),
            Text(
              'Edit',
              style: TextStyle(
                color: AppColors.burgundy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.burgundy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: AppColors.coral,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: AppColors.coral, size: 28),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuestListScreen(eventID: event.id, eventName: event.title),
            ),
          );

          // Refresh when coming back from details screen
          if (onEventUpdated != null) {
            await onEventUpdated!(event);
          }
        },
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            image: DecorationImage(
              image: AssetImage(getEventBackgroundImage()),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.45),
                BlendMode.darken,
              ),
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status Badge
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      event.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date and Location
              Text(
                '${DateFormat('MMM dd, yyyy').format(event.date)} • ${event.location}',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 8),

              // Guests and Budget
              Row(
                children: [
                  Text(
                    '${event.guests} Guests',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '\$${event.budget.toStringAsFixed(0)} Budget',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
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
