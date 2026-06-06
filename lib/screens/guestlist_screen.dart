import 'package:event_planner/models/Guest.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:event_planner/widgets/AddGuestDialog.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/widgets/GuestCard.dart';
import 'package:event_planner/widgets/statistics_cards.dart';
import 'package:event_planner/db/event_storage.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:event_planner/services/export_service.dart';

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGuests();
    _searchController.addListener(_filterGuest);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterGuest);
    _searchController.dispose();
    super.dispose();
  }

  // Safe snackbar helper
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    Future.microtask(() {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });
  }

  void _filterGuest() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredGuests = List.from(_allGuests);
      } else {
        _filteredGuests = _allGuests.where((guest) {
          return guest.name.toLowerCase().contains(query) ||
              guest.email.toLowerCase().contains(query) ||
              guest.phoneNumber.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // EXPORT TO EXCEL
  Future<void> _exportExcel() async {
    if (_allGuests.isEmpty) {
      _showSnackBar('No guests to export', backgroundColor: Colors.orange);
      return;
    }

    _showSnackBar('Generating Excel file...', backgroundColor: Colors.blue);

    try {
      await ExportService.exportToExcel(
        guests: _allGuests,
        eventName: widget.eventName,
      );

      if (!mounted) return;
      _showSnackBar(
        'Excel ready! Share or save the file.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Export failed: $e', backgroundColor: Colors.red);
    }
  }

  // EXPORT TO PDF
  Future<void> _exportPdf() async {
    if (_allGuests.isEmpty) {
      _showSnackBar('No guests to export', backgroundColor: Colors.orange);
      return;
    }

    _showSnackBar('Generating PDF file...', backgroundColor: Colors.blue);

    try {
      await ExportService.exportToPdf(
        guests: _allGuests,
        eventName: widget.eventName,
        totalCount: totalCount,
        acceptedCount: acceptedCount,
        pendingCount: pendingCount,
        declinedCount: declinedCount,
      );

      if (!mounted) return;
      _showSnackBar(
        'PDF ready! Share or save the file.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Export failed: $e', backgroundColor: Colors.red);
    }
  }

  // LOAD GUESTS FROM API
  Future<void> _loadGuests() async {
    if (!mounted) return;

    setState(() {
      _isloading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getEventGuests(int.parse(widget.eventID));

      if (!mounted) return;

      if (result['success'] == true) {
        final List<dynamic> guestsJson = result['data'] ?? [];
        final guests = guestsJson
            .map((json) => Guest.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          _allGuests = guests;
          _filteredGuests = guests;
          _isloading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load guests';
          _isloading = false;
        });
      }
    } catch (e) {
      print('Error loading guests: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
        _isloading = false;
      });
    }
  }

  // Statistics getters
  int get totalCount => _allGuests.length;
  int get acceptedCount =>
      _allGuests.where((g) => g.status == GuestStatus.accepted).length;
  int get declinedCount =>
      _allGuests.where((g) => g.status == GuestStatus.declined).length;
  int get pendingCount =>
      _allGuests.where((g) => g.status == GuestStatus.pending).length;
  int get checkedInCount =>
      _allGuests.where((g) => g.checkInTime != null).length;

  // ADD GUEST - Send invitation immediately
  void _addGuest() {
    showDialog(
      context: context,
      builder: (dialogContext) => AddGuestDialog(
        // removed guest: null
        onAdd: (guest) async {
          Navigator.pop(dialogContext);
          setState(() => _isloading = true);

          try {
            final result =
                await ApiService.addGuest(
                  eventId: int.parse(widget.eventID),
                  name: guest.name,
                  email: guest.email,
                  phone: guest.phoneNumber,
                  plusOneAllowed: guest.plusOnes != null && guest.plusOnes! > 0,
                  plusOneName: guest.plusOneName,
                  dietaryRestrictions: guest.dietaryRestrictions,
                  notes: guest.notes,
                  sendInvitation: true,
                ).timeout(
                  const Duration(seconds: 30),
                  onTimeout: () {
                    throw Exception('Request timed out. Please try again.');
                  },
                );

            if (!mounted) return;

            if (result['success'] == true) {
              await _loadGuests();
              if (!mounted) return;
              await updateEventProgress(widget.eventID);
              widget.onGuestChanged?.call();

              final emailSent = result['email_sent'] ?? false;
              _showSnackBar(
                emailSent
                    ? 'Guest added and invitation sent!'
                    : 'Guest added but email failed',
                backgroundColor: emailSent ? Colors.green : Colors.orange,
              );
            } else {
              setState(() => _isloading = false);
              _showSnackBar(
                result['message'] ?? 'Failed to add guest',
                backgroundColor: AppColors.burgundy.withOpacity(0.8),
              );
            }
          } catch (e) {
            if (!mounted) return;
            setState(() => _isloading = false);
            _showSnackBar(
              'Connection error. Please try again.',
              backgroundColor: AppColors.burgundy.withOpacity(0.8),
            );
            _loadGuests();
          }
        },
      ),
    );
  }

  // ✅ DELETE GUEST
  void _deleteGuest(Guest guest) async {
    try {
      final result = await ApiService.deleteGuest(int.parse(guest.id));

      if (!mounted) return;

      if (result['success'] == true) {
        await _loadGuests();
        await updateEventProgress(widget.eventID);
        widget.onGuestChanged?.call();

        _showSnackBar(
          '${guest.name} removed',
          backgroundColor: AppColors.burgundy.withOpacity(0.8),
        );
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to delete guest',
          backgroundColor: AppColors.burgundy.withOpacity(0.8),
        );
      }
    } catch (e) {
      _showSnackBar(
        'Failed to delete guest. Please try again.',
        backgroundColor: AppColors.burgundy.withOpacity(0.8),
      );
    }
  }

  //  RESEND INVITATION
  Future<void> _resendInvitation(Guest guest) async {
    try {
      final result = await ApiService.resendInvitation(int.parse(guest.id));

      if (result['success'] == true) {
        await _loadGuests();
        _showSnackBar(
          'Invitation resent to ${guest.name}!',
          backgroundColor: Colors.green,
        );
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to resend invitation',
          backgroundColor: AppColors.burgundy.withOpacity(0.8),
        );
      }
    } catch (e) {
      _showSnackBar(
        'Connection error. Please try again.',
        backgroundColor: AppColors.burgundy.withOpacity(0.8),
      );
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
                      FontAwesomeIcons.arrowLeft,
                      size: 20,
                      color: AppColors.darkpink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search guests...',
                      hintStyle: const TextStyle(color: AppColors.coral),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.coral,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _addGuest,
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.plusCircle,
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
      body: _isloading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF586041)),
                  SizedBox(height: 16),
                  Text(
                    'Sending invitation...',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGuests,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Statistics
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
                          textColor: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Statcard(
                          count: declinedCount,
                          label: 'Declined',
                          color: Colors.red.shade100,
                          textColor: AppColors.darkpink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Statcard(
                          count: pendingCount,
                          label: 'Pending',
                          color: Colors.orange.shade100,
                          textColor: const Color.fromARGB(255, 226, 104, 67),
                        ),
                      ),
                    ],
                  ),
                ),

                // Export buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportExcel,

                          label: const Text('Export Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkpink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exportPdf,

                          label: const Text('Export PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.darkpink,
                            side: const BorderSide(color: AppColors.darkpink),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Guest list (no edit on tap)
                Expanded(
                  child: _filteredGuests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.green.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No guests added yet'
                                    : 'No guests found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.green.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_searchController.text.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add your first guest',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.green.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadGuests,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredGuests.length,
                            itemBuilder: (context, index) {
                              final guest = _filteredGuests[index];
                              return GuestCard(
                                guest: guest,
                                onTap: null, // No edit - tap does nothing
                                onDelete: () => _deleteGuest(guest),
                                onResend: !guest.invitationSent
                                    ? () => _resendInvitation(guest)
                                    : null,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
