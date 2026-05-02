import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
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

  // REGISTER — now includes phone, and role is 'client' or 'planner'
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role, // must be 'client' or 'planner'
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

  // GET event types and planners for create form
  static Future<Map<String, dynamic>> getCreateData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/events/create-data'),
      headers: authHeaders,
    );
    return jsonDecode(response.body);
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
