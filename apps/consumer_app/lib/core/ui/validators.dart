/// Form validators shared by all steps. Each returns an error message or null.
class Validators {
  Validators._();

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'This field is required' : null;

  static String? positiveNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'This field is required';
    final n = double.tryParse(text.replaceAll(',', ''));
    if (n == null || n <= 0) return 'Enter a number greater than 0';
    return null;
  }

  static String? nonNegativeNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final n = double.tryParse(text.replaceAll(',', ''));
    if (n == null || n < 0) return 'Enter a valid number';
    return null;
  }

  static String? positiveInt(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null || n <= 0) return 'Enter a whole number greater than 0';
    return null;
  }

  /// Thai mobile/landline number written as digits, e.g. 0812345678.
  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'This field is required';
    if (!RegExp(r'^0\d{8,9}$').hasMatch(text)) return 'Enter a valid phone number';
    return null;
  }

  /// 13 digits with the standard check digit.
  static String? thaiCitizenId(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'This field is required';
    if (!RegExp(r'^\d{13}$').hasMatch(text)) return 'Enter 13 digits';
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(text[i]) * (13 - i);
    }
    final check = (11 - sum % 11) % 10;
    return check == int.parse(text[12]) ? null : 'Invalid ID number';
  }

  static String? postalCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'This field is required';
    return RegExp(r'^\d{5}$').hasMatch(text) ? null : 'Enter 5 digits';
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'This field is required';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text) ? null : 'Enter a valid email';
  }
}
