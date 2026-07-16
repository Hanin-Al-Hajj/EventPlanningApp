import 'dart:async';
import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/models/task.dart';
import 'package:event_planner/repositories/assistant_task_repository.dart';
import 'package:event_planner/screens/assistant/filtered_vendor_screen.dart';
import 'package:event_planner/screens/assistant/notification_screen.dart';
import 'package:event_planner/screens/assistant/assistant_setting.dart';
import 'package:event_planner/screens/assistant/assistant_profile_screen.dart';

class AssistantTaskScreen extends StatefulWidget {
  const AssistantTaskScreen({super.key});

  @override
  State<AssistantTaskScreen> createState() => _AssistantTaskScreenState();
}

class _AssistantTaskScreenState extends State<AssistantTaskScreen> {
  bool _isLoading = true;
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  int _totalTasks = 0;
  int _urgentTasks = 0;
  int _inProgressTasks = 0;
  int _completedTasks = 0;
  int _unreadNotifications = 0;
  String? _error;

  final TextEditingController _searchController = TextEditingController();

  void _filterTasks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTasks = List.from(_tasks);
      } else {
        final q = query.toLowerCase();
        _filteredTasks = _tasks.where((task) {
          return task.title.toLowerCase().contains(q) ||
              task.eventName.toLowerCase().contains(q) ||
              task.plannerName.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    AssistantTaskRepository.tasks.addListener(_onTasksChanged);
    _searchController.addListener(() => _filterTasks(_searchController.text));

    if (AssistantTaskRepository.hasCache) {
      _tasks = AssistantTaskRepository.cachedTasks;
      _filteredTasks = List.from(_tasks);
      _updateStats();
      _isLoading = false;
      unawaited(AssistantTaskRepository.refreshInBackground());
    } else {
      unawaited(_loadTasks());
    }
    _loadUnreadCount();
  }

  @override
  void dispose() {
    AssistantTaskRepository.tasks.removeListener(_onTasksChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onTasksChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _tasks = AssistantTaskRepository.cachedTasks;
        _filterTasks(_searchController.text);
        _updateStats();
        _isLoading = false;
        _error = null;
      });
    });
  }

  void _updateStats() {
    _totalTasks = _tasks.length;
    _urgentTasks = _tasks
        .where((t) => t.priority == TaskPriority.urgent)
        .length;
    _inProgressTasks = _tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    _completedTasks = _tasks.where((t) => t.status == TaskStatus.done).length;
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await ApiService.getAssistantNotificationStats();
      if (!mounted) return;
      setState(() {
        _unreadNotifications = res['unread'] ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _loadTasks({bool forceRefresh = false}) async {
    if (!forceRefresh && AssistantTaskRepository.hasCache) {
      setState(() {
        _tasks = AssistantTaskRepository.cachedTasks;
        _filteredTasks = List.from(_tasks);
        _updateStats();
        _isLoading = false;
        _error = null;
      });
      unawaited(AssistantTaskRepository.refreshInBackground());
      return;
    }

    if (_tasks.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      await AssistantTaskRepository.loadTasks(forceRefresh: forceRefresh);
      if (!mounted) return;

      setState(() {
        _tasks = AssistantTaskRepository.cachedTasks;
        _filteredTasks = List.from(_tasks);
        _updateStats();
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _tasks.isEmpty
            ? 'Something went wrong. Please try again.'
            : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.burgundy),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.burgundy),
        ),
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ApiService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  PopupMenuItem<String> _popupItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkpink),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.darkpink)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.urgent:
        priorityColor = const Color(0xFF620607); // vampire
        break;
      case TaskPriority.high:
        priorityColor = AppColors.darkpink;
        break;
      case TaskPriority.medium:
        priorityColor = AppColors.coral;
        break;
      case TaskPriority.low:
        priorityColor = Colors.green;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Status
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.burgundy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: _getStatusColor(task.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    // ignore: deprecated_member_use
                    color: _getStatusColor(task.status).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(task.status),
                      size: 14,
                      color: _getStatusColor(task.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.status == TaskStatus.done
                          ? 'Done'
                          : task.status == TaskStatus.inProgress
                          ? 'In Progress'
                          : 'To Do',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(task.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Priority + Event
          Row(
            children: [
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Event
              if (task.eventName.isNotEmpty) ...[
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.eventName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Planner
          if (task.plannerName.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.person, size: 13, color: AppColors.coral),
                const SizedBox(width: 4),
                Text(
                  'Assigned by: ${task.plannerName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          if (task.vendors != null && task.vendors!.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FilteredVendorScreen(taskId: task.id),
                  ),
                );
              },
              child: Container(
                width: 200,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AppColors.coral.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  // ignore: deprecated_member_use
                  border: Border.all(color: AppColors.coral.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.store,
                      size: 13,
                      color: AppColors.darkpink,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.vendorNames,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.darkpink,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.darkpink,
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Progress bar
          if (task.progress > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.status == TaskStatus.done
                            ? AppColors.green
                            : AppColors.darkpink,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${task.progress}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // Due date + Mark Done button
          if (task.dueDate != null || task.status != TaskStatus.done) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (task.dueDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: task.isOverdue ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.isOverdue
                            ? 'Overdue'
                            : 'Due ${_formatDate(task.dueDate!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: task.isOverdue
                              ? Colors.red
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (task.status != TaskStatus.done)
                  GestureDetector(
                    onTap: () => _markComplete(task),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Mark Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
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

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.done:
        return Icons.check_circle;
      case TaskStatus.inProgress:
        return Icons.pending;
      case TaskStatus.pending:
        return Icons.schedule;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _markComplete(Task task) async {
    final backup = List<Task>.from(_tasks);

    AssistantTaskRepository.markCompleted(task);
    setState(() {
      _tasks = AssistantTaskRepository.cachedTasks;
      _filterTasks(_searchController.text);
      _updateStats();
    });

    try {
      final result = await AssistantTaskRepository.completeTask(task.id);
      if (result is Map && result['success'] == false) {
        throw Exception('Failed to complete task');
      }
    } catch (_) {
      AssistantTaskRepository.setTasks(backup);
      if (mounted) {
        setState(() {
          _tasks = backup;
          _filterTasks(_searchController.text);
          _updateStats();
        });
        _showSnackBar('Could not mark task as complete.');
      }
      unawaited(_loadTasks(forceRefresh: true));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.burgundy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showVendorsBottomSheet(List<Map<String, dynamic>> vendors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assigned Vendors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.burgundy,
                ),
              ),
              const SizedBox(height: 16),
              ...vendors.map(
                (vendor) => ListTile(
                  leading: const Icon(Icons.store, color: AppColors.darkpink),
                  title: Text(
                    vendor['name'] ?? 'Unknown Vendor',
                    style: const TextStyle(color: AppColors.burgundy),
                  ),
                  subtitle: Text(
                    vendor['category'] ?? '',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Row(
                    children: [
                      PopupMenuButton<String>(
                        offset: const Offset(0, 45),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        itemBuilder: (context) => [
                          _popupItem(
                            'profile',
                            Icons.person_outline,
                            'Profile',
                          ),
                          _popupItem(
                            'settings',
                            Icons.settings_outlined,
                            'Settings',
                          ),
                          _popupItem('logout', Icons.logout, 'Logout'),
                        ],
                        onSelected: (value) {
                          if (value == 'profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssistantProfileScreen(),
                              ),
                            );
                          } else if (value == 'settings') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssistantSetting(),
                              ),
                            );
                          } else if (value == 'logout') {
                            _handleLogout();
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.darkpink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: AppColors.darkpink),
                            decoration: InputDecoration(
                              hintText: 'Search by task, event, planner...',
                              hintStyle: const TextStyle(
                                color: AppColors.coral,
                              ),
                              prefixIcon: const Icon(Icons.search),
                              prefixIconColor: AppColors.coral,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                          _loadUnreadCount();
                        },
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.bell,
                              size: 20,
                              color: AppColors.darkpink,
                            ),
                            if (_unreadNotifications > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: _unreadNotifications > 9 ? 18 : 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: AppColors.darkpink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _unreadNotifications > 9
                                          ? '9+'
                                          : '$_unreadNotifications',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          '$_totalTasks',
                          Icons.task_alt,
                          AppColors.coral,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStatCard(
                          'Urgent',
                          '$_urgentTasks',
                          Icons.priority_high,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStatCard(
                          'In Prog.',
                          '$_inProgressTasks',
                          Icons.pending,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStatCard(
                          'Done',
                          '$_completedTasks',
                          Icons.check_circle,
                          AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // My Tasks title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Assigned Tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color.fromARGB(255, 176, 27, 44),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Task List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.darkpink,
                          ),
                        )
                      : _error != null && _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                // ignore: deprecated_member_use
                                color: AppColors.green.withOpacity(0.5),
                                size: 60,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  // ignore: deprecated_member_use
                                  color: AppColors.green.withOpacity(0.8),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _loadTasks(forceRefresh: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 64,
                                // ignore: deprecated_member_use
                                color: AppColors.green.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks assigned yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  // ignore: deprecated_member_use
                                  color: AppColors.green.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tasks from your planner will appear here',
                                style: TextStyle(
                                  fontSize: 13,
                                  // ignore: deprecated_member_use
                                  color: AppColors.green.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadTasks(forceRefresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredTasks.length,
                            itemBuilder: (context, index) {
                              return _buildTaskCard(_filteredTasks[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    // ignore: deprecated_member_use
    p.color = AppColors.coral.withOpacity(0.10);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 130, p);
    // ignore: deprecated_member_use
    p.color = AppColors.darkpink.withOpacity(0.07);
    canvas.drawCircle(Offset(size.width * -0.12, size.height * 0.48), 170, p);
    // ignore: deprecated_member_use
    p.color = const Color.fromARGB(255, 176, 27, 44).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 1.08, size.height * 0.72), 190, p);
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => false;
}
