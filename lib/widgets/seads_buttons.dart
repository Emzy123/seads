import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : (icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label));

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppTheme.criticalRed,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Hold-to-activate SOS with optional tap path (accessibility).
class EmergencySosButton extends StatelessWidget {
  final bool isDispatching;
  final bool isHolding;
  final double holdProgress;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback onHoldCancel;
  final VoidCallback? onTapAlternative;

  const EmergencySosButton({
    super.key,
    required this.isDispatching,
    required this.isHolding,
    required this.holdProgress,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onHoldCancel,
    this.onTapAlternative,
  });

  @override
  Widget build(BuildContext context) {
    final holdLabel = isHolding
        ? 'Emergency SOS, keep holding to confirm'
        : 'Emergency SOS, hold for three seconds to dispatch ambulance';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: holdLabel,
          child: GestureDetector(
            onTapDown: (_) => onHoldStart(),
            onTapUp: (_) => onHoldEnd(),
            onTapCancel: onHoldCancel,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.criticalRed,
                    AppTheme.criticalRed.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.criticalRed.withValues(
                      alpha: 0.5 + (isHolding ? holdProgress * 0.3 : 0),
                    ),
                    blurRadius: 30 + (isHolding ? holdProgress * 20 : 0),
                    spreadRadius: 10 + (isHolding ? holdProgress * 15 : 0),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isHolding || holdProgress > 0)
                    SizedBox(
                      width: 136,
                      height: 136,
                      child: CircularProgressIndicator(
                        value: holdProgress,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isDispatching)
                        const SpinKitDoubleBounce(color: Colors.white, size: 40)
                      else ...[
                        const Icon(Icons.emergency, color: Colors.white, size: 36),
                        const SizedBox(height: 4),
                        Text(
                          isHolding ? 'Hold...' : 'SOS',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isHolding ? 'Keep holding to confirm...' : 'Hold for 3 seconds to dispatch',
          style: AppTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (onTapAlternative != null) ...[
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Request emergency help with tap confirmation',
            child: TextButton(
              onPressed: isDispatching ? null : onTapAlternative,
              child: const Text('Request help (tap)'),
            ),
          ),
        ],
      ],
    );
  }
}
