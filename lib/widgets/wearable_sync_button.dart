import 'package:flutter/material.dart';
import 'package:medguide/services/vital_sync.dart';
import 'package:medguide/theme/app_theme.dart';

class WearableSyncButton extends StatelessWidget {
  const WearableSyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return IconButton(
        tooltip: 'Sync incoming wearable vitals',
        icon:  Icon(Icons.watch_rounded, color: AppColors.teal),
        onPressed: () => showWearableSyncDialog(context),
      );
  }
}

Future<void> showWearableSyncDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _SyncDialog(),
    );

class _SyncDialog extends StatefulWidget {
  const _SyncDialog();
  @override
  State<_SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<_SyncDialog> {
  bool _pulse = false;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AnimatedBuilder(
        animation: VitalSync.instance,
        builder: (context, _) {
          final sync = VitalSync.instance;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Wearable Vitals'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween:
                    Tween(begin: _pulse ? 1.0 : .84, end: _pulse ? .84 : 1.0),
                duration: const Duration(milliseconds: 850),
                onEnd: () {
                  if (mounted) setState(() => _pulse = !_pulse);
                },
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 98,
                  height: 98,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceTeal,
                      border: Border.all(
                          color: AppColors.teal.withValues(alpha: .5),
                          width: 2)),
                  child: Icon(
                      sync.listening
                          ? Icons.monitor_heart_rounded
                          : Icons.watch_rounded,
                      color: AppColors.teal,
                      size: 48),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                  sync.listening
                      ? sync.receiving
                          ? 'Receiving new readings…'
                          : 'Listening for new readings'
                      : 'Connect your wearable to a service that sends readings to RiskSense, then start listening here.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
               Text(
                  'This app displays actual patient vital records received by the backend. Starting this view does not pair a device or create measurements.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (sync.error != null) ...[
                const SizedBox(height: 10),
                Text(sync.error!,
                    style:  TextStyle(color: AppColors.danger)),
              ],
            ]),
            actions: [
              if (sync.listening)
                TextButton.icon(
                  onPressed: () {
                    sync.stop();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.link_off_rounded),
                  label: const Text('End Sync'),
                ),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
              if (!sync.listening)
                FilledButton(
                  onPressed: sync.busy
                      ? null
                      : () async {
                          await sync.start();
                        },
                  child: Text(sync.busy ? 'Connecting…' : 'Confirm Sync'),
                ),
            ],
          );
        },
      );
  }
}
