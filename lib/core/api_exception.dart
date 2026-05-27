import 'package:dio/dio.dart';

/// Thrown when the backend returns a non-success response for an API call.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromResponse(Response<dynamic> response) {
    final data = response.data;
    String msg = 'Request failed';
    if (data is Map) {
      msg = (data['error'] ?? data['message'] ?? data['detail'] ?? msg).toString();
    } else if (data is String && data.isNotEmpty) {
      msg = data;
    }
    return ApiException(msg, statusCode: response.statusCode);
  }

  factory ApiException.notSignedIn() =>
      const ApiException('You must be signed in to continue', statusCode: 401);

  /// User-facing copy for SnackBars and error states.
  String get userMessage {
    if (statusCode == 401) return 'Session expired. Please sign in again.';
    if (statusCode == 403) return 'You do not have permission for this action.';
    if (statusCode == 404) return 'The requested data was not found.';
    if (statusCode != null && statusCode! >= 500) {
      return 'Server error. Please try again shortly.';
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
