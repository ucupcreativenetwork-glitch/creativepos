import 'package:flutter/material.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar(
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      action: action,
      duration: duration,
      behavior: SnackBarBehavior.floating,
    ),
  );
}