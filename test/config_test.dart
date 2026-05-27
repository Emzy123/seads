import 'package:flutter_test/flutter_test.dart';
import 'package:seads/config.dart';
import 'package:seads/core/demo_data.dart';

void main() {
  test('AppConfig defaults to production (no demo mode)', () {
    expect(AppConfig.isDemoMode, isFalse);
    expect(AppConfig.allowDemoFallbacks, isFalse);
    expect(AppConfig.isProduction, isTrue);
  });

  test('DemoData.orEmpty prefers API data when present', () {
    expect(DemoData.orEmpty([1, 2], () => [99]), [1, 2]);
  });

  test('DemoData.orEmpty returns empty when API empty and not demo', () {
    expect(DemoData.orEmpty<int>([], () => [1]), isEmpty);
  });

  test('DemoData.orMap prefers API map when non-empty', () {
    expect(DemoData.orMap({'a': 1}, () => {'b': 2}), {'a': 1});
  });
}
