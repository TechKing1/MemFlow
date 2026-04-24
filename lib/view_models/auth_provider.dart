import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api-routes/auth/auth_api_routes.dart';
import '../services/api_client.dart';

/// Manages JWT tokens and authenticated user state.
///
/// - Persists access + refresh tokens in SharedPreferences
/// - Auto-loads tokens on app startup
/// - Silently refreshes the access token using the refresh token
/// - Exposes isAuthenticated, user info, and role helpers
class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get username => _user?['username'] as String? ?? 'Unknown';
  String get email => _user?['email'] as String? ?? '';
  String get userRole => _user?['role'] as String? ?? 'analyst';
  bool get isAdmin => userRole == 'admin';

  // ── Startup: load persisted tokens ───────────────────────────────────────

  /// Tokens are session-only — not persisted to disk.
  /// loadFromStorage() is a no-op now, kept for API compatibility.
  Future<void> loadFromStorage() async {
    // Intentionally empty: tokens are session-only.
    // The app always requires login on every launch.
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String role = 'analyst',
    String? adminCode,
  }) async {
    _setLoading(true);
    try {
      await AuthApiRoutes.register(
        username: username,
        email: email,
        password: password,
        role: role,
        adminCode: adminCode,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    _setLoading(true);
    try {
      final data = await AuthApiRoutes.login(email: email, password: password);

      _accessToken  = data['access_token']  as String;
      _refreshToken = data['refresh_token'] as String;
      _user         = data['user']          as Map<String, dynamic>;
      _errorMessage = null;

      ApiClient.setToken(_accessToken); // ← wire token for all API calls
      // NOTE: tokens are session-only — NOT persisted to disk.

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Silent Token Refresh ──────────────────────────────────────────────────

  /// Silently exchange the refresh token for a new access token.
  /// Returns true on success, false if the refresh token is also expired.
  Future<bool> _silentRefresh() async {
    if (_refreshToken == null) {
      await logout();
      return false;
    }
    try {
      final data = await AuthApiRoutes.refreshToken(_refreshToken!);
      _accessToken = data['access_token'] as String;
      ApiClient.setToken(_accessToken); // ← update token after refresh

      // Re-fetch user profile with new token
      _user = await AuthApiRoutes.getMe(_accessToken!);

      await _persistTokens();
      notifyListeners();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  /// Call this when a 401 is received from any API call.
  /// Attempts a silent refresh; returns the new access token or null.
  Future<String?> handleUnauthorized() async {
    final refreshed = await _silentRefresh();
    return refreshed ? _accessToken : null;
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _accessToken  = null;
    _refreshToken = null;
    _user         = null;
    _errorMessage = null;

    ApiClient.clearToken(); // ← clear token from all future API calls

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    notifyListeners();
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> requestPasswordReset(String email) async {
    _setLoading(true);
    try {
      final result = await AuthApiRoutes.requestPasswordReset(email);
      _errorMessage = null;
      return result;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await AuthApiRoutes.confirmPasswordReset(
        resetToken: resetToken,
        newPassword: newPassword,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _persistTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null)  await prefs.setString('access_token',  _accessToken!);
    if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
  }

  String _extractMessage(Object e) {
    final msg = e.toString();
    // Remove "Exception: " prefix added by Dart
    return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
