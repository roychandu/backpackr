import '../aws/aws_module.dart';

/// Utility class for handling business logo operations
///
/// This class provides helper methods for working with business logos that are stored
/// as AWS S3 keys instead of base64 strings.
///
/// Example usage:
/// ```dart
/// // Get the full URL for a logo
/// String url = LogoUtils.getLogoUrl(logoKey);
///
/// // Generate a unique filename for new logos
/// String filename = LogoUtils.generateLogoFileName();
///
/// // Check if it's a valid logo key
/// bool isValid = LogoUtils.isValidLogoKey(logoKey);
/// ```
class LogoUtils {
  /// Get the full URL for a logo from its AWS key
  static String getLogoUrl(String logoKey) {
    return getUrlForUserUploadedImage(logoKey);
  }

  /// Generate a unique filename for new logos
  static String generateLogoFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return "businesslogo_$timestamp.jpg";
  }

  /// Check if the logo key is a valid AWS key
  static bool isValidLogoKey(String key) {
    return key.isNotEmpty && !key.startsWith('/');
  }

  /// Check if the logo is stored as base64 (legacy format)
  static bool isBase64Logo(String logo) {
    // Base64 strings are typically longer and contain alphanumeric characters
    return logo.length > 100 && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(logo);
  }

  /// Extract filename from AWS key
  static String getFileNameFromKey(String key) {
    final parts = key.split('/');
    return parts.isNotEmpty ? parts.last : key;
  }
}
