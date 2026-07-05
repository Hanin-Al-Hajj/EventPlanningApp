import 'package:event_planner/models/Guest.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';

class GuestCard extends StatelessWidget {
  final Guest guest;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final VoidCallback? onResend;

  const GuestCard({
    super.key,
    required this.guest,
    required this.onDelete,
    required this.onTap,
    this.onResend,
  });

  Color _getStatusColor() {
    switch (guest.status) {
      case GuestStatus.accepted:
        return Colors.green.shade600;
      case GuestStatus.declined:
        return Colors.red.shade600;
      case GuestStatus.pending:
        return Colors.orange.shade600;
    }
  }

  IconData _getStatusIcon() {
    switch (guest.status) {
      case GuestStatus.accepted:
        return Icons.check_circle;
      case GuestStatus.declined:
        return Icons.cancel;
      case GuestStatus.pending:
        return Icons.schedule;
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
          color: AppColors.burgundy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: AppColors.coral,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: AppColors.coral),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cream,
            title: const Text(
              'Delete Guest',
              style: TextStyle(color: AppColors.burgundy),
            ),
            content: Text(
              'Remove ${guest.name} from guest list?',
              style: TextStyle(color: AppColors.burgundy),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.burgundy),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkpink,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Name + Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      guest.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF151910),
                      ),
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 14,
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          guest.status.name[0].toUpperCase() +
                              guest.status.name.substring(1),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Email
              if (guest.email.isNotEmpty) ...[
                _buildInfoRow(Icons.email_outlined, guest.email),
                const SizedBox(height: 6),
              ],

              // Phone
              if (guest.phoneNumber.isNotEmpty) ...[
                _buildInfoRow(Icons.phone_outlined, guest.phoneNumber),
                const SizedBox(height: 6),
              ],

              // Dietary Restrictions
              if (guest.dietaryRestrictions != null &&
                  guest.dietaryRestrictions!.isNotEmpty) ...[
                _buildInfoRow(
                  Icons.restaurant_outlined,
                  guest.dietaryRestrictions!,
                ),
                const SizedBox(height: 6),
              ],

              // Plus One
              if (guest.plusOnes != null && guest.plusOnes! > 0) ...[
                _buildInfoRow(
                  Icons.person_add_outlined,
                  guest.plusOneName != null
                      ? '+1: ${guest.plusOneName}'
                      : '+1 Guest',
                ),
                const SizedBox(height: 6),
              ],

              // Notes
              if (guest.notes != null && guest.notes!.isNotEmpty) ...[
                _buildInfoRow(Icons.note_outlined, guest.notes!, maxLines: 2),
                const SizedBox(height: 6),
              ],

              const SizedBox(height: 8),

              // Bottom Row: Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Invitation Status
                  Row(
                    children: [
                      Icon(
                        guest.invitationSent
                            ? Icons.mark_email_read
                            : Icons.mark_email_unread,
                        size: 14,
                        color: guest.invitationSent
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        guest.invitationSent ? 'Invited' : 'Not invited',
                        style: TextStyle(
                          fontSize: 11,
                          color: guest.invitationSent
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  // Resend Button (only if not sent)
                  if (!guest.invitationSent && onResend != null)
                    TextButton.icon(
                      onPressed: onResend,
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text(
                        'Resend',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkpink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
