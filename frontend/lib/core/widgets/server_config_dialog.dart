import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app/theme/app_colors.dart';
import '../config/api_config.dart';

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const ServerConfigDialog({super.key, this.onSaved});

  static Future<void> show(BuildContext context, {VoidCallback? onSaved}) {
    return showDialog(
      context: context,
      builder: (ctx) => ServerConfigDialog(onSaved: onSaved),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testMessage;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    final targetUrl = _urlController.text.trim();
    final healthUrl = targetUrl.endsWith('/api')
        ? '$targetUrl/health'
        : (targetUrl.endsWith('/') ? '${targetUrl}health' : '$targetUrl/health');

    try {
      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _testSuccess = true;
          _testMessage = 'Connected! VPS Backend is reachable (HTTP 200 OK).';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testMessage = 'Server returned HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testMessage = 'Connection failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      await ApiConfig.setCustomBaseUrl(newUrl);
      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server URL set to: $newUrl'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, color: AppColors.vibrantBlue),
          SizedBox(width: 10),
          Text(
            'Server Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configured VPS Backend (Port 5010):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.cloud_done_rounded, size: 16, color: AppColors.incomeGreen),
                  label: const Text('VPS Default (62.72.29.36:5010)', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.surfaceElevated,
                  onPressed: () {
                    _urlController.text = ApiConfig.defaultBaseUrl;
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'API Base URL',
                hintText: ApiConfig.defaultBaseUrl,
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find_rounded, size: 18),
              label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
            ),
            if (_testMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _testSuccess
                      ? AppColors.incomeGreen.withOpacity(0.15)
                      : AppColors.expenseRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess ? AppColors.incomeGreen : AppColors.expenseRed,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _testSuccess ? AppColors.incomeGreen : AppColors.expenseRed,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess ? AppColors.incomeGreen : AppColors.expenseRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ApiConfig.resetBaseUrl();
            _urlController.text = ApiConfig.defaultBaseUrl;
            setState(() {});
          },
          child: const Text('Reset to VPS', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.vibrantBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
