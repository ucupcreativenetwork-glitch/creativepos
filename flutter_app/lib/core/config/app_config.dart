class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sessionTimeout = const Duration(hours: 8),
  });

  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sessionTimeout;

  static String normalizeServerUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return value;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  static String buildApiBaseUrl(String serverUrl) {
    final base = normalizeServerUrl(serverUrl);
    return '$base/api/v1';
  }
}