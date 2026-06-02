import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ Smart URL: automatically picks the right address per platform
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
    return jsonDecode(response.body);
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
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: authHeaders,
    );
    return jsonDecode(response.body);
  }

  // UPDATE profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: authHeaders,
      body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
    );
    return jsonDecode(response.body);
  }

  // UPDATE password
  static Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/password'),
      headers: authHeaders,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }
}
