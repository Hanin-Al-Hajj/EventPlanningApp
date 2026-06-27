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
    switch (_normalizedStatus) {
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
      case 'done':
        return AppColors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'pending':
        return AppColors.coral;
      case 'accepted':
        return Colors.teal;
      case 'planning':
        return AppColors.darkpink;
      case 'declined':
        return AppColors.burgundy;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (_normalizedStatus) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
      case 'done':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'accepted':
        return 'Accepted';
      case 'planning':
        return 'Planning';
      case 'declined':
        return 'declined';
      default:
        return event.status;
    }
  }

  String get _normalizedStatus {
    return event.status
        .toLowerCase()
        .trim()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  String getEventBackgroundImage() {
    switch (event.eventType) {
      case 'Wedding':
        return 'assets/images/wedding.jpeg';
      case 'Birthday':
        return 'assets/images/birthday.jpg';
      case 'Corporate':
        return 'assets/images/corporate.jpeg';
      case 'Anniversary':
        return 'assets/images/anniversary.jpeg';
      case 'Gender Reveal':
        return 'assets/images/gender.jpeg';
      case 'Graduation':
        return 'assets/images/grad.jpg';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final backgroundImage = getEventBackgroundImage();
    final plannerName = event.plannerName?.trim();
    final plannerLabel = plannerName?.isNotEmpty == true
        ? plannerName!
        : 'Not selected';

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (onTap != null) onTap!();
          return false;
        }
        return true;
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

          if (onEventUpdated != null) {
            await onEventUpdated!(event);
          }
        },
        child: Container(
          height: 146,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            image: backgroundImage.isEmpty
                ? null
                : DecorationImage(
                    image: AssetImage(backgroundImage),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.45),
                      BlendMode.darken,
                    ),
                  ),
            color: backgroundImage.isEmpty ? AppColors.burgundy : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withOpacity(0.8)),
                    ),
                    child: Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('MMM dd, yyyy').format(event.date)} - ${event.location}',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Planner: $plannerLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${event.guests} Guests',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '\$${event.budget.toStringAsFixed(0)} Budget',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
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
