import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';

class CustomSnackbar {
  /// Shows a custom snackbar at the top of the screen with white text and red background
  /// This is now a wrapper around the standardized SnackbarUtils
  static void show(BuildContext context, String message) {
    SnackbarUtils.showError(context, message);
  }

  /// Convenience method for success messages
  static void showSuccess(BuildContext context, String message) {
    SnackbarUtils.showSuccess(context, message);
  }

  /// Convenience method for info messages
  static void showInfo(BuildContext context, String message) {
    SnackbarUtils.showInfo(context, message);
  }
}
