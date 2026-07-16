import 'package:event_planner/models/Guest.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';

class AddGuestDialog extends StatefulWidget {
  final Function(Guest) onAdd;

  const AddGuestDialog({super.key, required this.onAdd});

  @override
  State<AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<AddGuestDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _plusOneNameController;
  late TextEditingController _dietaryController;
  late TextEditingController _notesController;

  bool _plusOneAllowed = false;

  String? _nameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _plusOneNameController = TextEditingController();
    _dietaryController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _plusOneNameController.dispose();
    _dietaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      _nameError = null;
      _emailError = null;
    });

    bool hasError = false;

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Please enter a name');
      hasError = true;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter an email');
      hasError = true;
    } else if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Please enter a valid email');
      hasError = true;
    }

    if (hasError) return;

    final guest = Guest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: email,
      phoneNumber: _phoneController.text.trim(),
      status: GuestStatus.pending,
      plusOnes: _plusOneAllowed ? 1 : 0,
      plusOneName: _plusOneAllowed ? _plusOneNameController.text.trim() : null,
      dietaryRestrictions: _dietaryController.text.trim().isEmpty
          ? null
          : _dietaryController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      invitationSent: false,
    );

    widget.onAdd(guest);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      title: const Text(
        'Add Guest',
        style: TextStyle(
          color: AppColors.burgundy,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name *
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name *',
                labelStyle: const TextStyle(color: AppColors.burgundy),
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),

            // Email *
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email *',
                labelStyle: const TextStyle(color: AppColors.burgundy),
                border: const OutlineInputBorder(),
                errorText: _emailError,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: AppColors.burgundy),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Dietary Restrictions
            TextField(
              controller: _dietaryController,
              decoration: const InputDecoration(
                labelText: 'Dietary Restrictions',
                labelStyle: TextStyle(color: AppColors.burgundy),
                border: OutlineInputBorder(),
                hintText: 'e.g., Vegetarian, Vegan, Allergies',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(color: AppColors.burgundy),
                border: OutlineInputBorder(),
                hintText: 'Any special notes...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Plus One Toggle
            SwitchListTile(
              title: const Text(
                'Plus One Allowed',
                style: TextStyle(color: AppColors.burgundy),
              ),
              value: _plusOneAllowed,
              onChanged: (value) {
                setState(() => _plusOneAllowed = value);
                if (!value) _plusOneNameController.clear();
              },
              activeColor: AppColors.darkpink,
            ),

            // Plus One Name — appears right below the switch
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.darkpink),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkpink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Send Invitation'),
        ),
      ],
    );
  }
}
