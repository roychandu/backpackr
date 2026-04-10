import 'package:flutter/material.dart';
import '../common_widgets/app_colors.dart';

/// Utility class for converting technical errors to user-friendly messages
class ErrorHandler {
  /// Convert any error to a user-friendly message
  static String getFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Authentication errors
    if (_isAuthError(errorString)) {
      return _getAuthErrorMessage(errorString);
    }

    // Network errors
    if (_isNetworkError(errorString)) {
      return 'Network error. Please check your internet connection';
    }

    // Permission errors
    if (_isPermissionError(errorString)) {
      return 'You don\'t have permission to access this data';
    }

    // Database errors
    if (_isDatabaseError(errorString)) {
      return _getDatabaseErrorMessage(errorString);
    }

    // Storage errors
    if (_isStorageError(errorString)) {
      return 'Failed to upload file. Please try again';
    }

    // Generic errors
    return _getGenericErrorMessage(errorString);
  }

  static bool _isAuthError(String error) {
    return error.contains('auth') ||
        error.contains('credential') ||
        error.contains('password') ||
        error.contains('email') ||
        error.contains('user');
  }

  static bool _isNetworkError(String error) {
    return error.contains('network') ||
        error.contains('connection') ||
        error.contains('timeout') ||
        error.contains('unreachable') ||
        error.contains('socketexception');
  }

  static bool _isPermissionError(String error) {
    return error.contains('permission') || error.contains('unauthorized');
  }

  static bool _isDatabaseError(String error) {
    return error.contains('database') ||
        error.contains('firebase') ||
        error.contains('index');
  }

  static bool _isStorageError(String error) {
    return error.contains('storage') || error.contains('upload');
  }

  static String _getAuthErrorMessage(String error) {
    if (error.contains('invalid-email') || error.contains('badly formatted')) {
      return 'Please enter a valid email address';
    } else if (error.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support';
    } else if (error.contains('user-not-found')) {
      return 'No account found with this email. Please register first';
    } else if (error.contains('wrong-password') ||
        error.contains('incorrect') ||
        error.contains('invalid-credential')) {
      return 'Incorrect email or password. Please try again';
    } else if (error.contains('email-already-in-use')) {
      return 'This email is already registered. Please login instead';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later';
    } else if (error.contains('requires-recent-login')) {
      return 'Please log out and log in again to perform this action';
    } else if (error.contains('expired')) {
      return 'Your session has expired. Please try again';
    } else if (error.contains('malformed')) {
      return 'Invalid credentials. Please check and try again';
    } else if (error.contains('operation-not-allowed')) {
      return 'This operation is currently disabled. Please contact support';
    } else if (error.contains('account-exists-with-different-credential')) {
      return 'An account already exists with this email using a different sign-in method';
    } else if (error.contains('canceled') || error.contains('cancelled')) {
      return 'Sign in was cancelled';
    } else if (error.contains('not available')) {
      return 'This sign-in method is not available on this device';
    }

    return 'Authentication failed. Please try again';
  }

  static String _getDatabaseErrorMessage(String error) {
    if (error.contains('permission-denied') ||
        error.contains('permission denied')) {
      return 'You don\'t have permission to access this data';
    } else if (error.contains('index-not-defined')) {
      return 'Database error. Please contact support';
    } else if (error.contains('disconnected')) {
      return 'Lost connection to server. Please try again';
    } else if (error.contains('not found')) {
      return 'The requested data could not be found';
    }

    return 'Failed to load data. Please try again';
  }

  static String _getGenericErrorMessage(String error) {
    if (error.contains('not found')) {
      return 'The requested item could not be found';
    } else if (error.contains('already exists')) {
      return 'This item already exists';
    } else if (error.contains('invalid')) {
      return 'Invalid data. Please check your input';
    } else if (error.contains('failed')) {
      return 'Operation failed. Please try again';
    } else if (error.contains('image') || error.contains('photo')) {
      return 'Failed to process image. Please try again';
    }

    return 'Something went wrong. Please try again';
  }

  /// Show a user-friendly snackbar with error message
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getFriendlyErrorMessage(error)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show an info snackbar
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show a warning snackbar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }
}
