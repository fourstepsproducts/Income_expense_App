import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../features/authentication/login_screen.dart';
import '../shared/providers.dart';
import 'navigation_scaffold.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class FinanceApp extends ConsumerWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          if (!authState.isInitialized) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.vibrantBlue),
              ),
            );
          }

          if (authState.isAuthenticated) {
            return const NavigationScaffold();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
