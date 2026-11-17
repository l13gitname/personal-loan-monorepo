/// Prisma serialises `Decimal` columns as JSON strings ("50000.00"); accept
/// both numbers and numeric strings.
double? doubleFromJson(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double doubleRequiredFromJson(Object? value) => doubleFromJson(value) ?? 0;

/// ISO date-time from the API -> `yyyy-MM-dd` used by the form/DTO.
String? dateOnlyFromJson(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.length >= 10 ? text.substring(0, 10) : text;
}
