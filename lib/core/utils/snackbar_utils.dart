import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, Colors.green);
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, Colors.red);
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, Colors.orange);
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, Colors.blue);
  }
}