/// Formats numeric grades and scores nicely by rounding to 2 decimal places
/// and stripping unnecessary trailing decimals.
String formatNilai(dynamic value) {
  if (value == null) return '-';
  if (value is num) {
    double val = double.parse(value.toStringAsFixed(2));
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }
  if (value is String) {
    if (value.trim() == '-') return '-';
    final parsed = double.tryParse(value);
    if (parsed != null) {
      return formatNilai(parsed);
    }
  }
  return value.toString();
}
