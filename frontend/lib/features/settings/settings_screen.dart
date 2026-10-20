import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../shared/providers.dart';
import '../categories/categories_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _openCurrencyPicker() {
    final currentCurrency = ref.read(currencyProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...AppConstants.currencySymbols.entries.map((e) {
                final isSelected = e.key == currentCurrency;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.vibrantBlue.withOpacity(0.2) : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.vibrantBlue : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  title: Text(
                    '${e.key} - ${e.value}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      color: isSelected ? AppColors.vibrantBlue : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.vibrantBlue) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(currencyProvider.notifier).setCurrency(e.key);
                    await ref.read(authProvider.notifier).updateProfile(currency: e.key);
                    ref.invalidate(dashboardSummaryProvider);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _openServerUrlConfig() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Server API URL', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the REST API endpoint (e.g. for Android emulator use http://10.0.2.2:5000/api)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'API Base URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiConfig.resetBaseUrl();
              if (mounted) setState(() {});
            },
            child: const Text('Reset Default', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              Navigator.pop(ctx);
              await ApiConfig.setCustomBaseUrl(newUrl);
              if (mounted) setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to log out of your personal finance account?',
      confirmText: 'Sign Out',
      confirmColor: AppColors.expenseRed,
    );

    if (confirmed && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // User Profile Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.accentCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User Profile',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Preferences Header
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'PREFERENCES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
            ),
          ),

          // Currency Selection
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.accentCyan),
                  title: const Text('Display Currency', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    'Active: $currency (${AppConstants.currencySymbols[currency] ?? ''})',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: _openCurrencyPicker,
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.category_rounded, color: AppColors.vibrantBlue),
                  title: const Text('Category Management', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Custom categories, colors & icons', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                  },
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded, color: AppColors.accentCyan),
                  title: const Text('Theme', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Deep Navy & Black (Active)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Dark Mode', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Data & System Header
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SYSTEM & NETWORK',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
            ),
          ),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync_rounded, color: AppColors.incomeGreen),
                  title: const Text('Refresh Financial Data', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Sync live records from MongoDB backend', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
                  onTap: () {
                    ref.invalidate(dashboardSummaryProvider);
                    ref.invalidate(categoriesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Financial cache refreshed'), backgroundColor: AppColors.info),
                    );
                  },
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.dns_rounded, color: AppColors.vibrantBlue),
                  title: const Text('API Endpoint Configuration', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(ApiConfig.baseUrl, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                  onTap: _openServerUrlConfig,
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                  title: const Text('Application Version', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('${AppConstants.appName} v${AppConstants.appVersion}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sign Out Button
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            tileColor: AppColors.surface,
            leading: const Icon(Icons.logout_rounded, color: AppColors.expenseRed),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.expenseRed, fontWeight: FontWeight.w600),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
