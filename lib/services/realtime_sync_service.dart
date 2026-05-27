import 'dart:async';

/// Adaptive polling replacement for fixed-interval refresh (2s–30s backoff).
class RealtimeSyncService {
  RealtimeSyncService({
    this.minInterval = const Duration(seconds: 2),
    this.maxInterval = const Duration(seconds: 30),
  }) : _currentInterval = const Duration(seconds: 2);

  final Duration minInterval;
  final Duration maxInterval;

  Timer? _timer;
  late Duration _currentInterval;
  bool _running = false;
  Future<void> Function()? _onTick;

  Duration get currentInterval => _currentInterval;
  bool get isRunning => _running;

  void start(Future<void> Function() onTick) {
    stop();
    _onTick = onTick;
    _running = true;
    _currentInterval = minInterval;
    _scheduleNext(immediate: true);
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _onTick = null;
  }

  void reportSuccess() {
    _currentInterval = minInterval;
  }

  void reportFailure() {
    final nextMs = (_currentInterval.inMilliseconds * 1.5).round();
    final capped = nextMs.clamp(
      minInterval.inMilliseconds,
      maxInterval.inMilliseconds,
    );
    _currentInterval = Duration(milliseconds: capped);
  }

  void _scheduleNext({bool immediate = false}) {
    if (!_running || _onTick == null) return;
    _timer?.cancel();

    if (immediate) {
      _runTick();
      return;
    }

    _timer = Timer(_currentInterval, _runTick);
  }

  Future<void> _runTick() async {
    if (!_running || _onTick == null) return;
    try {
      await _onTick!();
      reportSuccess();
    } catch (_) {
      reportFailure();
    }
    _scheduleNext();
  }

  void dispose() => stop();
}
