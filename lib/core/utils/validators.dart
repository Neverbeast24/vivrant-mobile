String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email is required';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  if (!ok) return 'Enter a valid email';
  return null;
}

String? validatePassword(String? value, {int minLength = 8}) {
  final v = value ?? '';
  if (v.isEmpty) return 'Password is required';
  if (v.length < minLength) {
    return 'Password must be at least $minLength characters';
  }
  return null;
}
