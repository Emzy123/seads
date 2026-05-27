import 'package:flutter_test/flutter_test.dart';
import 'package:seads/core/breakpoints.dart';

void main() {
  test('compact below 600', () {
    expect(SeadsBreakpoints.ofWidth(599), SeadsBreakpoint.compact);
  });

  test('medium between 600 and 1023', () {
    expect(SeadsBreakpoints.ofWidth(600), SeadsBreakpoint.medium);
    expect(SeadsBreakpoints.ofWidth(1023), SeadsBreakpoint.medium);
  });

  test('expanded at 1024+', () {
    expect(SeadsBreakpoints.ofWidth(1024), SeadsBreakpoint.expanded);
  });
}
