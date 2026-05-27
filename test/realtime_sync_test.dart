import 'package:flutter_test/flutter_test.dart';
import 'package:seads/services/realtime_sync_service.dart';

void main() {
  test('reportFailure increases interval up to max', () {
    final sync = RealtimeSyncService(
      minInterval: const Duration(seconds: 2),
      maxInterval: const Duration(seconds: 10),
    );
    sync.reportFailure();
    expect(sync.currentInterval.inSeconds, greaterThan(2));
    sync.reportFailure();
    sync.reportFailure();
    expect(sync.currentInterval.inSeconds, lessThanOrEqualTo(10));
  });

  test('reportSuccess resets interval to min', () {
    final sync = RealtimeSyncService();
    sync.reportFailure();
    sync.reportSuccess();
    expect(sync.currentInterval, sync.minInterval);
  });
}
