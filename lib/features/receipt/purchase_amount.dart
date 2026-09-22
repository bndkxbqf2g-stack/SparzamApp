double? parsePurchaseAmount(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', '.'));
  return value != null && value.isFinite && value >= 0 ? value : null;
}
