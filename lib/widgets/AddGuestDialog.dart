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
  late TextEditingController _plusOnesController;

  late GuestStatus _selectedStatus;
  String? _nameError;
  String? _phoneError;
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.guest?.name ?? '');
    _emailContoller = TextEditingController(text: widget.guest?.email ?? '');
    _tableController = TextEditingController(
      text: widget.guest?.tableNumber ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.guest != null ? widget.guest!.phoneNumber : '',
    );
    _plusOnesController = TextEditingController(
      text: widget.guest?.plusOnes != null
          ? widget.guest!.plusOnes.toString()
          : '0',
    );

    _selectedStatus = widget.guest?.status ?? GuestStatus.pending;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailContoller.dispose();
    _tableController.dispose();
    _phoneController.dispose();
    _plusOnesController.dispose();

    super.dispose();
  }

  void _save() {
    setState(() {
      _nameError = null;
      _phoneError = null;
    });

    bool hasError = false;

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Please enter a name';
      });
      hasError = true;
    }
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _phoneError = 'Please enter a phone number';
      });
      hasError = true;
    }
    if (hasError) {
      return;
    }
    final guest = Guest(
      id: widget.guest?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      status: _selectedStatus,

      email: _emailContoller.text.trim().isEmpty
          ? null
          : _emailContoller.text.trim(),

      tableNumber: _tableController.text.trim().isEmpty
          ? null
          : _tableController.text.trim(),

      phoneNumber: _phoneController.text.trim(),

      plusOnes: int.tryParse(_plusOnesController.text.trim()) ?? 0,
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
              decoration: InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
                errorText: _nameError,
              ),
              onChanged: (value) {
                if (_nameError != null) {
                  setState(() {
                    _nameError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailContoller,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                errorText: _phoneError,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                if (_phoneError != null) {
                  setState(() {
                    _phoneError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tableController,
              decoration: const InputDecoration(
                labelText: 'Table Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _plusOnesController,
              decoration: const InputDecoration(
                labelText: 'Plus Ones',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
