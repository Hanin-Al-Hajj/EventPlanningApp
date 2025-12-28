import 'package:event_planner/models/Guest.dart';
import 'package:flutter/material.dart';

class AddGuestDialog extends StatefulWidget {
  const AddGuestDialog({super.key, this.guest, required this.onAdd});
  final Guest? guest;
  final Function(Guest) onAdd;
  @override
  State<AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<AddGuestDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailContoller;
  late TextEditingController _tableController;
  late TextEditingController _phoneController;
  late GuestStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.guest?.name ?? '');
    _emailContoller = TextEditingController(text: widget.guest?.email ?? '');
    _tableController = TextEditingController(
      text: widget.guest?.tableNumber ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.guest?.phoneNumber ?? '',
    );
    _selectedStatus = widget.guest?.status ?? GuestStatus.pending;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailContoller.dispose();
    _tableController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name and phonenumber')),
      );
      return;
    }
    final guest = Guest(
      id: widget.guest?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),

      name: _nameController.text,
      email: _emailContoller.text.isEmpty ? null : _emailContoller.text,
      tableNumber: _tableController.text,
      status: _selectedStatus,
      phoneNumber: _phoneController.text,
      plusOnes: null,
    );
    widget.onAdd(guest);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.guest == null ? 'Add Guest' : 'Edit Guest'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailContoller,
              decoration: const InputDecoration(
                labelText: 'Email ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tableController,
              decoration: const InputDecoration(
                labelText: 'Table Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF545A3B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
