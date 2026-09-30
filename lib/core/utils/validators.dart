/// Pure validation functions used by form fields. Each returns an error
/// message, or `null` when the value is valid.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? employeeId(String? value) {
    final base = required(value, field: 'Employee ID');
    if (base != null) return base;
    if (!RegExp(r'^[A-Za-z]{2,5}\d{3,6}$').hasMatch(value!.trim())) {
      return 'Use the format emp001';
    }
    return null;
  }

  static String? password(String? value) {
    final base = required(value, field: 'Password');
    if (base != null) return base;
    if (value!.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? amount(String? value, {double max = 1000000}) {
    final base = required(value, field: 'Amount');
    if (base != null) return base;
    final parsed = double.tryParse(value!.trim().replaceAll(',', ''));
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Amount must be greater than zero';
    if (parsed > max) return 'Amount cannot exceed $max';
    return null;
  }

  static String? description(String? value, {int min = 10, int max = 300}) {
    final base = required(value, field: 'Description');
    if (base != null) return base;
    final trimmed = value!.trim();
    if (trimmed.length < min) return 'Describe the expense in at least $min characters';
    if (trimmed.length > max) return 'Keep the description under $max characters';
    return null;
  }

  static String? claimDate(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Select the expense date';
    final today = now ?? DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);
    if (value.isAfter(endOfToday)) return 'Expense date cannot be in the future';
    if (value.isBefore(today.subtract(const Duration(days: 365)))) {
      return 'Claims older than one year cannot be submitted';
    }
    return null;
  }
}