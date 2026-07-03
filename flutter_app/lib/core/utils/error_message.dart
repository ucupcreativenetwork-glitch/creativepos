import '../errors/app_exception.dart';

String friendlyError(Object error) {
  if (error is AppException) {
    final message = error.message;
    if (_isFeatureUnavailable(message)) {
      return 'Fitur ini tidak tersedia di paket langganan Anda. Hubungi admin tenant.';
    }
    return message;
  }
  final text = error.toString();
  if (_isFeatureUnavailable(text)) {
    return 'Fitur ini tidak tersedia di paket langganan Anda. Hubungi admin tenant.';
  }
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text;
}

bool _isFeatureUnavailable(String text) {
  final lower = text.toLowerCase();
  return lower.contains('not available on your current subscription') ||
      lower.contains('feature ') && lower.contains('not available');
}