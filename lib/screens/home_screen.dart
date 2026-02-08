import 'package:event_planner/screens/create_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/models/event.dart';
import 'package:event_planner/widgets/event_card.dart';
import 'package:event_planner/widgets/quick_action_button.dart';
import 'package:event_planner/widgets/app_drawer.dart';
import 'package:event_planner/db/event_storage.dart';

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

  Future<void> _refreshEvents() async {
    if (_isLoadingEvents) return;

    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final updatedEvents = await loadEvents();

      final currentEvents = List<Event>.from(widget.registeredEvents);
      for (var event in currentEvents) {
        widget.onDeleteEvent(event);
      }

      for (var event in updatedEvents) {
        widget.onAddEvent(event);
      }

      setState(() {
        _allEvents = List.from(updatedEvents);
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
      print('>>> NEW EVENT CREATED: ${newEvent.title}');
      // Insert into database FIRST
      await insertEvent(newEvent);
      // Add to UI
      widget.onAddEvent(newEvent);
      // Force UI refresh
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
      print('>>> EVENT UPDATED: ${updatedEvent.title}');

      // Update in database FIRST
      await updateEvent(updatedEvent);

      // Update parent
      widget.onUpdateEvent(updatedEvent);

      // Refresh all events from database to ensure consistency
      await _refreshEvents();
    }
  }

  Future<void> _deleteEvent(Event event) async {
    print('>>> USER DELETED EVENT: ${event.title}');
    // Delete from database FIRST
    await deleteEvent(event);
    // Delete from UI
    widget.onDeleteEvent(event);
    // Refresh to update UI
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
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            //header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(color: Color(0xFF586041)),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EventFlow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 🔍 SEARCH BAR
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
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
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
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
                                              color: Color(0xFF151910),
                                            ),
                                          ),
                                          const Text(
                                            'Active Events',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
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
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
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
                                              color: Color(0xFF151910),
                                            ),
                                          ),
                                          const Text(
                                            'Days Until Next Event',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
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
                                    'Upcoming Events',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFF545A3B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('View All'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              //list of events
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
                                            onDelete: () => _deleteEvent(event),
                                            onTap: () => _editEvent(event),
                                            onEventUpdated: (_) async {
                                              await _refreshEvents();
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                              const SizedBox(height: 24),

                              //action button
                              const Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 100,
                                child: QuickActionButton(
                                  icon: Icons.add,
                                  label: 'New Event',
                                  onTap: _navigateToCreateEvent,
                                ),
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
    );
  }
}
