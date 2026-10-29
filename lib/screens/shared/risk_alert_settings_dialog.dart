import 'package:flutter/material.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/app_form_dialog.dart';

class RiskAlertSettingsDialog extends StatefulWidget {
  const RiskAlertSettingsDialog({
    super.key,
    this.loadEmailPreference,
    this.saveEmailPreference,
  });

  final Future<bool> Function()? loadEmailPreference;
  final Future<bool> Function(bool)? saveEmailPreference;

  @override
  State<RiskAlertSettingsDialog> createState() =>
      _RiskAlertSettingsDialogState();
}

class _RiskAlertSettingsDialogState extends State<RiskAlertSettingsDialog> {
  bool _loading = true;
  bool _saving = false;
  bool _emailEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<bool> _defaultLoad() async {
    final response = Map<String, dynamic>.from(await ApiClient.instance
        .get('/patients/notification-preferences') as Map);
    return response['email_elevated_results'] == true;
  }

  Future<bool> _defaultSave(bool enabled) async {
    final response = Map<String, dynamic>.from(await ApiClient.instance.patch(
        '/patients/notification-preferences',
        data: {'email_elevated_results': enabled}) as Map);
    return response['email_elevated_results'] == true;
  }

  Future<void> _load() async {
    try {
      final enabled = await (widget.loadEmailPreference ?? _defaultLoad)();
      if (mounted) setState(() => _emailEnabled = enabled);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ApiException
            ? error.message
            : 'Email preference could not be loaded. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveEmail(bool enabled) async {
    if (_saving || _loading || _error != null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await (widget.saveEmailPreference ?? _defaultSave)(enabled);
      if (mounted) setState(() => _emailEnabled = saved);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ApiException
            ? error.message
            : 'Email preference could not be saved. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveBadges(bool enabled) async {
    try {
      await AppPreferences.instance.setRiskAlerts(enabled);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Dashboard alert preference could not be saved.');
      }
    }
  }

  Widget _option({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceTeal,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.teal.withValues(alpha: .3)),
        ),
        child: SwitchListTile.adaptive(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          secondary: Icon(icon, color: AppColors.teal, size: 24),
          title: Text(title,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          subtitle: Text(description,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
          value: value,
          onChanged: onChanged,
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: AppPreferences.instance,
        builder: (context, _) => AppFormDialog(
          icon: Icons.notifications_active_outlined,
          title: const Text('Risk Result Alerts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose how you want to hear about risk analysis results.',
                  style:
                      TextStyle(color: AppColors.textSecondary, height: 1.45)),
              const SizedBox(height: 16),
              _option(
                icon: Icons.notifications_outlined,
                title: 'Dashboard Alert Badges',
                description:
                    'Show a badge for a new moderate or high result until you open that analysis.',
                value: AppPreferences.instance.riskAlerts,
                onChanged: _saveBadges,
              ),
              _option(
                icon: Icons.email_outlined,
                title: 'Email Elevated Results',
                description:
                    'Send my estimated score, contributing model factors and change from my previous score of the same type to my account email.',
                value: _emailEnabled,
                onChanged:
                    _loading || _saving || _error != null ? null : _saveEmail,
              ),
              if (_loading || _saving)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                )),
              if (_error != null) ...[
                Text(_error!,
                    style: TextStyle(color: AppColors.danger, fontSize: 12)),
                TextButton(
                    onPressed: _loading || _saving
                        ? null
                        : () {
                            setState(() {
                              _error = null;
                              _loading = true;
                            });
                            _load();
                          },
                    child: const Text('Try Again')),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(13),
                  border:
                      Border.all(color: AppColors.amber.withValues(alpha: .35)),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.privacy_tip_outlined,
                          color: AppColors.amber, size: 20),
                      const SizedBox(width: 9),
                      Expanded(
                          child: Text(
                        'Email contains sensitive health information. Enable it only if your email account is private. Scores are estimates, not diagnoses. Email delivery is off by default.',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            height: 1.4),
                      )),
                    ]),
              ),
            ],
          ),
          actions: [
            FilledButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Done')),
          ],
        ),
      );
}
