import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

/// Auth API routes for MemFlow.
/// Handles register, login, token refresh, profile, and password operations.
class AuthApiRoutes {
  static const String _baseUrl = '${ApiConfig.baseUrl}/api/auth';

  // ── Register ──────────────────────────────────────────────────────────────

  /// Register a new user account.
  /// Returns a map with 'user' on success, or throws on failure.
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String role = 'analyst',
    String? adminCode,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            'role': role,
            if (adminCode != null && adminCode.isNotEmpty) 'admin_code': adminCode,
          }),
        )
        .timeout(ApiConfig.connectionTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed.');
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Login with email + password.
  /// Returns { 'access_token', 'refresh_token', 'user' } on success.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(ApiConfig.connectionTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed.');
    }
  }

  // ── Refresh Token ─────────────────────────────────────────────────────────

  /// Exchange a refresh token for a new access token.
  /// Returns { 'access_token' } on success.
  static Future<Map<String, dynamic>> refreshToken(
      String refreshToken) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/refresh'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $refreshToken',
          },
        )
        .timeout(ApiConfig.connectionTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Token refresh failed.');
    }
  }

  // ── Current User ──────────────────────────────────────────────────────────

  /// Get the currently authenticated user's profile.
  static Future<Map<String, dynamic>> getMe(String accessToken) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        )
        .timeout(ApiConfig.connectionTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data['user'] as Map<String, dynamic>;
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch profile.');
    }
  }

  // ── Change Password ───────────────────────────────────────────────────────

  /// Change the authenticated user's password.
  static Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/change-password'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Password change failed.');
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  /// Request a password reset token for the given email.
  /// Returns the reset_token (in production this would be sent via email).
  static Future<Map<String, dynamic>> requestPasswordReset(
      String email) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(ApiConfig.connectionTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Password reset request failed.');
    }
  }

  /// Confirm a password reset using a reset token + new password.
  static Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/reset-password/confirm'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'reset_token': resetToken,
            'new_password': newPassword,
          }),
        )
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Password reset failed.');
    }
  }
}
