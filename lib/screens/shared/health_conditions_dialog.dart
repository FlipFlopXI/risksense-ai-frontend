import 'package:flutter/material.dart';
import 'package:medguide/services/recorded_conditions.dart';
import 'package:medguide/theme/app_theme.dart';

/// The caller persists the returned state through the patient's health-profile API.
class HealthConditionsDialog extends StatefulWidget {
  const HealthConditionsDialog({super.key, required this.initial});

  final RecordedConditions initial;

  @override
  State<HealthConditionsDialog> createState() => _HealthConditionsDialogState();
}

class _HealthConditionsDialogState extends State<HealthConditionsDialog> {
  late bool _diabetes = widget.initial.diabetes;
  late bool _heartDisease = widget.initial.heartDisease;
  late bool _otherChronic = widget.initial.other.trim().isNotEmpty;
  late final TextEditingController _other =
      TextEditingController(text: widget.initial.other);
  String? _error;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _save() {
    final description = _other.text.trim();
    if (_otherChronic && description.isEmpty) {
      setState(() => _error = 'Describe the other chronic condition.');
      return;
    }
    final state = RecordedConditions(
      diabetes: _diabetes,
      heartDisease: _heartDisease,
      other: _otherChronic ? description : '',
    );
    if ((state.toProfileText()?.length ?? 0) > 1000) {
      setState(() => _error = 'Use fewer than 1,000 characters.');
      return;
    }
    Navigator.pop(context, state);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(context).height * .84,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.heroStart, AppColors.heroEnd]),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Row(children: [
              Icon(Icons.medical_information_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                  child: Text('Update Health Conditions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700))),
            ]),
          ),
          Flexible(
              child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  'Record only conditions diagnosed by a qualified clinician. '
                  'These answers are patient reported and can be updated later.',
                  style:
                      TextStyle(color: AppColors.textSecondary, height: 1.45)),
              const SizedBox(height: 14),
              _choice(Icons.bloodtype_rounded, 'Diagnosed with diabetes',
                  _diabetes, (value) => setState(() => _diabetes = value)),
              _choice(
                  Icons.favorite_rounded,
                  'Diagnosed with heart disease',
                  _heartDisease,
                  (value) => setState(() => _heartDisease = value)),
              _choice(
                  Icons.healing_rounded,
                  'Other chronic condition',
                  _otherChronic,
                  (value) => setState(() {
                        _otherChronic = value;
                        _error = null;
                      })),
              if (_otherChronic) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _other,
                  maxLength: 800,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Specify condition or conditions',
                    hintText: 'Enter the diagnosed condition names',
                    errorText: _error,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              if (_error != null && !_otherChronic)
                Text(_error!, style: TextStyle(color: AppColors.danger)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.amber.withValues(alpha: .35)),
                ),
                child: Text(
                    'A reported diagnosis changes which guidance appears '
                    'beside risk analysis. It does not verify a diagnosis or change '
                    'your access. Speak with your clinician before acting on results.',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        height: 1.4)),
              ),
            ]),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _choice(IconData icon, String label, bool value,
          ValueChanged<bool> onChanged) =>
      Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: value
              ? AppColors.teal.withValues(alpha: .10)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: value ? AppColors.teal : AppColors.border),
        ),
        child: SwitchListTile.adaptive(
          secondary: Icon(icon,
              color: value ? AppColors.teal : AppColors.textSecondary),
          title: Text(label,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          value: value,
          activeTrackColor: AppColors.teal,
          onChanged: onChanged,
        ),
      );
}
