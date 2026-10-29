/// Conservative entry checks for patient-reported measurements.
/// These limits catch likely entry errors; they do not classify health status.
class PatientMeasurementValidation {
  static double? _number(String? raw) => double.tryParse(raw?.trim() ?? '');

  static String? metabolic(String? raw, {required bool insulinDose}) {
    final value = _number(raw);
    if (value == null || !value.isFinite) {
      return insulinDose ? 'Enter an insulin dose in U.' : 'Enter a glucose reading in mg/dL.';
    }
    if (insulinDose) {
      return value <= 0 || value > 500 ? 'Enter a recorded dose greater than 0 and up to 500 U.' : null;
    }
    return value < 20 || value > 600 ? 'Enter a meter reading from 20 to 600 mg/dL.' : null;
  }

  static String? activity(String? raw, int index) {
    if ((raw ?? '').trim().isEmpty) return null;
    final value = _number(raw);
    final limits = [100000.0, 1440.0, 10000.0, 500.0];
    final units = ['steps', 'min', 'kcal', 'km'];
    if (value == null || !value.isFinite || value < 0 || value > limits[index]) {
      return 'Enter 0 to ${limits[index].toInt()} ${units[index]}.';
    }
    if (index < 2 && value != value.truncateToDouble()) {
      return 'Enter a whole number of ${units[index]}.';
    }
    return null;
  }

  static String? weight(String? raw) {
    final value = _number(raw);
    return value == null || !value.isFinite || value < 25 || value > 350
        ? 'Enter a measured weight from 25 to 350 kg.' : null;
  }

  static String? muscle(String? raw, {double? currentWeight}) {
    final value = _number(raw);
    if (value == null || !value.isFinite || value <= 0 || value > 250) {
      return 'Enter skeletal muscle greater than 0 and up to 250 kg.';
    }
    if (currentWeight != null && value > currentWeight) {
      return 'Skeletal muscle cannot exceed the recorded weight.';
    }
    return null;
  }

  static String? bodyFat(String? raw) {
    final value = _number(raw);
    return value == null || !value.isFinite || value < 1 || value > 80
        ? 'Enter body fat from 1% to 80%.' : null;
  }
}
