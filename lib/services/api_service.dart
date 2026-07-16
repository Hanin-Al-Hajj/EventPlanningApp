import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Smart URL: automatically picks the right address per platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api'; // Web browser
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api'; // Android emulator
    } else {
      return 'http://127.0.0.1:8000/api'; // iOS simulator
    }
  }

  static String? _token;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;

  static Map<String, String> get publicHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  // REGISTER
  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: publicHeaders,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
      }),
    );
    final data = jsonDecode(response.body);

    if (data['token'] != null) setToken(data['token']);
    return data;
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: publicHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (data['token'] != null) setToken(data['token']);
    return data;
  }

  // LOGOUT
  static Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/logout'), headers: authHeaders);
    clearToken();
  }

  // GET ALL EVENTS
  static Future<Map<String, dynamic>> getEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/events'),
      headers: authHeaders,
    );
    return jsonDecode(response.body);
  }

  // GET ONE EVENT
  static Future<Map<String, dynamic>> getEvent(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/events/$id'),
      headers: authHeaders,
    );
    return jsonDecode(response.body);
  }

  // CREATE EVENT
  static Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> eventData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/client/events'),
      headers: authHeaders,
      body: jsonEncode(eventData),
    );
    return jsonDecode(response.body);
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final isOk = response.statusCode >= 200 && response.statusCode < 300;

    if (response.body.isEmpty) {
      return {'success': isOk};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        decoded.putIfAbsent('success', () => isOk);
        return decoded;
      }
      return {'success': isOk, 'data': decoded};
    } catch (e) {
      return {
        'success': false,
        'message': 'Server returned an invalid response',
        'status_code': response.statusCode,
        'body': response.body,
      };
    }
  }

  // UPDATE EVENT
  static Future<Map<String, dynamic>> updateEvent(
    String id,
    Map<String, dynamic> eventData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/client/events/$id'),
      headers: authHeaders,
      body: jsonEncode(eventData),
    );
    return _decodeResponse(response);
  }

  // DELETE EVENT
  static Future<Map<String, dynamic>> deleteEvent(String id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/client/events/$id'), headers: authHeaders)
        .timeout(const Duration(seconds: 10));
    return _decodeResponse(response);
  }

  // GET event types and planners for create form
  static Future<Map<String, dynamic>> getCreateData() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/client/events/create-data'),
          headers: authHeaders,
        )
        .timeout(const Duration(seconds: 10));
    return _decodeResponse(response);
  }

  // GET current user profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http
        .get(Uri.parse('$baseUrl/me'), headers: authHeaders)
        .timeout(const Duration(seconds: 10));

    return _decodeResponse(response);
  }

  // UPDATE profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/profile'),
          headers: authHeaders,
          body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));

    return _decodeResponse(response);
  }

  // UPDATE password
  static Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/profile/password'),
          headers: authHeaders,
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));

    return _decodeResponse(response);
  }

  // GET ALL GUESTS (optional filters)
  static Future<Map<String, dynamic>> getGuests({
    int? eventId,
    String? status, // 'pending', 'accepted', 'declined'
    String? search,
    int? perPage,
  }) async {
    final params = <String, String>{};
    if (eventId != null) params['event_id'] = eventId.toString();
    if (status != null) params['status'] = status;
    if (search != null) params['search'] = search;
    if (perPage != null) params['per_page'] = perPage.toString();

    final uri = Uri.parse(
      '$baseUrl/client/guests',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri, headers: authHeaders);
    return _decodeResponse(response);
  }

  // GET GUESTS FOR A SPECIFIC EVENT
  static Future<Map<String, dynamic>> getEventGuests(
    int eventId, {
    String? status,
    String? search,
    int? perPage,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (search != null) params['search'] = search;
    if (perPage != null) params['per_page'] = perPage.toString();

    final uri = Uri.parse(
      '$baseUrl/client/events/$eventId/guests',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri, headers: authHeaders);
    return _decodeResponse(response);
  }

  // GET SINGLE GUEST
  static Future<Map<String, dynamic>> getGuest(int guestId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/guests/$guestId'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // ADD GUEST + SEND INVITATION
  // In api_service.dart, update the addGuest method:
  static Future<Map<String, dynamic>> addGuest({
    required int eventId,
    required String name,
    required String email,
    String? phone,
    bool? plusOneAllowed,
    String? plusOneName,
    String? dietaryRestrictions,
    String? notes,
    bool sendInvitation = true,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'send_invitation': sendInvitation,
    };

    if (phone != null) body['phone'] = phone;
    if (plusOneAllowed != null) body['plus_one_allowed'] = plusOneAllowed;
    if (plusOneName != null) body['plus_one_name'] = plusOneName;
    if (dietaryRestrictions != null) {
      body['dietary_restrictions'] = dietaryRestrictions;
    }
    if (notes != null) body['notes'] = notes;

    final response = await http
        .post(
          Uri.parse('$baseUrl/client/events/$eventId/guests'),
          headers: authHeaders,
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 30), // ✅ Add timeout
        );

    return _decodeResponse(response);
  }

  // UPDATE GUEST
  static Future<Map<String, dynamic>> updateGuest({
    required int guestId,
    String? name,
    String? email,
    String? phone,
    bool? plusOneAllowed,
    String? plusOneName,
    String? dietaryRestrictions,
    String? notes,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (plusOneAllowed != null) body['plus_one_allowed'] = plusOneAllowed;
    if (plusOneName != null) body['plus_one_name'] = plusOneName;
    if (dietaryRestrictions != null) {
      body['dietary_restrictions'] = dietaryRestrictions;
    }
    if (notes != null) body['notes'] = notes;

    final response = await http.put(
      Uri.parse('$baseUrl/client/guests/$guestId'),
      headers: authHeaders,
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  // DELETE GUEST
  static Future<Map<String, dynamic>> deleteGuest(int guestId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/client/guests/$guestId'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // RESEND INVITATION TO GUEST
  static Future<Map<String, dynamic>> resendInvitation(int guestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/client/guests/$guestId/resend'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // CHECK IN GUEST
  static Future<Map<String, dynamic>> checkInGuest(int guestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/client/guests/$guestId/check-in'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // UNDO CHECK IN
  static Future<Map<String, dynamic>> undoCheckIn(int guestId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/client/guests/$guestId/check-in'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET RSVP DETAILS BY TOKEN
  static Future<Map<String, dynamic>> getRsvpDetails(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rsvp/$token'),
      headers: publicHeaders, // No auth needed
    );
    return _decodeResponse(response);
  }

  // SUBMIT RSVP RESPONSE
  static Future<Map<String, dynamic>> submitRsvp({
    required String token,
    required String rsvpStatus, // 'accepted' or 'declined'
    String? plusOneName,
    String? dietaryRestrictions,
    String? message,
  }) async {
    final body = <String, dynamic>{'rsvp_status': rsvpStatus};

    if (plusOneName != null) body['plus_one_name'] = plusOneName;
    if (dietaryRestrictions != null) {
      body['dietary_restrictions'] = dietaryRestrictions;
    }
    if (message != null) body['rsvp_message'] = message;

    final response = await http.post(
      Uri.parse('$baseUrl/rsvp/$token'),
      headers: publicHeaders, // No auth needed
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  // GET events with messages preview
  static Future<Map<String, dynamic>> getMessagesEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/messages/events'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET messages for a specific event
  static Future<Map<String, dynamic>> getMessages(int eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/events/$eventId/messages'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // SEND a message to planner
  static Future<Map<String, dynamic>> sendMessage({
    required int eventId,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/client/events/$eventId/messages'),
      headers: authHeaders,
      body: jsonEncode({'message': message}),
    );
    return _decodeResponse(response);
  }

  // DELETE all messages for an event
  static Future<Map<String, dynamic>> deleteAllMessages(int eventId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/client/events/$eventId/messages'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET notifications
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/notifications?page=$page&per_page=$perPage'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET notification stats
  static Future<Map<String, dynamic>> getNotificationStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/notifications/stats'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET unread count only
  static Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/notifications/unread-count'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // MARK notification as read
  static Future<Map<String, dynamic>> markNotificationRead(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/client/notifications/$id/read'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // ARCHIVE notification
  static Future<Map<String, dynamic>> archiveNotification(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/client/notifications/$id/archive'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // MARK ALL as read
  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final response = await http.post(
      Uri.parse('$baseUrl/client/notifications/read-all'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // ARCHIVE ALL notifications
  static Future<Map<String, dynamic>> archiveAllNotifications() async {
    final response = await http.post(
      Uri.parse('$baseUrl/client/notifications/archive-all'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> markClientEventMessagesAsRead(
    int eventId,
  ) async {
    final uri = Uri.parse('$baseUrl/client/messages/events/$eventId/read');

    final response = await http.post(uri, headers: authHeaders);

    return _decodeResponse(response);
  }

  // PLANNER IN GENERAL
  //
  //
  //
  //
  //

  // GET planner dashboard (weekly calendar with events)
  static Future<Map<String, dynamic>> getPlannerDashboard({
    String? date,
  }) async {
    String url = '$baseUrl/planner/dashboard';
    if (date != null) {
      url += '?date=$date';
    }
    final response = await http.get(Uri.parse(url), headers: authHeaders);
    return _decodeResponse(response);
  }

  // GET events for a specific day
  static Future<Map<String, dynamic>> getPlannerDayEvents(String date) async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/dashboard/events/$date'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET pending client requests
  static Future<Map<String, dynamic>> getPlannerRequests({
    String? filter,
    String? sort,
    String? search,
    int? perPage,
  }) async {
    final params = <String, String>{};
    if (filter != null) params['filter'] = filter;
    if (sort != null) params['sort'] = sort;
    if (search != null) params['search'] = search;
    if (perPage != null) params['per_page'] = perPage.toString();

    final uri = Uri.parse(
      '$baseUrl/planner/requests',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri, headers: authHeaders);
    return _decodeResponse(response);
  }

  // GET request stats
  static Future<Map<String, dynamic>> getPlannerRequestStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/requests/stats'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // ACCEPT a client request
  static Future<Map<String, dynamic>> acceptPlannerRequest(
    String eventId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planner/requests/$eventId/accept'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // DECLINE a client request
  static Future<Map<String, dynamic>> declinePlannerRequest(
    String eventId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planner/requests/$eventId/decline'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  //get all vendors for an event
  static Future<Map<String, dynamic>> getVendors(String eventId) async {
    debugPrint('>>> token is: $_token');
    final response = await http.get(
      Uri.parse('$baseUrl/planner/events/$eventId/vendors'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  //get single vendor for an event
  static Future<Map<String, dynamic>> getVendor(
    String eventId,
    String vendorId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/planner/events/$eventId/vendors/$vendorId"),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  //get favorite vendors for an event
  static Future<Map<String, dynamic>> getFavoriteVendors(String eventId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/planner/events/$eventId/vendors/favorites"),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  //toggle favorite status of a vendor for an event
  static Future<Map<String, dynamic>> toggleFavoriteVendor(
    String eventId,
    String vendorId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/planner/events/$eventId/vendors/$vendorId/favorite"),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // remove a vendor from favorites
  static Future<Map<String, dynamic>> removeFavoriteVendor(
    String eventId,
    String vendorId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/planner/events/$eventId/vendors/$vendorId/favorite'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getPlannerNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/notifications'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET notification stats (total_today, unread, urgent)
  static Future<Map<String, dynamic>> getPlannerNotificationStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/notifications/stats'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // MARK single notification as read
  static Future<Map<String, dynamic>> markPlannerNotificationRead(
    int id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planner/notifications/$id/read'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // ARCHIVE single notification (swipe to dismiss)
  static Future<Map<String, dynamic>> archivePlannerNotification(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planner/notifications/$id/archive'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // MARK ALL notifications as read
  static Future<Map<String, dynamic>> markAllPlannerNotificationsRead() async {
    final response = await http.post(
      Uri.parse('$baseUrl/planner/notifications/mark-all-read'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // DELETE ALL active notifications (Clear button)
  static Future<Map<String, dynamic>> deleteAllPlannerNotifications() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/planner/notifications'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET planner events list
  static Future<Map<String, dynamic>> getPlannerEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/events'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // UPDATE event status
  static Future<Map<String, dynamic>> updateEventStatus(
    int eventId,
    String status,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/planner/events/$eventId/status'),
      headers: authHeaders,
      body: jsonEncode({'status': status}),
    );
    return _decodeResponse(response);
  }

  // GET tasks for a specific event
  static Future<Map<String, dynamic>> getEventTasks(int eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/events/$eventId/tasks'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // CREATE a task for an event
  static Future<Map<String, dynamic>> createTask({
    required int eventId,
    required String title,
    String? description,
    required String priority,
    String? dueDate,
    int? progress,
    int? assistantId,
    List<int>? vendorIds,
  }) async {
    final body = <String, dynamic>{'title': title, 'priority': priority};
    if (description != null) body['description'] = description;
    if (dueDate != null) body['due_date'] = dueDate;
    if (progress != null) body['progress'] = progress;
    if (assistantId != null) body['assistant_id'] = assistantId;
    if (vendorIds != null) body['vendor_ids'] = vendorIds;

    final response = await http.post(
      Uri.parse('$baseUrl/planner/events/$eventId/tasks'),
      headers: authHeaders,
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  // UPDATE a task
  static Future<Map<String, dynamic>> updateTask({
    required int taskId,
    String? title,
    String? description,
    String? priority,
    String? dueDate,
    int? progress,
    String? status,
    int? assistantId,
    List<int>? vendorIds,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (priority != null) body['priority'] = priority;
    if (dueDate != null) body['due_date'] = dueDate;
    if (progress != null) body['progress'] = progress;
    if (status != null) body['status'] = status;
    if (assistantId != null) body['assistant_id'] = assistantId;
    if (vendorIds != null) body['vendor_ids'] = vendorIds;

    final response = await http.put(
      Uri.parse('$baseUrl/planner/tasks/$taskId'),
      headers: authHeaders,
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  // UPDATE task status
  static Future<Map<String, dynamic>> updateTaskStatus(
    int taskId,
    String status,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/planner/tasks/$taskId/status'),
      headers: authHeaders,
      body: jsonEncode({'status': status}),
    );
    return _decodeResponse(response);
  }

  // DELETE a task
  static Future<Map<String, dynamic>> deleteTask(int taskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/planner/tasks/$taskId'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET list of assistants
  static Future<Map<String, dynamic>> getAssistants() async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/assistants'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  //messages
  static Future<Map<String, dynamic>> getPlannerMessagesEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/messages/events'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET planner messages for a specific event
  static Future<Map<String, dynamic>> getPlannerMessages(int eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/events/$eventId/messages'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> sendPlannerMessage({
    required int eventId,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planner/events/$eventId/messages'),
      headers: authHeaders,
      body: jsonEncode({'message': message}),
    );
    return _decodeResponse(response);
  }

  // DELETE all planner messages for an event
  static Future<Map<String, dynamic>> deleteAllPlannerMessages(
    int eventId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/planner/events/$eventId/messages'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  //analytics
  static Future<Map<String, dynamic>> getPlannerAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/analytics'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET event details for planner
  static Future<Map<String, dynamic>> getPlannerEvent(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/events/$id'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET planner monthly calendar
  static Future<Map<String, dynamic>> getPlannerMonthlyCalendar({
    String? month, // format: 2026-06
    String? date, // format: 2026-06-26
  }) async {
    final params = <String, String>{};

    if (month != null) params['month'] = month;
    if (date != null) params['date'] = date;

    final uri = Uri.parse(
      '$baseUrl/planner/monthly-calendar',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri, headers: authHeaders);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> markPlannerEventMessagesAsRead(
    int eventId,
  ) async {
    final uri = Uri.parse('$baseUrl/planner/messages/events/$eventId/read');

    final response = await http.post(uri, headers: authHeaders);

    return _decodeResponse(response);
  }

  // archive event
  static Future<Map<String, dynamic>> archivePlannerEvent(int eventId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planner/events/$eventId/archive'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  //unarchive event
  static Future<Map<String, dynamic>> unarchivePlannerEvent(int eventId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planner/events/$eventId/unarchive'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  //get archived events
  static Future<Map<String, dynamic>> getArchivedPlannerEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/planner/events/archived'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET planner profile
  static Future<Map<String, dynamic>> getPlannerProfile() async {
    final response = await http
        .get(Uri.parse('$baseUrl/planner/me'), headers: authHeaders)
        .timeout(const Duration(seconds: 10));

    return _decodeResponse(response);
  }

  // UPDATE planner profile
  static Future<Map<String, dynamic>> updatePlannerProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/planner/profile'),
          headers: authHeaders,
          body: jsonEncode({
            'name': name,
            'email': email,
            'phone': phone.trim().isEmpty ? null : phone,
          }),
        )
        .timeout(const Duration(seconds: 10));

    return _decodeResponse(response);
  }

  // UPDATE planner password
  static Future<Map<String, dynamic>> updatePlannerPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/planner/profile/password'),
          headers: authHeaders,
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));

    return _decodeResponse(response);
  }

  //Assistant
  //
  //
  //
  //
  //

  // GET assistant tasks
  static Future<Map<String, dynamic>> getAssistantTasks({
    String? filter,
  }) async {
    String url = '$baseUrl/assistant/tasks';
    if (filter != null) url += '?filter=$filter';

    final response = await http.get(Uri.parse(url), headers: authHeaders);
    return _decodeResponse(response);
  }

  // MARK task as complete
  static Future<Map<String, dynamic>> completeAssistantTask(int taskId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/assistant/tasks/$taskId/complete'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET vendors for a task
  static Future<Map<String, dynamic>> getTaskVendors(int taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/assistant/tasks/$taskId/vendors'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET vendor details (assistant)
  static Future<Map<String, dynamic>> getAssistantVendor(int vendorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/assistant/vendor/$vendorId'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // PLACE/UPDATE order
  static Future<Map<String, dynamic>> submitOrder({
    required int taskId,
    required int vendorId,
    required double price,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assistant/task/$taskId/vendor/$vendorId/order'),
      headers: authHeaders,
      body: jsonEncode({'price': price, 'notes': notes}),
    );
    return _decodeResponse(response);
  }

  // GET my orders
  static Future<Map<String, dynamic>> getMyOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/assistant/orders'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET assistant dashboard
  static Future<Map<String, dynamic>> getAssistantDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/assistant/dashboard'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET assigned vendors for an event
  static Future<Map<String, dynamic>> getAssignedVendors(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/client/events/$eventId/assigned-vendors'),
        headers: authHeaders,
      );
      return _decodeResponse(response);
    } catch (e) {
      throw Exception('Failed to load assigned vendors');
    }
  }

  static Future<Map<String, dynamic>> deleteOrder(int orderId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/assistant/orders/$orderId'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET assistant notifications
  static Future<Map<String, dynamic>> getAssistantNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/assistant/notifications?page=$page&per_page=$perPage',
      ),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // GET assistant notification stats
  static Future<Map<String, dynamic>> getAssistantNotificationStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/assistant/notifications/stats'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // MARK single notification as read
  static Future<Map<String, dynamic>> markAssistantNotificationRead(
    int id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assistant/notifications/$id/read'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // MARK ALL as read
  static Future<Map<String, dynamic>>
  markAllAssistantNotificationsRead() async {
    final response = await http.post(
      Uri.parse('$baseUrl/assistant/notifications/read-all'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // ARCHIVE notification
  static Future<Map<String, dynamic>> archiveAssistantNotification(
    int id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assistant/notifications/$id/archive'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // ARCHIVE ALL notifications
  static Future<Map<String, dynamic>> archiveAllAssistantNotifications() async {
    final response = await http.post(
      Uri.parse('$baseUrl/assistant/notifications/archive-all'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  //shared setting for all roles

  // GET current settings
  static Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings'),
      headers: authHeaders,
    );
    return _decodeResponse(response);
  }

  // TOGGLE / UPDATE in-app alerts
  static Future<Map<String, dynamic>> updateNotificationSettings({
    required bool inAppAlerts,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/settings/notifications'),
      headers: authHeaders,
      body: jsonEncode({'in_app_alerts': inAppAlerts}),
    );
    return _decodeResponse(response);
  }

  // DELETE account
  static Future<Map<String, dynamic>> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/settings/account'),
      headers: authHeaders,
    );
    final data = _decodeResponse(response);
    if (data['success'] == true) clearToken();
    return data;
  }

  // GET assistant profile
  static Future<Map<String, dynamic>> getAssistantProfile() async {
    final response = await http
        .get(Uri.parse('$baseUrl/assistant/me'), headers: authHeaders)
        .timeout(const Duration(seconds: 10));

    return _decodeResponse(response);
  }

  // UPDATE assistant profile
  static Future<Map<String, dynamic>> updateAssistantProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/assistant/profile'),
          headers: authHeaders,
          body: jsonEncode({
            'name': name,
            'email': email,
            'phone': phone.trim().isEmpty ? null : phone,
          }),
        )
        .timeout(const Duration(seconds: 10));

    return _decodeResponse(response);
  }

  // UPDATE assistant password
  static Future<Map<String, dynamic>> updateAssistantPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/assistant/profile/password'),
          headers: authHeaders,
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));

    return _decodeResponse(response);
  }
}
