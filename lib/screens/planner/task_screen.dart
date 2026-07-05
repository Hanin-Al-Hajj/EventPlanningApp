import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/task.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlannerTaskScreen extends StatefulWidget {
  final int eventId;
  final String eventName;

  const PlannerTaskScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<PlannerTaskScreen> createState() => _PlannerTaskScreenState();
}

class _PlannerTaskScreenState extends State<PlannerTaskScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _todoCount = 0;
  int _inProgressCount = 0;
  int _doneCount = 0;
  int _eventGuests = 0;
  double _eventBudget = 0;
  String _eventDescription = '';
  String? _eventLocation;

  List<Map<String, dynamic>> _assistants = [];
  List<Map<String, dynamic>> _vendors = [];
  bool _isFormDataLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        ApiService.getEventTasks(widget.eventId),
        ApiService.getPlannerEvent(widget.eventId),
        ApiService.getAssistants(),
        ApiService.getVendors(widget.eventId.toString()),
      ], eagerError: false);

      if (!mounted) return;

      // Tasks (index 0)
      final taskResult = results[0];
      if (taskResult is Map && taskResult['success'] == true) {
        final data = taskResult['data'];
        final tasksList = data['tasks'] as List? ?? [];
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        _tasks = tasksList
            .map((t) => Task.fromJson(Map<String, dynamic>.from(t)))
            .toList();
        _todoCount = stats['todo'] ?? 0;
        _inProgressCount = stats['in_progress'] ?? 0;
        _doneCount = stats['done'] ?? 0;
      }

      // Event details (index 1)
      final eventResult = results[1];
      if (eventResult is Map && eventResult['success'] == true) {
        final event = eventResult['data'] as Map<String, dynamic>? ?? {};
        _eventGuests = int.tryParse('${event['guest_estimate'] ?? 0}') ?? 0;
        _eventBudget =
            double.tryParse(
              '${event['budget'] ?? event['budget_overall'] ?? 0}',
            ) ??
            0;
        _eventDescription = event['description'] ?? '';
        _eventLocation = event['location'] ?? event['location_text'] ?? '';
      }

      // Assistants (index 2)
      final assistantsResult = results[2] as Map<String, dynamic>?;
      if (assistantsResult != null && assistantsResult['success'] == true) {
        _assistants = List<Map<String, dynamic>>.from(
          assistantsResult['data'] ?? [],
        );
      }

      // Vendors (index 3)
      final vendorsResult = results[3] as Map<String, dynamic>?;
      if (vendorsResult != null && vendorsResult['success'] == true) {
        _vendors = List<Map<String, dynamic>>.from(
          vendorsResult['vendors'] ?? vendorsResult['data'] ?? [],
        );
      }
    } catch (e) {
      debugPrint('Load error: $e');
      if (mounted) _errorMessage = 'Connection error';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getEventTasks(widget.eventId),
        ApiService.getPlannerEvent(widget.eventId),
      ], eagerError: false);

      if (!mounted) return;

      // Parse tasks (index 0)
      final taskResult = results[0];
      if (taskResult is Map && taskResult['success'] == true) {
        final data = taskResult['data'];
        final tasksList = data['tasks'] as List? ?? [];
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        setState(() {
          _tasks = tasksList
              .map((t) => Task.fromJson(Map<String, dynamic>.from(t)))
              .toList();
          _todoCount = stats['todo'] ?? 0;
          _inProgressCount = stats['in_progress'] ?? 0;
          _doneCount = stats['done'] ?? 0;
        });
      }

      // Parse event details (index 1)
      final eventResult = results[1];
      // ignore: unnecessary_type_check
      if (eventResult is Map && eventResult['success'] == true) {
        final event = eventResult['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _eventGuests = int.tryParse('${event['guest_estimate'] ?? 0}') ?? 0;
          _eventBudget =
              double.tryParse(
                '${event['budget'] ?? event['budget_overall'] ?? 0}',
              ) ??
              0;
          _eventDescription = event['description'] ?? '';
          _eventLocation = event['location'] ?? event['location_text'] ?? '';
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Load tasks error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection error';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final newStatus = task.status == TaskStatus.done ? 'pending' : 'done';
    try {
      final result = await ApiService.updateTaskStatus(task.id, newStatus);
      if (result['success'] == true) _loadTasks();
    } catch (e) {}
  }

  void _showTaskDialog({Task? task}) async {
    final assistants = _assistants;
    final vendors = _vendors;

    if (!mounted) return;

    final isEditing = task != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    String priority = task?.priority.name ?? 'medium';
    String? assistantId = task?.planner?['id']?.toString();
    List<int> vendorIds =
        task?.vendors
            ?.map((v) => int.tryParse(v['id']?.toString() ?? '') ?? 0)
            .where((id) => id > 0)
            .toList() ??
        [];
    DateTime? dueDate = task?.dueDate;
    int progress = task?.progress ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEditing ? 'Edit Task' : 'Add Task',
            style: const TextStyle(
              color: AppColors.darkpink,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(titleController, 'Title *'),
                const SizedBox(height: 12),
                _buildField(
                  descriptionController,
                  'Description (optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Priority',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.burgundy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: priority,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.burgundy.withOpacity(0.3),
                                ),
                              ),
                            ),
                            items: ['low', 'medium', 'high', 'urgent']
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      p[0].toUpperCase() + p.substring(1),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => priority = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.burgundy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: dueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColors
                                            .darkpink, // header & selected day
                                        onPrimary:
                                            Colors.white, // text on header
                                        onSurface: AppColors
                                            .burgundy, // calendar day text
                                        surface: AppColors.cream, // background
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors
                                              .darkpink, // OK / Cancel buttons
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() => dueDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  // ignore: deprecated_member_use
                                  color: AppColors.burgundy.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                dueDate != null
                                    ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: dueDate != null
                                      ? AppColors.burgundy
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.burgundy,
                          ),
                        ),
                        Text(
                          '$progress%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkpink,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: progress.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.darkpink,
                      onChanged: (v) =>
                          setDialogState(() => progress = v.round()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Assistant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.burgundy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: assistantId,
                      decoration: InputDecoration(
                        hintText: 'No Assistant',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            // ignore: deprecated_member_use
                            color: AppColors.burgundy.withOpacity(0.3),
                          ),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'No Assistant',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                        if (assistants.isNotEmpty)
                          ...assistants.map(
                            (a) => DropdownMenuItem(
                              value: a['id'].toString(),
                              child: Text(
                                a['name'] ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                      ],
                      onChanged: (v) => setDialogState(() => assistantId = v),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assign Vendors',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.burgundy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              // ignore: deprecated_member_use
                              color: AppColors.burgundy.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (vendorIds.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: vendorIds.map((id) {
                                    final vendor = vendors.firstWhere(
                                      (v) =>
                                          v['id'].toString() == id.toString(),
                                      orElse: () => {},
                                    );
                                    return Chip(
                                      label: Text(
                                        vendor['name'] ?? 'Vendor',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 14,
                                      ),
                                      onDeleted: () => setDialogState(
                                        () => vendorIds.remove(id),
                                      ),
                                      backgroundColor: AppColors.coral
                                          // ignore: deprecated_member_use
                                          .withOpacity(0.1),
                                      side: BorderSide(
                                        // ignore: deprecated_member_use
                                        color: AppColors.coral.withOpacity(0.3),
                                      ),
                                    );
                                  }).toList(),
                                )
                              else
                                const Text(
                                  'No vendors selected',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (vendors.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 150,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,

                                      children: vendors.map((v) {
                                        final id = v['id'].toString();
                                        final isSelected = vendorIds.contains(
                                          int.tryParse(id) ?? 0,
                                        );
                                        return CheckboxListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            v['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          value: isSelected,
                                          activeColor: AppColors.darkpink,
                                          onChanged: (checked) {
                                            setDialogState(() {
                                              if (checked == true) {
                                                vendorIds.add(
                                                  int.tryParse(id) ?? 0,
                                                );
                                              } else {
                                                vendorIds.remove(
                                                  int.tryParse(id) ?? 0,
                                                );
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.darkpink),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                try {
                  if (isEditing) {
                    await ApiService.updateTask(
                      taskId: task.id,
                      title: titleController.text,
                      description: descriptionController.text.isNotEmpty
                          ? descriptionController.text
                          : null,
                      priority: priority,
                      dueDate: dueDate?.toIso8601String(),
                      progress: progress,
                      assistantId: assistantId != null
                          ? int.tryParse(assistantId!)
                          : null,
                      vendorIds: vendorIds.isNotEmpty ? vendorIds : null,
                    );
                  } else {
                    await ApiService.createTask(
                      eventId: widget.eventId,
                      title: titleController.text,
                      description: descriptionController.text.isNotEmpty
                          ? descriptionController.text
                          : null,
                      priority: priority,
                      dueDate: dueDate?.toIso8601String(),
                      progress: progress,
                      assistantId: assistantId != null
                          ? int.tryParse(assistantId!)
                          : null,
                      vendorIds: vendorIds.isNotEmpty ? vendorIds : null,
                    );
                  }
                  Navigator.pop(ctx);
                  _loadTasks();
                } catch (e) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkpink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isEditing ? 'Update' : 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: AppColors.burgundy, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          // ignore: deprecated_member_use
          borderSide: BorderSide(color: AppColors.burgundy.withOpacity(0.3)),
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.done:
        return AppColors.green;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.pending:
        return Colors.blue;
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
                  widget.eventName,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.burgundy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _showTaskDialog(),
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.circlePlus,
                      size: 28,
                      color: AppColors.darkpink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.darkpink),
            )
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 1,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'To Do',
                          '$_todoCount',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStatCard(
                          'In Progress',
                          '$_inProgressCount',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStatCard(
                          'Done',
                          '$_doneCount',
                          AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                // Event Summary Card
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_eventGuests > 0) ...[
                            const Icon(
                              Icons.people,
                              size: 14,
                              color: AppColors.coral,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_eventGuests guests',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.burgundy,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (_eventBudget > 0) ...[
                            const Icon(
                              Icons.attach_money,
                              size: 14,
                              color: AppColors.coral,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${_eventBudget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.burgundy,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (_eventLocation != null &&
                              _eventLocation!.isNotEmpty) ...[
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.coral,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _eventLocation!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.burgundy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),
                      Text(
                        _eventDescription.isNotEmpty
                            ? '" $_eventDescription "'
                            : 'Description: The client didn\'t specify a description',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _eventDescription.isNotEmpty
                              ? AppColors.burgundy
                              : AppColors.green.withOpacity(0.7),
                          fontStyle: _eventDescription.isNotEmpty
                              ? FontStyle.italic
                              : FontStyle.italic,
                        ),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 64,
                                color: AppColors.green.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.green.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTasks,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) =>
                                _buildTaskCard(_tasks[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Dismissible(
      key: Key(task.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
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
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Task',
              style: TextStyle(color: AppColors.burgundy),
            ),
            content: Text('Remove "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.burgundy),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkpink,
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
      onDismissed: (direction) => _deleteTask(task.id),
      child: GestureDetector(
        onTap: () => _showTaskDialog(task: task),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: task.status == TaskStatus.done,
                    onChanged: (_) => _toggleTaskStatus(task),
                    activeColor: AppColors.darkpink,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: task.status == TaskStatus.done
                                ? AppColors.green
                                : AppColors.burgundy,
                            decoration: task.status == TaskStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              task.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status == TaskStatus.done
                          ? 'Done'
                          : task.status == TaskStatus.inProgress
                          ? 'In Progress'
                          : 'To Do',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(task.status),
                      ),
                    ),
                  ),
                ],
              ),
              // Assistant
              if (task.plannerName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 12,
                        color: AppColors.coral,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned to: ${task.plannerName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              // Vendors
              if (task.vendors != null && task.vendors!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.vendors!.length} vendor(s) assigned',
                        style: TextStyle(fontSize: 11, color: AppColors.green),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTask(int taskId) async {
    try {
      final result = await ApiService.deleteTask(taskId);
      if (!mounted) return;
      if (result['success'] == true) {
        _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted'),
              backgroundColor: AppColors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete'),
            backgroundColor: AppColors.burgundy,
          ),
        );
      }
    }
  }
}
