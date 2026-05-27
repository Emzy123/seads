import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Accessible status chip: icon + label + color (WCAG: not color-only).
class StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  final bool showPulse;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.showPulse = true,
    this.icon,
  });

  Color get _color {
    switch (status.toLowerCase()) {
      case 'online':
      case 'available':
        return AppTheme.statusOnline;
      case 'emergency':
      case 'critical':
        return AppTheme.statusEmergency;
      case 'responding':
      case 'en_route':
      case 'responding_to_incident':
        return AppTheme.statusResponding;
      case 'offline':
      case 'off_duty':
        return AppTheme.statusOffline;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData get _icon {
    if (icon != null) return icon!;
    switch (status.toLowerCase()) {
      case 'available':
      case 'online':
        return Icons.check_circle_outline;
      case 'critical':
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'responding':
      case 'en_route':
        return Icons.local_shipping_outlined;
      case 'offline':
        return Icons.cloud_off_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPulse && AppTheme.animationsEnabled(context))
              BreathingPulse(color: _color, size: 8)
            else
              Icon(_icon, size: 14, color: _color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: _color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
