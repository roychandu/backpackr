import 'package:backpackr/shared/services/upload/aws_module.dart';

///
/// This class provides helper methods for working with attachments that are stored
/// as AWS S3 keys instead of local file paths.
///
/// Example usage:
/// ```dart
/// // Get the full URL for an attachment
/// String url = AttachmentUtils.getAttachmentUrl(attachmentKey);
///
/// // Get the filename from an AWS key
/// String filename = AttachmentUtils.getFileNameFromKey(attachmentKey);
///
/// // Check if it's a valid attachment key
/// bool isValid = AttachmentUtils.isValidAttachmentKey(attachmentKey);
/// ```
class AttachmentUtils {
  /// Get the full URL for an attachment from its AWS key
  static String getAttachmentUrl(String attachmentKey) {
    return getUrlForUserUploadedImage(attachmentKey);
  }

  /// Extract filename from AWS key
  static String getFileNameFromKey(String key) {
    final parts = key.split('/');
    return parts.isNotEmpty ? parts.last : key;
  }

  /// Check if the attachment key is a valid AWS key
  static bool isValidAttachmentKey(String key) {
    return key.isNotEmpty && !key.startsWith('/');
  }

  /// Generate a unique filename for new attachments
  static String generateAttachmentFileName(String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalFileName.split('.').last;
    return "attachment_$timestamp.$extension";
  }
}
