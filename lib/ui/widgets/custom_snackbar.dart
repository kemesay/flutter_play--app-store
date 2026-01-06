import 'package:flutter/material.dart';

class CustomSnackbar {
  /// Shows a custom snackbar at the top of the screen with white text and red background
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        duration: const Duration(seconds: 4),
        elevation: 6.0,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
