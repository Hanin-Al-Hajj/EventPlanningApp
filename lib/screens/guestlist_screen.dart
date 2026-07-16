import 'dart:async';

import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/db/event_storage.dart';
import 'package:event_planner/models/Guest.dart';
import 'package:event_planner/repositories/guest_repository.dart';
import 'package:event_planner/services/export_service.dart';
import 'package:event_planner/widgets/add_guest_dialog.dart';
import 'package:event_planner/widgets/guest_card.dart';
import 'package:event_planner/widgets/statistics_cards.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  late final int _eventId;
  late ValueNotifier<List<Guest>> _guestsNotifier;

  List<Guest> _allGuests = [];
  List<Guest> _filteredGuests = [];
  bool _isloading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _eventId = int.tryParse(widget.eventID) ?? 0;
    _searchController.addListener(_filterGuest);

    if (_eventId == 0) {
      _errorMessage = 'Invalid event';
      return;
    }

    _guestsNotifier = GuestRepository.guestsForEvent(_eventId);
    _guestsNotifier.addListener(_onGuestsChanged);

    _allGuests = GuestRepository.cachedGuests(_eventId);
    _filteredGuests = _applySearch(_searchController.text);

    if (GuestRepository.hasCache(_eventId)) {
      unawaited(GuestRepository.refreshInBackground(_eventId));
    } else {
      unawaited(_loadGuests());
    }
  }

  @override
  void dispose() {
    if (_eventId != 0) {
      _guestsNotifier.removeListener(_onGuestsChanged);
    }
    _searchController.removeListener(_filterGuest);
    _searchController.dispose();
    super.dispose();
  }

  void _onGuestsChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _allGuests = GuestRepository.cachedGuests(_eventId);
        _filteredGuests = _applySearch(_searchController.text);
        _errorMessage = null;
      });
    });
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    Future.microtask(() {
      if (!mounted) return;

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
    });
  }

  List<Guest> _applySearch(String queryText) {
    final query = queryText.toLowerCase().trim();
    if (query.isEmpty) return List<Guest>.from(_allGuests);

    return _allGuests.where((guest) {
      return guest.name.toLowerCase().contains(query) ||
          guest.email.toLowerCase().contains(query) ||
          guest.phoneNumber.toLowerCase().contains(query);
    }).toList();
  }

  void _filterGuest() {
    setState(() {
      _filteredGuests = _applySearch(_searchController.text);
    });
  }

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

  Future<void> _loadGuests({bool showLoader = true}) async {
    if (!mounted || _eventId == 0) return;

    final hasCache = GuestRepository.hasCache(_eventId);

    if (showLoader && !hasCache) {
      setState(() {
        _isloading = true;
        _errorMessage = null;
      });
    } else if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      await GuestRepository.loadGuests(eventId: _eventId, forceRefresh: true);

      if (!mounted) return;

      setState(() {
        _allGuests = GuestRepository.cachedGuests(_eventId);
        _filteredGuests = _applySearch(_searchController.text);
        _isloading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error loading guests: $e');
      if (!mounted) return;

      setState(() {
        _isloading = false;
        if (!hasCache && _allGuests.isEmpty) {
          _errorMessage = 'Connection error. Please try again.';
        }
      });
    }
  }

  int get totalCount => _allGuests.length;
  int get acceptedCount =>
      _allGuests.where((g) => g.status == GuestStatus.accepted).length;
  int get declinedCount =>
      _allGuests.where((g) => g.status == GuestStatus.declined).length;
  int get pendingCount =>
      _allGuests.where((g) => g.status == GuestStatus.pending).length;
  int get checkedInCount =>
      _allGuests.where((g) => g.checkInTime != null).length;

  void _addGuest() {
    showDialog(
      context: context,
      builder: (dialogContext) => AddGuestDialog(
        onAdd: (guest) async {
          Navigator.pop(dialogContext);

          try {
            final result = await GuestRepository.addGuest(
              eventId: _eventId,
              name: guest.name,
              email: guest.email,
              phone: guest.phoneNumber,
              plusOneAllowed: guest.plusOnes != null && guest.plusOnes! > 0,
              plusOneName: guest.plusOneName,
              dietaryRestrictions: guest.dietaryRestrictions,
              notes: guest.notes,
              sendInvitation: true,
            );

            if (!mounted) return;

            if (result['success'] == true) {
              await updateEventProgress(widget.eventID);
              final callback = widget.onGuestChanged;
              if (callback != null) await callback();

              unawaited(GuestRepository.refreshInBackground(_eventId));

              final emailSent = result['email_sent'] ?? false;
              _showSnackBar(
                emailSent
                    ? 'Guest added and invitation sent!'
                    : 'Guest added but email failed',
                backgroundColor: emailSent ? Colors.green : Colors.orange,
              );
            } else {
              _showSnackBar(
                result['message'] ?? 'Failed to add guest',
                backgroundColor: AppColors.burgundy.withOpacity(0.8),
              );
            }
          } catch (_) {
            if (!mounted) return;

            _showSnackBar(
              'Connection error. Please try again.',
              backgroundColor: AppColors.burgundy.withOpacity(0.8),
            );
            unawaited(GuestRepository.refreshInBackground(_eventId));
          }
        },
      ),
    );
  }

  Future<void> _deleteGuest(Guest guest) async {
    try {
      final result = await GuestRepository.deleteGuest(
        eventId: _eventId,
        guest: guest,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await updateEventProgress(widget.eventID);
        final callback = widget.onGuestChanged;
        if (callback != null) await callback();

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
    } catch (_) {
      _showSnackBar(
        'Failed to delete guest. Please try again.',
        backgroundColor: AppColors.burgundy.withOpacity(0.8),
      );
    }
  }

  Future<void> _resendInvitation(Guest guest) async {
    try {
      final result = await GuestRepository.resendInvitation(
        eventId: _eventId,
        guest: guest,
      );

      if (!mounted) return;

      if (result['success'] == true) {
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
    } catch (_) {
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
                onTap: _eventId == 0 ? null : _addGuest,
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
      body: _isloading && _allGuests.isEmpty
          ? _buildLoadingState()
          : _errorMessage != null && _allGuests.isEmpty
          ? _buildErrorState()
          : _buildGuestContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF586041)),
          SizedBox(height: 16),
          Text(
            'Loading guests...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadGuests(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.table_chart, size: 18),
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
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
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
        Expanded(
          child: _filteredGuests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadGuests(showLoader: false),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredGuests.length,
                    itemBuilder: (context, index) {
                      final guest = _filteredGuests[index];
                      return GuestCard(
                        guest: guest,
                        onTap: null,
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
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => _loadGuests(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          Column(
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
        ],
      ),
    );
  }
}
