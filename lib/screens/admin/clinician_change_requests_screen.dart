import 'package:flutter/material.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/app_form_dialog.dart';

class ClinicianChangeRequestsScreen extends StatefulWidget {
  const ClinicianChangeRequestsScreen({super.key});
  @override
  State<ClinicianChangeRequestsScreen> createState() =>
      _ClinicianChangeRequestsScreenState();
}

class _ClinicianChangeRequestsScreenState
    extends State<ClinicianChangeRequestsScreen> {
  final Set<String> resolvedIds = {};
  late Future<List<Map<String, dynamic>>> requests = _load();
  Future<List<Map<String, dynamic>>> _load() async =>
      (await ApiClient.instance.get('/admin/clinician-change-requests') as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .where((row) => !resolvedIds.contains(row['id']?.toString()))
          .toList();
  Future<void> _refresh() async {
    final next = _load();
    setState(() => requests = next);
    await next;
  }

  Future<void> _decide(Map<String, dynamic> row, String decision) async {
    final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => AppFormDialog(
              icon: decision == 'approve'
                  ? Icons.verified_user_outlined
                  : Icons.block_outlined,
              title: Text(decision == 'approve'
                  ? 'Approve Clinician Change?'
                  : 'Reject Clinician Change?'),
              content: Text(decision == 'approve'
                  ? 'The previous clinician will lose access and the new clinician will be linked to this patient.'
                  : 'The current clinician link will remain unchanged.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: Text(decision == 'approve' ? 'Approve' : 'Reject')),
              ],
            ));
    if (approved != true || !mounted) return;
    try {
      await ApiClient.instance.post(
          '/admin/clinician-change-requests/${row['id']}/decision',
          data: {'decision': decision});
      if (!mounted) return;
      setState(() => resolvedIds.add(row['id'].toString()));
      try {
        await _refresh();
      } catch (_) {/* Keep the confirmed decision hidden. */}
    } on ApiException catch (e) {
      if (mounted) await _error(e.message);
    }
  }

  Future<void> _error(String message) => showDialog<void>(
      context: context,
      builder: (dialog) => AppFormDialog(
              icon: Icons.error_outline_rounded,
              title: const Text('Unable to Review Request'),
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Dismiss'))
              ]));

  Future<void> _details(Map<String, dynamic> row) async {
    final old = row['old_clinician'] as Map? ?? {};
    final next = row['new_clinician'] as Map? ?? {};
    await showDialog<void>(
        context: context,
        builder: (dialog) => AppFormDialog(
              icon: Icons.swap_horiz_rounded,
              title: const Text('Clinician Change Request'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Patient', [
                      '${row['patient_name'] ?? 'Name unavailable'}',
                      '${row['patient_email'] ?? 'Email unavailable'}',
                      'Patient ID: ${row['patient_id'] ?? ''}',
                    ]),
                    const SizedBox(height: 12),
                    _section('Current clinician', [
                      '${old['display_name'] ?? 'Name unavailable'}',
                      '${old['institution'] ?? 'Institution not recorded'}',
                      '${old['risk_sense_id'] ?? ''}',
                    ]),
                    const SizedBox(height: 12),
                    _section('Requested clinician', [
                      '${next['display_name'] ?? 'Name unavailable'}',
                      '${next['institution'] ?? 'Institution not recorded'}',
                      '${next['risk_sense_id'] ?? ''}',
                    ]),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Close'))
              ],
            ));
  }

  Widget _section(String title, List<String> lines) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: AppColors.surfaceBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          for (final line in lines)
            Text(line, style: TextStyle(color: AppColors.textPrimary)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Clinician Requests'),
          backgroundColor: AppColors.cardWhite),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: requests,
          builder: (context, state) {
            if (state.hasError)
              return Center(
                  child: TextButton(
                      onPressed: _refresh,
                      child: const Text(
                          'Unable to load requests. Tap to retry.')));
            if (!state.hasData)
              return const Center(child: CircularProgressIndicator());
            final rows = state.data!
                .where((row) => !resolvedIds.contains(row['id']?.toString()))
                .toList();
            return RefreshIndicator(
                onRefresh: _refresh,
                child: rows.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 160),
                        Center(
                            child:
                                Text('No pending clinician change requests.'))
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          final next = row['new_clinician'] as Map? ?? {};
                          return Card(
                              color: AppColors.cardWhite,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(children: [
                                    ListTile(
                                        onTap: () => _details(row),
                                        leading: Icon(
                                            Icons.person_search_rounded,
                                            color: AppColors.primaryBlue),
                                        title: Text(
                                            '${row['patient_name'] ?? 'Patient'}'),
                                        subtitle: Text(
                                            'Requested: ${next['display_name'] ?? 'Clinician'}'),
                                        trailing: const Icon(
                                            Icons.chevron_right_rounded)),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                              onPressed: () =>
                                                  _decide(row, 'reject'),
                                              child: const Text('Reject')),
                                          const SizedBox(width: 8),
                                          FilledButton(
                                              onPressed: () =>
                                                  _decide(row, 'approve'),
                                              child: const Text('Approve')),
                                        ]),
                                  ])));
                        }));
          }),
    );
  }
}
