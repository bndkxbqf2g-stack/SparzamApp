class DiagnosticLogEntry {
  const DiagnosticLogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    this.details,
  });

  final DateTime timestamp;
  final String category;
  final String message;
  final String? details;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'category': category,
        'message': message,
        'details': details,
      };

  factory DiagnosticLogEntry.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.parse(json['timestamp'] as String);
    final category = json['category'] as String;
    final message = json['message'] as String;
    if (category.trim().isEmpty || message.trim().isEmpty) {
      throw const FormatException('Ungültiger Diagnoseeintrag');
    }
    return DiagnosticLogEntry(
      timestamp: timestamp,
      category: category,
      message: message,
      details: json['details'] as String?,
    );
  }
}
