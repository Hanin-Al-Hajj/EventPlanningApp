import 'package:event_planner/db/Guest_storage.dart';
import 'package:event_planner/models/Guest.dart';
import 'package:event_planner/widgets/AddGuestDialog.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/widgets/GuestCard.dart';
import 'package:event_planner/widgets/Statcard.dart';
import 'package:event_planner/db/event_storage.dart';

class GuestListScreen extends StatefulWidget {
  const GuestListScreen({
    super.key,
    required this.eventID,
    required this.eventName,
    this.onGuestChanged,
  });
  final String eventID;
  final String eventName;
  final Future<void> Function()? onGuestChanged;
  @override
  State<GuestListScreen> createState() => _GuestlistScreenState();
}

class _GuestlistScreenState extends State<GuestListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Guest> _allGuests = [];
  List<Guest> _filteredGuests = [];
  bool _isloading = false;

  @override
  void initState() {
    super.initState();
    _loadGuests();
    _searchController.addListener(_filterGuest);
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
  }

  void _filterGuest() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGuests = _allGuests.where((guest) {
        return guest.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadGuests() async {
    setState(() => _isloading = true);
    try {
      final guests = await GuestStorage.loadGuestsForEvent(widget.eventID);
      setState(() {
        _allGuests = guests;
        _filteredGuests = guests;
        _isloading = false;
      });
    } catch (e) {
      print('Error loading guests:$e');
      setState(() => _isloading = false);
    }
  }

  int get acceptedCount =>
      _allGuests.where((g) => g.status == GuestStatus.accepted).length;
  int get declinedCount =>
      _allGuests.where((g) => g.status == GuestStatus.declined).length;

  int get pendingCount =>
      _allGuests.where((g) => g.status == GuestStatus.pending).length;

  void _addGuest() {
    showDialog(
      context: context,
      builder: (context) => AddGuestDialog(
        onAdd: (guest) async {
          await GuestStorage.insertGuest(guest, widget.eventID);
          _loadGuests();
          await updateEventProgress(widget.eventID);
          widget.onGuestChanged?.call();
        },
      ),
    );
  }

  void _editGuest(Guest guest) {
    showDialog(
      context: context,
      builder: (context) => AddGuestDialog(
        guest: guest,
        onAdd: (updateGuest) async {
          await GuestStorage.updateGuest(updateGuest, widget.eventID);
          _loadGuests();
          await updateEventProgress(widget.eventID);
          widget.onGuestChanged?.call();
        },
      ),
    );
  }

  void _deleteGuest(Guest guest) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Guest'),
        content: Text('Are you sure you want to remove ${guest.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await GuestStorage.deleteGuest(guest.id, widget.eventID);
      _loadGuests();
      await updateEventProgress(widget.eventID);
      widget.onGuestChanged?.call();
    }
  }

  void _importFromExcel() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Excel import coming soon!')));
  }

  void _sendInvites() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sending invites to $pendingCount guests...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF586041),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Guest List', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            onPressed: _addGuest,
          ),
        ],
      ),
      body: _isloading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF586041)),
            )
          : Column(
              children: [
                //search bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF586041),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search guests...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade600,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                //statistic card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Statcard(
                          count: acceptedCount,
                          label: 'Accepted',
                          color: Colors.green.shade100,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Statcard(
                          count: declinedCount,
                          label: 'Declined',
                          color: Colors.red.shade100,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Statcard(
                          count: pendingCount,
                          label: 'Pending',
                          color: Colors.orange.shade100,
                        ),
                      ),
                    ],
                  ),
                ),

                //action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _importFromExcel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF545A3B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Import Excel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _sendInvites,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF545A3B),
                            side: const BorderSide(color: Color(0xFF545A3B)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Send Invites'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                //list of guests
                Expanded(
                  child: _filteredGuests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No guests added yet'
                                    : 'No guests found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredGuests.length,
                          itemBuilder: (context, index) {
                            final guest = _filteredGuests[index];
                            return Guestcard(
                              guest: guest,
                              onTap: () => _editGuest(guest),
                              onDelete: () => _deleteGuest(guest),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
