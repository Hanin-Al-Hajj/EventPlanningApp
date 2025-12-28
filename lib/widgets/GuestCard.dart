import 'package:event_planner/models/Guest.dart';
import 'package:flutter/material.dart';

class Guestcard extends StatelessWidget {
  final Guest guest;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const Guestcard({
    super.key,
    required this.guest,
    required this.onDelete,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (guest.status) {
      case GuestStatus.accepted:
        return const Color(0xFF545A3B);
      case GuestStatus.declined:
        return Colors.grey.shade800;
      case GuestStatus.pending:
        return Colors.orange.shade700;
    }
  }

  String _getStatusText() {
    switch (guest.status) {
      case GuestStatus.accepted:
        return 'Accepted';
      case GuestStatus.declined:
        return 'Declined';
      case GuestStatus.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(guest.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Guest'),
            content: Text('Remove ${guest.name} from guest list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF151910),
                      ),
                    ),
                    const SizedBox(height: 4),

                    if (guest.tableNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        guest.tableNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getStatusText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
