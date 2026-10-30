import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent silent black screen on rendering/widget errors in release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF090D16),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Text(
                'Something went wrong:\n${details.exceptionAsString()}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  };

  try {
    await ApiConfig.initialize();
  } catch (e) {
    debugPrint('ApiConfig.initialize failed: $e');
  }

  runApp(
    const ProviderScope(
      child: FinanceApp(),
    ),
  );
}
