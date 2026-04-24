import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:intl/intl.dart';
import 'package:event_planner/constants/app_colors.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key, this.eventToEdit});

  final Event? eventToEdit;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _guestsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedEventType;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      _eventNameController.text = widget.eventToEdit!.title;
      _guestsController.text = widget.eventToEdit!.guests.toString();
      _budgetController.text = widget.eventToEdit!.budget.toString();
      _locationController.text = widget.eventToEdit!.location;
      _selectedDate = widget.eventToEdit!.date;
      _selectedEventType = widget.eventToEdit!.eventType;
      _descriptionController.text = widget.eventToEdit!.description ?? '';
    }
  }

  final List<String> _eventTypes = [
    'Wedding',
    'Birthday',
    'Corporate',
    'Anniversary',
    'Gender Reveal',
    'Graduation',
  ];

  @override
  void dispose() {
    _eventNameController.dispose();
    _guestsController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.burgundy,
              onPrimary: Colors.white,
              onSurface: Color(0xFF151910),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      if (_selectedEventType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an event type')),
        );
        return;
      }
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an event date')),
        );
        return;
      }

      final newEvent = Event(
        id:
            widget.eventToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _eventNameController.text,
        date: _selectedDate!,
        location: _locationController.text.isEmpty
            ? 'TBD'
            : _locationController.text,
        guests: int.parse(_guestsController.text),
        budget: double.parse(_budgetController.text),
        progress: widget.eventToEdit?.progress ?? 0.0,
        status: widget.eventToEdit?.status ?? 'Planning',
        eventType: _selectedEventType,
      );

      Navigator.pop(context, newEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.eventToEdit != null;
    var column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // event type matra7 ldropdawn
        const Text(
          'Event Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),

          child: DropdownButtonFormField<String>(
            iconEnabledColor: AppColors.darkpink,
            hint: const Text(
              'Select event type',
              style: TextStyle(color: AppColors.darkpink),
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
            ),

            value: _selectedEventType,
            items: _eventTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type,
                  style: TextStyle(
                    color: AppColors.burgundy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedEventType = value;
              });
            },
          ),
        ),
        const SizedBox(height: 20),

        // event name luser bina2e
        const Text(
          'Event Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: _eventNameController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintText: 'Enter event name',
              hintStyle: TextStyle(color: AppColors.darkpink),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an event name';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),

        // event date
        const Text(
          'Event Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? 'Select event date'
                      : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                  style: TextStyle(
                    color: _selectedDate == null
                        ? AppColors.darkpink
                        : AppColors.darkpink,
                    fontSize: 16,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.burgundy,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // location
        const Text(
          'Location (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintText: 'Enter location',
              hintStyle: TextStyle(color: AppColors.darkpink),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // nb of guests
        const Text(
          'Number of Guests',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: _guestsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintText: 'Enter number of guests',
              hintStyle: TextStyle(color: AppColors.darkpink),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter number of guests';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),

        // budget
        const Text(
          'Budget',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintText: 'Enter budget',
              hintStyle: TextStyle(color: AppColors.darkpink),
              prefixText: '\$ ',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a budget';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Description (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),

              border: InputBorder.none,
              hintText: 'Add any notes or details about the event...',
              hintStyle: TextStyle(color: AppColors.darkpink),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // matra7 lsave button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saveEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkpink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              isEditing ? 'Update Event' : 'Save Event',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.burgundy,
        titleSpacing: 40,
        title: Text(
          isEditing ? 'Edit Event' : 'Create New Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(key: _formKey, child: column),
        ),
      ),
    );
  }
}
