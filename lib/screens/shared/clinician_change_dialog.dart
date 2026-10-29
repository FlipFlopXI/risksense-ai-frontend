import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/app_form_dialog.dart';

class ClinicianChangeDialog extends StatefulWidget {
  const ClinicianChangeDialog({super.key});
  @override
  State<ClinicianChangeDialog> createState() => _ClinicianChangeDialogState();
}

class _ClinicianChangeDialogState extends State<ClinicianChangeDialog> {
  final id = TextEditingController();
  Map<String, dynamic>? clinician;
  Map<String, dynamic>? pending;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final row = Map<String, dynamic>.from(
          await ApiClient.instance.get('/patients/me/clinician-change-request'));
      if (mounted) setState(() => pending = row);
    } on ApiException catch (e) {
      if (mounted && e.statusCode != 404) setState(() => error = e.message);
    }
  }

  Future<void> _lookup() async {
    final value = id.text.trim().toUpperCase();
    if (!RegExp(r'^RS-CLN-[0-9]{5}$').hasMatch(value)) {
      setState(() => error = 'Enter an ID in the form RS-CLN-12345.');
      return;
    }
    setState(() { busy = true; error = null; clinician = null; });
    try {
      final row = Map<String, dynamic>.from(await ApiClient.instance.get(
          '/patients/clinicians/lookup/$value'));
      if (mounted) setState(() => clinician = row);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.statusCode == 404
          ? 'No active, approved clinician has that ID.' : e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _request() async {
    if (clinician == null || clinician!['risk_sense_id'] != id.text.trim().toUpperCase()) return;
    setState(() { busy = true; error = null; });
    try {
      final row = Map<String, dynamic>.from(await ApiClient.instance.post(
          '/patients/me/clinician-change-request',
          data: {'risk_sense_id': clinician!['risk_sense_id']}));
      if (mounted) setState(() => pending = row);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppFormDialog(
      icon: Icons.medical_services_outlined,
      title: const Text('Request a New Clinician'),
      content: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your current clinician keeps access until an administrator approves a replacement.',
            style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          if (pending != null) ...[
            _identityCard('Request pending review', pending!['new_clinician'] as Map),
            const SizedBox(height: 8),
            Text('You will remain linked to your current clinician until this request is approved.',
              style: TextStyle(color: AppColors.textSecondary)),
          ] else ...[
            TextField(controller: id,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(12)],
              decoration: const InputDecoration(labelText: 'New RiskSense clinician ID',
                hintText: 'RS-CLN-12345'),
              onChanged: (_) => setState(() { clinician = null; error = null; })),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: busy ? null : _lookup,
              icon: const Icon(Icons.search_rounded), label: const Text('Find Clinician')),
            if (clinician != null) ...[
              const SizedBox(height: 12),
              _identityCard('Requested clinician', clinician!),
            ],
          ],
          if (busy) const LinearProgressIndicator(),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: AppColors.danger))),
        ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        if (pending == null) FilledButton(onPressed: busy || clinician == null ? null : _request,
          child: const Text('Submit Request')),
      ],
    );
  }

  Widget _identityCard(String title, Map details) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryBlue.withValues(alpha: .35))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
      const SizedBox(height: 7),
      Text('${details['display_name'] ?? 'Name unavailable'}', style: TextStyle(color: AppColors.textPrimary)),
      Text('${details['institution'] ?? 'Institution not recorded'}', style: TextStyle(color: AppColors.textSecondary)),
      Text('${details['risk_sense_id'] ?? ''}', style: TextStyle(color: AppColors.textSecondary)),
    ]),
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
