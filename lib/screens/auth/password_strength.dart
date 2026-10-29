enum PasswordStrength { veryWeak, weak, moderate, strong }

PasswordStrength classifyRegistrationPassword(
    String password, String fullName) {
  if (password.length < 6 ||
      password.length > 128 ||
      !RegExp(r'[A-Z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password) ||
      !RegExp(r'[^A-Za-z0-9\s]').hasMatch(password)) {
    return PasswordStrength.veryWeak;
  }
  final lowerPassword = password.toLowerCase();
  final names = fullName.trim().toLowerCase().split(RegExp(r'\s+'));
  if (names.any((name) => name.isNotEmpty && lowerPassword.contains(name))) {
    return PasswordStrength.weak;
  }
  if (RegExp(r'[A-Za-z]').allMatches(password).length == 1) {
    return PasswordStrength.moderate;
  }
  return PasswordStrength.strong;
}
