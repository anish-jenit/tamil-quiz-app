class Validators {
  static final RegExp _usernameRegExp =
      RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9_]{1,18})[a-zA-Z0-9]$');

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username required';
    }
    final v = value.trim();
    if (v.length < 3 || v.length > 20) {
      return 'Must be 3-20 characters';
    }
    if (!_usernameRegExp.hasMatch(v)) {
      return 'Only letters, numbers and underscore; cannot start or end with underscore';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email required';
    }
    final v = value.trim();
    final emailRE = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRE.hasMatch(v)) {
      return 'Enter a valid email';
    }
    return null;
  }
}
