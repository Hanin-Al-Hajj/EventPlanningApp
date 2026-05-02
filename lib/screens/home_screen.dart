import 'package:event_planner/screens/create_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/widgets/event_card.dart';
import 'package:event_planner/db/event_storage.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/screens/profile_screen.dart';
import 'package:event_planner/screens/system_screen.dart';

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
    await _refreshEvents();
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
        body: SafeArea(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20), // round bottom left
                  bottomRight: Radius.circular(20), // round bottom right
                ),

                //header
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.cream),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          children: [
                            const Text(
                              'EventFlow',
                              style: TextStyle(
                                color: AppColors.darkpink,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),

                            // Notification icon
                            const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.darkpink,
                            ),
                            const SizedBox(width: 12),

                            // Profile avatar with dropdown
                            PopupMenuButton<String>(
                              offset: const Offset(0, 45),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),

                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
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
                                PopupMenuItem<String>(
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
                                PopupMenuItem<String>(
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
                                padding: const EdgeInsets.all(8),

                                decoration: const BoxDecoration(
                                  color: AppColors.darkpink,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🔍 SEARCH BAR
                      SizedBox(
                        height: 60,
                        width: 310,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Search events...',
                            hintStyle: const TextStyle(color: AppColors.coral),
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
                    ],
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkpink,
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
                                    SizedBox(width: 15),
                                    TextButton(
                                      onPressed: _navigateToCreateEvent,
                                      style: TextButton.styleFrom(
                                        backgroundColor: AppColors.darkpink,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Text('Create Event'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _filteredEvents.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 32,
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.event_outlined,
                                                size: 64,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No events yet',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Create your first event to get started',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: _filteredEvents.map((event) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: EventCard(
                                              event: event,
                                              onDelete: () =>
                                                  _deleteEvent(event),
                                              onTap: () => _editEvent(event),
                                              onEventUpdated: (_) async {
                                                await _refreshEvents();
                                              },
                                            ),
                                          );
                                        }).toList(),
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
      ),
    );
  }
}
