import 'package:event_planner/screens/create_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/widgets/event_card.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/screens/profile_screen.dart';
import 'package:event_planner/screens/system_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/screens/client_notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onAddEvent,
    required this.onDeleteEvent,
    required this.onUpdateEvent,
    required this.registeredEvents,
  });
  final Function(Event) onAddEvent;
  final Function(Event) onDeleteEvent;
  final Function(Event) onUpdateEvent;
  final List<Event> registeredEvents;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];

  bool _isLoadingEvents = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int get activeEventsCount {
    return widget.registeredEvents
        .where(
          (event) =>
              event.status == 'In Progress' || event.status == 'Planning',
        )
        .length;
  }

  int get daysUntilNextEvent {
    if (widget.registeredEvents.isEmpty) return 0;

    final now = DateTime.now();
    final upcomingEvents =
        widget.registeredEvents
            .where((event) => event.date.isAfter(now))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (upcomingEvents.isEmpty) return 0;

    return upcomingEvents.first.date.difference(now).inDays;
  }

  void _filterEvents() {
    setState(() {
      _filteredEvents = _applySearch(_searchController.text);
    });
  }

  List<Event> _applySearch(String query) {
    if (query.isEmpty) return List.from(_allEvents);

    final lowerQuery = query.toLowerCase();

    return _allEvents.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
          event.location.toLowerCase().contains(lowerQuery) ||
          event.status.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.burgundy),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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
      ApiService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _refreshEvents() async {
    if (_isLoadingEvents) return;

    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final result = await ApiService.getEvents();
      final List rawEvents = result['data'] ?? [];

      final List<Event> events = rawEvents
          .map(
            (e) => Event(
              id: e['id'].toString(),
              title: e['name'] ?? '',
              date: DateTime.parse(e['start_date']),
              location: e['location_text'] ?? 'TBD',
              guests: int.tryParse(e['guest_estimate'].toString()) ?? 0,
              budget: double.tryParse(e['budget_overall'].toString()) ?? 0.0,
              progress: 0.0,
              status: e['status'] ?? 'Planning',
              eventType: e['event_type']?['name'],
              description: e['description'],
            ),
          )
          .toList();

      final currentEvents = List<Event>.from(widget.registeredEvents);
      for (var event in currentEvents) {
        widget.onDeleteEvent(event);
      }

      for (var event in events) {
        widget.onAddEvent(event);
      }

      setState(() {
        _allEvents = List.from(events);
        _filteredEvents = _applySearch(_searchController.text);
      });
    } catch (e) {
      print('Error refreshing events: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading events: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
        });
      }
    }
  }

  Future<void> _navigateToCreateEvent() async {
    final newEvent = await Navigator.push<Event>(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventScreen()),
    );

    if (newEvent != null) {
      await _refreshEvents();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editEvent(Event event) async {
    final updatedEvent = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(eventToEdit: event),
      ),
    );

    if (updatedEvent != null) {
      await _refreshEvents();
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Event',
          style: TextStyle(color: AppColors.burgundy),
        ),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
          style: const TextStyle(color: AppColors.burgundy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.burgundy),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkpink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await ApiService.deleteEvent(event.id);

      if (!mounted) return;

      if (result['success'] == true) {
        widget.onDeleteEvent(event);

        setState(() {
          _allEvents.removeWhere((e) => e.id == event.id);
          _filteredEvents = _applySearch(_searchController.text);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete event'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
    }
  }

  @override
  void initState() {
    super.initState();

    _allEvents = List.from(widget.registeredEvents);
    _filteredEvents = _allEvents;

    _searchController.addListener(_filterEvents);

    if (widget.registeredEvents.isEmpty) {
      Future.microtask(() => _refreshEvents());
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update local lists when parent updates
    if (oldWidget.registeredEvents != widget.registeredEvents) {
      setState(() {
        _allEvents = List.from(widget.registeredEvents);
        _filteredEvents = _applySearch(_searchController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: _scaffoldKey,
      child: Scaffold(
        body: Stack(
          children: [
            const _HomeBackgroundShapes(),
            SafeArea(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20), // round bottom left
                      bottomRight: Radius.circular(20), // round bottom right
                    ),

                    //header
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cream.withOpacity(0.1),
                      ),
                      child: Padding(
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
                                const PopupMenuItem<String>(
                                  value: 'profile',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        color: AppColors.darkpink,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Profile',
                                        style: TextStyle(
                                          color: AppColors.darkpink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'settings',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.settings_outlined,
                                        color: AppColors.darkpink,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Settings',
                                        style: TextStyle(
                                          color: AppColors.darkpink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: AppColors.darkpink,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: AppColors.darkpink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'profile') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileScreen(),
                                    ),
                                  );
                                } else if (value == 'settings') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SystemScreen(),
                                    ),
                                  );
                                } else if (value == 'logout') {
                                  _handleLogout(context);
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
                                  style: const TextStyle(
                                    color: AppColors.darkpink,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search events...',
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

                            const SizedBox(width: 10),

                            Container(
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ClientNotificationScreen(),
                                    ),
                                  );
                                },
                                icon: const FaIcon(
                                  FontAwesomeIcons.bell,
                                  size: 20,
                                  color: AppColors.darkpink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  //main content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshEvents,
                      child: _isLoadingEvents && widget.registeredEvents.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //stat cards
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 110,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.coral,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '$activeEventsCount',
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const Text(
                                                  'Active Events',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            height: 110,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.coral,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '$daysUntilNextEvent',
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const Text(
                                                  'Days Until Next Event',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    //upcoming events
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'My Events   ',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color.fromARGB(
                                              255,
                                              176,
                                              27,
                                              44,
                                            ),
                                          ),
                                        ),
                                        if (_filteredEvents.isNotEmpty)
                                          Text(
                                            'Swipe Card',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.coral,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        SizedBox(width: 10),
                                        TextButton(
                                          onPressed: _navigateToCreateEvent,
                                          style: TextButton.styleFrom(
                                            backgroundColor: AppColors.darkpink,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Text('Create Event'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _filteredEvents.isEmpty
                                        ? TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0, end: 1),
                                            duration: const Duration(
                                              milliseconds: 350,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, value, child) {
                                              return Opacity(
                                                opacity: value,
                                                child: Transform.scale(
                                                  scale: 0.96 + (value * 0.04),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 32,
                                                    ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.event_outlined,
                                                      size: 64,
                                                      color: Color.fromARGB(
                                                        255,
                                                        71,
                                                        91,
                                                        55,
                                                      ).withOpacity(0.6),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'No events yet',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Color.fromARGB(
                                                          255,
                                                          71,
                                                          91,
                                                          55,
                                                        ).withOpacity(0.8),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Create your first event to get started',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Color.fromARGB(
                                                          255,
                                                          71,
                                                          91,
                                                          55,
                                                        ).withOpacity(0.6),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        : Column(
                                            children: _filteredEvents
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                                  final index = entry.key;
                                                  final event = entry.value;

                                                  return TweenAnimationBuilder<
                                                    double
                                                  >(
                                                    tween: Tween(
                                                      begin: 0,
                                                      end: 1,
                                                    ),
                                                    duration: Duration(
                                                      milliseconds:
                                                          300 + (index * 80),
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    builder: (context, value, child) {
                                                      return Opacity(
                                                        opacity: value,
                                                        child:
                                                            Transform.translate(
                                                              offset: Offset(
                                                                0,
                                                                18 *
                                                                    (1 - value),
                                                              ),
                                                              child: child,
                                                            ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 12,
                                                          ),
                                                      child: EventCard(
                                                        event: event,
                                                        onDelete: () =>
                                                            _deleteEvent(event),
                                                        onTap: () =>
                                                            _editEvent(event),
                                                        onEventUpdated: (_) async {
                                                          await _refreshEvents();
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                          ),
                                  ],
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
    );
  }
}

class _HomeBackgroundShapes extends StatelessWidget {
  const _HomeBackgroundShapes();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _HomeBackgroundPainter()),
    );
  }
}

class _HomeBackgroundPainter extends CustomPainter {
  const _HomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = AppColors.coral.withOpacity(0.10);
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.08),
      130,
      paint,
    );

    paint.color = AppColors.darkpink.withOpacity(0.07);
    canvas.drawCircle(
      Offset(size.width * -0.12, size.height * 0.48),
      170,
      paint,
    );

    paint.color = const Color.fromARGB(255, 176, 27, 44).withOpacity(0.06);
    canvas.drawCircle(
      Offset(size.width * 1.08, size.height * 0.72),
      190,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeBackgroundPainter oldDelegate) => false;
}
