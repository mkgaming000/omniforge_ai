// Input validators for forms
class Validators {
  Validators._();

  static String? required(String? value, {String? label}) {
    if (value == null || value.trim().isEmpty) {
      return '${label ?? 'This field'} is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? apiKey(String? value, {String? provider}) {
    if (value == null || value.trim().isEmpty) {
      return '${provider ?? 'Provider'} API key is required';
    }
    if (value.length < 20) {
      return 'API key looks too short';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return 'Enter a valid HTTP(S) URL';
      }
    } catch (_) {
      return 'Enter a valid URL';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String? label}) {
    if (value == null) return null;
    if (value.length < min) {
      return '${label ?? 'This field'} must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String? label}) {
    if (value == null) return null;
    if (value.length > max) {
      return '${label ?? 'This field'} must be at most $max characters';
    }
    return null;
  }

  static String? numeric(String? value, {String? label}) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) {
      return '${label ?? 'This field'} must be a number';
    }
    return null;
  }

  static String? range(
    String? value,
    num min,
    num max, {
    String? label,
  }) {
    if (value == null || value.isEmpty) return null;
    final numValue = num.tryParse(value);
    if (numValue == null) {
      return '${label ?? 'This field'} must be a number';
    }
    if (numValue < min || numValue > max) {
      return '${label ?? 'This field'} must be between $min and $max';
    }
    return null;
  }

  static String? prompt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Prompt cannot be empty';
    }
    if (value.length > 32000) {
      return 'Prompt is too long (max 32000 characters)';
    }
    return null;
  }
}
