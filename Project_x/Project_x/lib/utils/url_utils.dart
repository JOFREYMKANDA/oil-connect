import 'package:oil_connect/backend/api/api_config.dart';

class UrlUtils {
  /// Build an absolute URL for images returned as relative paths or wrong hosts.
  /// - Returns null for empty values
  /// - If already absolute http(s), normalizes localhost host to the API host
  /// - If relative, prefixes with the origin of Config.baseUrl
  static String? absoluteImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final trimmed = value.trim();

    // Determine API origin (scheme://host[:port]) from baseUrl
    final apiUri = Uri.tryParse(Config.baseUrl);
    if (apiUri == null || !apiUri.hasScheme || apiUri.host.isEmpty) {
      return null;
    }
    final origin = Uri(scheme: apiUri.scheme, host: apiUri.host, port: apiUri.hasPort ? apiUri.port : null);

    // Already absolute
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
      // If pointing to localhost, swap host to API origin
      if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
        return parsed.replace(scheme: origin.scheme, host: origin.host, port: origin.hasPort ? origin.port : null).toString();
      }
      return trimmed;
    }

    // Relative path: ensure it starts with '/'
    final relativePath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    // Some backends store uploads under '/storage' or '/public'; do not alter the path
    return origin.toString() + relativePath;
  }
}


