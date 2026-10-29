/// Patient-reported diagnoses stored in the existing health-profile conditions field.
/// Exact entries are used so family history or a question about a condition cannot
/// accidentally be treated as a diagnosis.
class RecordedConditions {
  const RecordedConditions({
    this.diabetes = false,
    this.heartDisease = false,
    this.other = '',
  });

  final bool diabetes;
  final bool heartDisease;
  final String other;

  static RecordedConditions fromText(String? value) {
    var diabetes = false;
    var heartDisease = false;
    final other = <String>[];
    for (final raw in (value ?? '').split(RegExp(r'[;,\n]'))) {
      final item = raw.trim();
      final normalized = item.toLowerCase();
      if (item.isEmpty) continue;
      if (normalized == 'diabetes' ||
          normalized == 'type 1 diabetes' ||
          normalized == 'type 2 diabetes' ||
          normalized == 'diabetes (patient-reported diagnosis)' ||
          normalized == 'i have diabetes' ||
          normalized == 'i have type 1 diabetes' ||
          normalized == 'i have type 2 diabetes' ||
          normalized == 'diagnosed with diabetes' ||
          normalized == 'diagnosed with type 1 diabetes' ||
          normalized == 'diagnosed with type 2 diabetes') {
        diabetes = true;
      } else if (normalized == 'heart disease' ||
          normalized == 'heart disease (patient-reported diagnosis)' ||
          normalized == 'i have heart disease' ||
          normalized == 'diagnosed with heart disease') {
        heartDisease = true;
      } else {
        other.add(item);
      }
    }
    return RecordedConditions(
      diabetes: diabetes,
      heartDisease: heartDisease,
      other: other.join('; '),
    );
  }

  bool hasDiagnosisFor(String model) =>
      model == 'diabetes' ? diabetes : model == 'heart_disease' && heartDisease;

  String? toProfileText() {
    final entries = <String>[
      if (diabetes) 'Diabetes (patient-reported diagnosis)',
      if (heartDisease) 'Heart disease (patient-reported diagnosis)',
      if (other.trim().isNotEmpty) other.trim(),
    ];
    return entries.isEmpty ? null : entries.join('; ');
  }
}
