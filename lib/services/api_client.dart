/// Central authenticated HTTP client for MemFlow.
///
/// The AuthProvider calls [ApiClient.setToken] after a successful login.
/// All API route files call [ApiClient.headers] to get headers with the
/// Authorization token automatically included.
///
/// Usage in API route files:
///   final response = await http.get(uri, headers: ApiClient.headers);
class ApiClient {
  ApiClient._(); // prevent instantiation

  static String? _token;

  /// Called by AuthProvider right after login/register/token refresh.
  static void setToken(String? token) {
    _token = token;
  }

  /// Clear the token on logout.
  static void clearToken() {
    _token = null;
  }

  /// Returns headers with Content-Type + Authorization (if token is set).
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Returns headers for multipart requests (no Content-Type — http sets it).
  static Map<String, String> get multipartHeaders => {
        if (_token != null) 'Authorization': 'Bearer $_token',
      };
}
