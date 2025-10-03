/// Import operation result model
/// Handles success, error, and cancellation states for CSV imports
class ImportResult {
  final bool isSuccess;
  final bool isCancelled;
  final String message;
  final String? errorCode;
  final int successCount;
  final int errorCount;
  final List<String> errors;

  const ImportResult._({
    required this.isSuccess,
    required this.isCancelled,
    required this.message,
    this.errorCode,
    this.successCount = 0,
    this.errorCount = 0,
    this.errors = const [],
  });

  /// Create successful import result
  factory ImportResult.success({
    required String message,
    int successCount = 0,
    int errorCount = 0,
    List<String> errors = const [],
  }) {
    return ImportResult._(
      isSuccess: true,
      isCancelled: false,
      message: message,
      successCount: successCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  /// Create error import result
  factory ImportResult.error(String errorCode, String message) {
    return ImportResult._(
      isSuccess: false,
      isCancelled: false,
      message: message,
      errorCode: errorCode,
    );
  }

  /// Create cancelled import result
  factory ImportResult.cancelled() {
    return const ImportResult._(
      isSuccess: false,
      isCancelled: true,
      message: 'Import dibatalkan',
    );
  }

  /// Check if operation was successful
  bool get hasSuccess => isSuccess;

  /// Check if operation had errors
  bool get hasErrors => errorCount > 0 || (!isSuccess && !isCancelled);

  /// Get formatted summary message
  String get summary {
    if (isCancelled) return 'Import dibatalkan';
    if (isSuccess) {
      if (errorCount > 0) {
        return '$message (${successCount} berhasil, ${errorCount} error)';
      }
      return message;
    }
    return 'Error: $message';
  }

  @override
  String toString() => summary;
}