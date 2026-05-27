import 'package:flutter_test/flutter_test.dart';
import 'package:seads/core/api_exception.dart';
import 'package:seads/services/api_service.dart';

void main() {
  test('coerceStringList handles list input', () {
    expect(ApiService.coerceStringList(['a', 'b']), ['a', 'b']);
  });

  test('coerceStringList splits comma-separated string', () {
    expect(ApiService.coerceStringList('a, b, c'), ['a', 'b', 'c']);
  });

  test('coerceStringList returns empty for null', () {
    expect(ApiService.coerceStringList(null), isEmpty);
  });

  test('ApiException userMessage maps 401', () {
    const e = ApiException('unauthorized', statusCode: 401);
    expect(e.userMessage, contains('sign in'));
  });

  test('ApiException userMessage maps 500', () {
    const e = ApiException('error', statusCode: 500);
    expect(e.userMessage, contains('Server error'));
  });
}
