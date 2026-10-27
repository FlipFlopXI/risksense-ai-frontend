import 'package:flutter/material.dart';
import 'package:medguide/services/weekly_report.dart';

class WeeklyReportButton extends StatefulWidget {
  final Future<WeeklyReport> Function() createReport;
  const WeeklyReportButton({super.key, required this.createReport});

  @override
  State<WeeklyReportButton> createState() => _WeeklyReportButtonState();
}

class _WeeklyReportButtonState extends State<WeeklyReportButton> {
  bool busy = false;

  Future<void> download() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final report = await widget.createReport();
      if (mounted) await WeeklyReportService.open(context, report);
    } catch (_) {
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: const Text('PDF Unavailable'),
                content: const Text(
                    'The weekly report could not be opened. Please try again.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Dismiss')),
                ],
              ));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return IconButton(
        tooltip: 'Download weekly report',
        onPressed: busy ? null : download,
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_rounded),
      );
  }
}
