String resolveMediaUrl(String? url, String? serverUrl) {
  if (url == null || url.isEmpty) return '';
  if (serverUrl != null && serverUrl.isNotEmpty) {
    final base = serverUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.hasScheme &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return '$base${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
    }
    if (url.startsWith('/')) return '$base$url';
  }
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (serverUrl == null || serverUrl.isEmpty) return url;
  final base = serverUrl.replaceAll(RegExp(r'/+$'), '');
  if (url.startsWith('/')) return '$base$url';
  return '$base/$url';
}