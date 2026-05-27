import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows pending offline actions or sync backoff state.
class SyncStatusBanner extends StatelessWidget {
  final int pendingCount;
  final Duration? pollInterval;
  final bool showBackoff;

  const SyncStatusBanner({
    super.key,
    required this.pendingCount,
    this.pollInterval,
    this.showBackoff = false,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0 && !showBackoff) return const SizedBox.shrink();

    final messages = <String>[];
    if (pendingCount > 0) {
      messages.add('$pendingCount update${pendingCount == 1 ? '' : 's'} queued — will sync when online');
    }
    if (showBackoff && pollInterval != null) {
      messages.add('Live sync every ${pollInterval!.inSeconds}s');
    }

    return Material(
      color: AppTheme.priorityHigh.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.sync, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                messages.join(' · '),
                style: AppTheme.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
