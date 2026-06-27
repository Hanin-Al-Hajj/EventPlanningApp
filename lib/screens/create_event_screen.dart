import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/create_event.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

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

  List<EventTypeOption> _eventTypes = [];
  List<PlannerOption> _planners = [];

  int? _selectedEventTypeId;
  String? _selectedEventTypeName;
  int? _selectedPlannerId;
  String? _selectedPlannerName;
  DateTime? _selectedDate;

  bool _isLoadingData = true;
  bool _isSaving = false;

  bool get isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    _fillFormForEditing();
    _loadCreateData();
  }

  void _fillFormForEditing() {
    final event = widget.eventToEdit;
    if (event == null) return;

    _eventNameController.text = event.title;
    _guestsController.text = event.guests.toString();
    _budgetController.text = event.budget.toString();
    _locationController.text = event.location;
    _selectedDate = event.date;
    _descriptionController.text = event.description ?? '';
  }

  Future<void> _loadCreateData() async {
    try {
      final result = await ApiService.getCreateData();
      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        if (data is! Map) {
          _showLoadError('Invalid form data');
          return;
        }

        final createData = CreateEventData.fromJson(
          Map<String, dynamic>.from(data),
        );

        final matchingType = isEditing
            ? createData.eventTypeByName(widget.eventToEdit!.eventType)
            : null;
        final matchingPlanner = isEditing
            ? createData.plannerById(widget.eventToEdit!.plannerId)
            : null;

        setState(() {
          _eventTypes = createData.eventTypes;
          _planners = createData.planners;

          if (matchingType != null) {
            _selectedEventTypeId = matchingType.id;
            _selectedEventTypeName = matchingType.name;
          }

          if (matchingPlanner != null) {
            _selectedPlannerId = matchingPlanner.id;
            _selectedPlannerName = matchingPlanner.name;
          }

          _isLoadingData = false;
        });
      } else {
        _showLoadError(result['message'] ?? 'Failed to load form data');
      }
    } catch (e) {
      if (!mounted) return;
      _showLoadError('Failed to load form data: $e');
    }
  }

  void _showLoadError(String message) {
    setState(() {
      _eventTypes = [];
      _planners = [];
      _isLoadingData = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    final today = DateTime.now();
    final firstDate = isEditing
        ? DateTime(today.year - 5, today.month, today.day)
        : today;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365 * 2)),
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
      final request = CreateEventRequest(
        eventTypeId: _selectedEventTypeId!,
        name: _eventNameController.text,
        startDate: _selectedDate!,
        locationText: _locationController.text,
        guestEstimate: int.parse(_guestsController.text),
        budgetOverall: double.parse(_budgetController.text),
        description: _descriptionController.text,
        plannerId: _selectedPlannerId,
      );

      final result = isEditing
          ? await ApiService.updateEvent(
              widget.eventToEdit!.id,
              request.toJson(),
            )
          : await ApiService.createEvent(request.toJson());

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is! Map) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid saved event data')),
          );
          return;
        }

        final savedEvent = eventFromCreateResponse(
          Map<String, dynamic>.from(data),
          eventTypeName: _selectedEventTypeName,
          plannerId: _selectedPlannerId,
          plannerName: _selectedPlannerName,
        );

        Navigator.pop(context, savedEvent);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to save event')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  EventTypeOption? _eventTypeById(int? id) {
    if (id == null) return null;

    for (final type in _eventTypes) {
      if (type.id == id) return type;
    }
    return null;
  }

  PlannerOption? _plannerById(int? id) {
    if (id == null) return null;

    for (final planner in _planners) {
      if (planner.id == id) return planner;
    }
    return null;
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
                              value: type.id,
                              child: Text(
                                type.name,
                                style: const TextStyle(
                                  color: AppColors.burgundy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            final selectedType = _eventTypeById(value);

                            setState(() {
                              _selectedEventTypeId = selectedType?.id;
                              _selectedEventTypeName = selectedType?.name;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      _dateField('Event Date', _selectedDate, () {
                        _selectDate('Event Date', (picked) {
                          setState(() => _selectedDate = picked);
                        });
                      }),
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
                                value: planner.id,
                                child: Text(
                                  planner.name,
                                  style: const TextStyle(
                                    color: AppColors.burgundy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            final selectedPlanner = _plannerById(value);

                            setState(() {
                              _selectedPlannerId = selectedPlanner?.id;
                              _selectedPlannerName = selectedPlanner?.name;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
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
