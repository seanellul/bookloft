import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      'https://morning-voice-2fb9.hp-230.workers.dev/api';
  static const Duration timeout = Duration(seconds: 30);

  // Login with email and password
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          // Store token and user info
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseData['data']['token']);
          await prefs.setString(
              'user_name', responseData['data']['volunteer']['name']);
          await prefs.setString(
              'user_id', responseData['data']['volunteer']['id']);

          return {
            'success': true,
            'user': responseData['data']['volunteer'],
            'token': responseData['data']['token'],
          };
        } else {
          return {
            'success': false,
            'error': responseData['error']?['message'] ?? 'Login failed',
          };
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error']?['message'] ??
              'Login failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  // Get current user info
  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final name = prefs.getString('user_name');
    final id = prefs.getString('user_id');

    if (token != null && name != null && id != null) {
      return {
        'token': token,
        'name': name,
        'id': id,
      };
    }
    return null;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_id');
  }

  // Get auth headers for API requests
  static Future<Map<String, String>> getAuthHeaders() async {
    final user = await getCurrentUser();
    if (user != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${user['token']}',
      };
    }
    return {'Content-Type': 'application/json'};
  }
}
