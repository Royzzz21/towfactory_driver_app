/// Validates login form fields (email: required, format; password: required).
abstract final class FormValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns a map of field name → error message. Empty map means valid.
  static Map<String, String> validateLogin({
    required String email,
    required String password,
  }) {
    final errors = <String, String>{};

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      errors['email'] = 'Enter your email';
    } else if (!_emailRegex.hasMatch(trimmedEmail)) {
      errors['email'] = 'Enter a valid email';
    }

    if (password.isEmpty) {
      errors['password'] = 'Enter your password';
    }

    return errors;
  }
}
