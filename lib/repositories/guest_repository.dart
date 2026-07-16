import 'package:event_planner/models/Guest.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class GuestRepository {
  static final Map<int, ValueNotifier<List<Guest>>> _guestsByEvent = {};
  static final Set<int> _loadedEvents = {};
  static final Map<int, Future<void>> _runningRefreshes = {};

  static ValueNotifier<List<Guest>> guestsForEvent(int eventId) {
    return _notifierFor(eventId);
  }

  static List<Guest> cachedGuests(int eventId) {
    return _notifierFor(eventId).value;
  }

  static bool hasCache(int eventId) {
    return _loadedEvents.contains(eventId);
  }

  static void seed(int eventId, List<Guest> guests) {
    if (guests.isEmpty || hasCache(eventId)) return;

    _notifierFor(eventId).value = List<Guest>.from(guests);
    _loadedEvents.add(eventId);
  }

  static Future<void> loadGuests({
    required int eventId,
    bool forceRefresh = false,
  }) async {
    if (hasCache(eventId) && !forceRefresh) return;

    final runningRefresh = _runningRefreshes[eventId];
    if (runningRefresh != null) return runningRefresh;

    final refresh = _fetchGuests(eventId);
    _runningRefreshes[eventId] = refresh;

    try {
      await refresh;
    } finally {
      _runningRefreshes.remove(eventId);
    }
  }

  static Future<void> refreshInBackground(int eventId) async {
    try {
      await loadGuests(eventId: eventId, forceRefresh: true);
    } catch (e) {
      debugPrint('Guests background refresh error: $e');
    }
  }

  static Future<Map<String, dynamic>> addGuest({
    required int eventId,
    required String name,
    required String email,
    required String phone,
    bool plusOneAllowed = false,
    String? plusOneName,
    String? dietaryRestrictions,
    String? notes,
    bool sendInvitation = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await ApiService.addGuest(
      eventId: eventId,
      name: name,
      email: email,
      phone: phone,
      plusOneAllowed: plusOneAllowed,
      plusOneName: plusOneName,
      dietaryRestrictions: dietaryRestrictions,
      notes: notes,
      sendInvitation: sendInvitation,
    ).timeout(timeout);

    if (result['success'] == false) return result;

    final addedGuest = _guestFromResponse(result);
    if (addedGuest != null) {
      upsert(eventId: eventId, guest: addedGuest);
    } else {
      await loadGuests(eventId: eventId, forceRefresh: true);
    }

    return result;
  }

  static Future<Map<String, dynamic>> addGuestFromModel({
    required int eventId,
    required Guest guest,
    bool sendInvitation = true,
  }) {
    return addGuest(
      eventId: eventId,
      name: guest.name,
      email: guest.email,
      phone: guest.phoneNumber,
      plusOneAllowed: guest.plusOnes != null && guest.plusOnes! > 0,
      plusOneName: guest.plusOneName,
      dietaryRestrictions: guest.dietaryRestrictions,
      notes: guest.notes,
      sendInvitation: sendInvitation,
    );
  }

  static Future<Map<String, dynamic>> deleteGuest({
    required int eventId,
    required Guest guest,
  }) async {
    final result = await ApiService.deleteGuest(int.parse(guest.id));
    if (result['success'] == true) {
      remove(eventId: eventId, guestId: guest.id);
    }

    return result;
  }

  static Future<Map<String, dynamic>> resendInvitation({
    required int eventId,
    required Guest guest,
  }) async {
    final result = await ApiService.resendInvitation(int.parse(guest.id));
    if (result['success'] == true) {
      unawaitedRefresh(eventId);
    }

    return result;
  }

  static Future<Map<String, dynamic>> updateGuest({
    required int eventId,
    required int guestId,
    String? name,
    String? email,
    String? phone,
    bool? plusOneAllowed,
    String? plusOneName,
    String? dietaryRestrictions,
    String? notes,
  }) async {
    final result = await ApiService.updateGuest(
      guestId: guestId,
      name: name,
      email: email,
      phone: phone,
      plusOneAllowed: plusOneAllowed,
      plusOneName: plusOneName,
      dietaryRestrictions: dietaryRestrictions,
      notes: notes,
    );

    if (result['success'] != true) return result;

    final updatedGuest = _guestFromResponse(result);
    if (updatedGuest != null) {
      upsert(eventId: eventId, guest: updatedGuest);
    } else {
      unawaitedRefresh(eventId);
    }

    return result;
  }

  static Future<Map<String, dynamic>> checkInGuest({
    required int eventId,
    required Guest guest,
  }) async {
    final result = await ApiService.checkInGuest(int.parse(guest.id));
    if (result['success'] != true) return result;

    final updatedGuest = _guestFromResponse(result);
    if (updatedGuest != null) {
      upsert(eventId: eventId, guest: updatedGuest);
    } else {
      unawaitedRefresh(eventId);
    }

    return result;
  }

  static Future<Map<String, dynamic>> undoCheckIn({
    required int eventId,
    required Guest guest,
  }) async {
    final result = await ApiService.undoCheckIn(int.parse(guest.id));
    if (result['success'] != true) return result;

    final updatedGuest = _guestFromResponse(result);
    if (updatedGuest != null) {
      upsert(eventId: eventId, guest: updatedGuest);
    } else {
      unawaitedRefresh(eventId);
    }

    return result;
  }

  static void upsert({required int eventId, required Guest guest}) {
    final nextGuests = List<Guest>.from(_notifierFor(eventId).value);
    final index = nextGuests.indexWhere((item) => item.id == guest.id);

    if (index == -1) {
      nextGuests.insert(0, guest);
    } else {
      nextGuests[index] = guest;
    }

    _notifierFor(eventId).value = nextGuests;
    _loadedEvents.add(eventId);
  }

  static void remove({required int eventId, required String guestId}) {
    _notifierFor(eventId).value = _notifierFor(
      eventId,
    ).value.where((guest) => guest.id != guestId).toList();
  }

  static void unawaitedRefresh(int eventId) {
    refreshInBackground(eventId);
  }

  static void clearEvent(int eventId) {
    _guestsByEvent.remove(eventId);
    _loadedEvents.remove(eventId);
    _runningRefreshes.remove(eventId);
  }

  static void clear() {
    _guestsByEvent.clear();
    _loadedEvents.clear();
    _runningRefreshes.clear();
  }

  static Future<void> _fetchGuests(int eventId) async {
    final result = await ApiService.getEventGuests(eventId);
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to load guests');
    }

    final guests = _guestListFromResponse(result);
    _notifierFor(eventId).value = guests;
    _loadedEvents.add(eventId);
  }

  static List<Guest> _guestListFromResponse(Map<String, dynamic> result) {
    final data = result['data'];
    final rawGuests = data is List
        ? data
        : data is Map
        ? data['guests'] ?? data['data'] ?? const []
        : const [];

    final guests = <Guest>[];
    for (final item in _asList(rawGuests)) {
      final json = _asMap(item);
      if (json == null) continue;
      guests.add(Guest.fromJson(json));
    }

    return guests;
  }

  static Guest? _guestFromResponse(Map<String, dynamic> result) {
    final data = result['data'];
    final json =
        _asMap(result['guest']) ??
        (data is Map ? _asMap(data['guest']) : null) ??
        _asMap(data);

    if (json == null) return null;
    return Guest.fromJson(json);
  }

  static ValueNotifier<List<Guest>> _notifierFor(int eventId) {
    return _guestsByEvent.putIfAbsent(
      eventId,
      () => ValueNotifier<List<Guest>>([]),
    );
  }
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
