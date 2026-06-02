import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  // API data
  List<Map<String, dynamic>> _eventTypes = [];
  List<Map<String, dynamic>> _planners = [];
  bool _isLoadingData = true;

  // Selected values
  int? _selectedEventTypeId;
  String? _selectedEventTypeName;
  int? _selectedPlannerId;
  String? _selectedPlannerName;
  DateTime? _selectedDate;
  bool _isSaving = false;
  bool get isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadCreateData();

    if (widget.eventToEdit != null) {
      _eventNameController.text = widget.eventToEdit!.title;
      _guestsController.text = widget.eventToEdit!.guests.toString();
      _budgetController.text = widget.eventToEdit!.budget.toString();
      _locationController.text = widget.eventToEdit!.location;
      _selectedDate = widget.eventToEdit!.date;
      _descriptionController.text = widget.eventToEdit!.description ?? '';
    }
  }

  // Load event types and planners from API
  Future<void> _loadCreateData() async {
    try {
      final result = await ApiService.getCreateData();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        setState(() {
          _eventTypes = List<Map<String, dynamic>>.from(
            data['event_types'] ?? [],
          );
          _planners = List<Map<String, dynamic>>.from(data['planners'] ?? []);

          // Event type matching
          // Event type matching
          if (isEditing && _selectedEventTypeId == null) {
            final matchingType = _eventTypes.where(
              (type) => type['name'] == widget.eventToEdit!.eventType,
            );
            if (matchingType.isNotEmpty) {
              _selectedEventTypeId = matchingType.first['id'] as int;
              _selectedEventTypeName = matchingType.first['name'];
            }
          }

          // Planner matching — MUST happen here after _planners is populated
          if (isEditing && widget.eventToEdit!.plannerId != null) {
            final matchingPlanner = _planners.where(
              (p) => p['id'] == widget.eventToEdit!.plannerId,
            );
            if (matchingPlanner.isNotEmpty) {
              _selectedPlannerId = matchingPlanner.first['id'] as int;
              _selectedPlannerName = matchingPlanner.first['name'];
            }
          }

          _isLoadingData = false;
        });
      } else {
        setState(() {
          _eventTypes = [];
          _planners = [];
          _isLoadingData = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load form data'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _eventTypes = [];
        _planners = [];
        _isLoadingData = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load form data: $e')));
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _guestsController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(String label, Function(DateTime) onPicked) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    if (picked != null) onPicked(picked);
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
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
                  value == null
                      ? 'Select date'
                      : DateFormat('MMM dd, yyyy').format(value),
                  style: const TextStyle(
                    color: AppColors.darkpink,
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
      ],
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEventTypeId == null) {
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

    setState(() => _isSaving = true);

    try {
      final eventData = {
        'event_type_id': _selectedEventTypeId,
        'name': _eventNameController.text,
        'start_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'location_text': _locationController.text.isEmpty
            ? 'TBD'
            : _locationController.text,
        'guest_estimate': int.parse(_guestsController.text),
        'budget_overall': double.parse(_budgetController.text),
        'description': _descriptionController.text,

        if (_selectedPlannerId != null) 'planner_id': _selectedPlannerId,
      };

      final result = isEditing
          ? await ApiService.updateEvent(widget.eventToEdit!.id, eventData)
          : await ApiService.createEvent(eventData);

      setState(() => _isSaving = false);

      if (!mounted) return;

      if (result['success'] == true) {
        // Convert API response back to local Event model
        final data = result['data'];
        final newEvent = Event(
          id: data['id'].toString(),
          title: data['name'],
          date: DateTime.parse(data['start_date']),
          location: data['location_text'] ?? 'TBD',
          guests: int.tryParse(data['guest_estimate'].toString()) ?? 0,
          budget: double.tryParse(data['budget_overall'].toString()) ?? 0.0,
          progress: 0.0,
          status: data['status'] ?? 'Planning',
          eventType: _selectedEventTypeName,
          description: data['description'],
          plannerId: data['planner_id'],
          plannerName: data['planner_name'],
        );
        Navigator.pop(context, newEvent);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create event'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 20,
                      color: AppColors.darkpink,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  isEditing ? 'Edit Event' : 'Create Event',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.burgundy,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),

              const SizedBox(width: 52),
            ],
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // EVENT TYPE DROPDOWN (from API)
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
                        child: DropdownButtonFormField<int>(
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
                          value: _selectedEventTypeId,
                          items: _eventTypes.map((type) {
                            return DropdownMenuItem<int>(
                              value: type['id'] as int,
                              child: Text(
                                type['name'],
                                style: const TextStyle(
                                  color: AppColors.burgundy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedEventTypeId = value;
                              _selectedEventTypeName = _eventTypes.firstWhere(
                                (t) => t['id'] == value,
                              )['name'];
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // EVENT NAME
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
                          style: const TextStyle(color: AppColors.darkpink),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an event name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // EVENT DATE
                      _dateField('Event Date', _selectedDate, () {
                        _selectDate('Event Date', (picked) {
                          setState(() => _selectedDate = picked);
                        });
                      }),

                      // LOCATION
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
                          style: const TextStyle(color: AppColors.darkpink),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // NUMBER OF GUESTS
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
                          style: const TextStyle(color: AppColors.darkpink),
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

                      // BUDGET
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
                          style: const TextStyle(color: AppColors.darkpink),
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
                      const SizedBox(height: 20),

                      // PLANNER SELECTOR (Optional)
                      const Text(
                        'Choose a Planner (Optional)',
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
                        child: DropdownButtonFormField<int>(
                          iconEnabledColor: AppColors.darkpink,
                          hint: const Text(
                            'Select a planner (optional)',
                            style: TextStyle(color: AppColors.darkpink),
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                          value: _selectedPlannerId,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text(
                                'No planner',
                                style: TextStyle(color: AppColors.burgundy),
                              ),
                            ),
                            ..._planners.map((planner) {
                              return DropdownMenuItem<int>(
                                value: planner['id'] as int,
                                child: Text(
                                  planner['name'],
                                  style: const TextStyle(
                                    color: AppColors.burgundy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPlannerId = value;
                              _selectedPlannerName = value == null
                                  ? null
                                  : _planners.firstWhere(
                                      (p) => p['id'] == value,
                                    )['name'];
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // DESCRIPTION
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
                            hintText:
                                'Add any notes or details about the event...',
                            hintStyle: TextStyle(color: AppColors.darkpink),
                          ),
                          style: const TextStyle(color: AppColors.darkpink),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkpink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEditing ? 'Update Event' : 'Save Event',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
