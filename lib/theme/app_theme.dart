import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SEADS Global Design System
/// Dark Glassmorphic UI/UX Specification
class AppTheme {
  // Background Colors - Deep navy/charcoal gradient
  static const Color bgPrimary = Color(0xFF0A0F1D);
  static const Color bgSecondary = Color(0xFF10182F);
  static const Color bgGradientStart = Color(0xFF0A0F1D);
  static const Color bgGradientEnd = Color(0xFF10182F);

  // Glassmorphic Surface
  static const Color glassBackground = Color.fromRGBO(20, 28, 40, 0.65);
  static const double glassBlur = 12.0;
  static const double glassBorderRadius = 24.0;
  static const Color glassBorder = Color.fromRGBO(255, 255, 255, 0.1);
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.3),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  // Typography Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0C4DE); // Light steel blue
  static const Color textMuted = Color(0xFF6B7B8C);

  // Critical Value Colors
  static const Color criticalRed = Color(0xFFFF6B6B);
  static const Color criticalTeal = Color(0xFF4ECDC4);
  static const Color accentOrange = Colors.orangeAccent;
  static const Color successGreen = Color(0xFF4ECDC4);

  // Status Colors with breathing animation
  static const Color statusOnline = Color(0xFF4ECDC4);
  static const Color statusEmergency = Color(0xFFFF6B6B);
  static const Color statusResponding = Color(0xFFFFA502);
  static const Color statusOffline = Color(0xFF6B7B8C);

  // Priority Colors
  static const Color priorityCritical = Color(0xFFFF6B6B);
  static const Color priorityHigh = Color(0xFFFFA502);
  static const Color priorityMedium = Color(0xFFFFD93D);
  static const Color priorityLow = Color(0xFF4ECDC4);

  // Spacing (8px base unit)
  static const double spaceUnit = 8.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  static const double contentPadding = 20.0;
  static const double cardPadding = 16.0;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // Interactive Feedback
  static const double scaleActive = 0.98;
  static const double scaleHover = 1.02;

  // Get gradient background
  static BoxDecoration get backgroundGradient => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bgGradientStart, bgGradientEnd],
    ),
  );

  // Get glassmorphic container decoration
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: glassBackground,
    borderRadius: BorderRadius.circular(glassBorderRadius),
    border: Border.all(color: glassBorder, width: 1),
    boxShadow: glassShadow,
  );

  // Get glassmorphic container with custom radius
  static BoxDecoration glassDecorationWithRadius(double radius) => BoxDecoration(
    color: glassBackground,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: glassBorder, width: 1),
    boxShadow: glassShadow,
  );

  // Text Styles
  static TextStyle get headingLarge => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headingMedium => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get headingSmall => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    color: textSecondary,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    color: textSecondary,
    letterSpacing: 0.1,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12,
    color: textMuted,
    letterSpacing: 0.1,
  );

  static TextStyle get criticalValue => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: criticalRed,
  );

  static TextStyle get successValue => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: successGreen,
  );

  // Haptic feedback helpers
  static void hapticLight() => HapticFeedback.lightImpact();
  static void hapticMedium() => HapticFeedback.mediumImpact();
  static void hapticHeavy() => HapticFeedback.heavyImpact();
  static void hapticSuccess() => HapticFeedback.vibrate();
}

/// Animated breathing pulse widget for status indicators
class BreathingPulse extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const BreathingPulse({
    super.key,
    required this.color,
    this.size = 12,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<BreathingPulse> createState() => _BreathingPulseState();
}

class _BreathingPulseState extends State<BreathingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_animation.value * 0.5),
                blurRadius: widget.size,
                spreadRadius: widget.size * 0.3,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Glassmorphic card container
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.glassBorderRadius;
    
    Widget card = RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: AppTheme.glassShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppTheme.glassBlur,
              sigmaY: AppTheme.glassBlur,
            ),
            child: Container(
              padding: padding ?? const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: AppTheme.glassBackground,
                border: Border.all(
                  color: borderColor ?? AppTheme.glassBorder,
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: () {
          AppTheme.hapticLight();
          onTap!();
        },
        child: card,
      );
    }

    return card;
  }
}

/// Animated background particles widget
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int particleCount = 20;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      particleCount,
      (index) => AnimationController(
        duration: Duration(seconds: 10 + index * 2),
        vsync: this,
      )..repeat(),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.linear),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Stack(
        children: [
          // Animated particles - wrapped in RepaintBoundary for performance
          RepaintBoundary(
            child: Stack(
              children: List.generate(particleCount, (index) {
                return AnimatedBuilder(
                  animation: _animations[index],
                  builder: (context, child) {
                    final x = (_animations[index].value * 2 - 0.5 + index * 0.05) % 1.1;
                    final y = (_animations[index].value * 1.5 + index * 0.1) % 1.1;
                    return Positioned(
                      left: x * size.width,
                      top: y * size.height,
                      child: Container(
                        width: 2 + (index % 3).toDouble(),
                        height: 2 + (index % 3).toDouble(),
                        decoration: BoxDecoration(
                          color: AppTheme.criticalTeal.withOpacity(0.3 + (index % 5) * 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          // Main content
          widget.child,
        ],
      ),
    );
  }
}

/// Status indicator with breathing pulse
class StatusIndicator extends StatelessWidget {
  final String status;
  final String label;
  final bool showPulse;

  const StatusIndicator({
    super.key,
    required this.status,
    required this.label,
    this.showPulse = true,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'online':
      case 'available':
        return AppTheme.statusOnline;
      case 'emergency':
      case 'critical':
        return AppTheme.statusEmergency;
      case 'responding':
      case 'responding_to_incident':
        return AppTheme.statusResponding;
      case 'offline':
      case 'off_duty':
        return AppTheme.statusOffline;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPulse)
          BreathingPulse(color: _statusColor, size: 10)
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: _statusColor),
        ),
      ],
    );
  }
}

/// Offline indicator widget
class OfflineIndicator extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? lastSync;

  const OfflineIndicator({super.key, this.onRetry, this.lastSync});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: AppTheme.priorityHigh,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: AppTheme.priorityHigh, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Offline',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.priorityHigh,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (lastSync != null)
                Text(
                  'Last sync: $lastSync',
                  style: AppTheme.bodySmall,
                ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                AppTheme.hapticLight();
                onRetry!();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.priorityHigh.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh, color: AppTheme.priorityHigh, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Push notification preview toast
class NotificationPreview extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onAction;
  final String? actionLabel;

  const NotificationPreview({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      borderColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.headingSmall.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(message, style: AppTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (onAction != null && actionLabel != null)
            GestureDetector(
              onTap: () {
                AppTheme.hapticMedium();
                onAction!();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeleton loading shimmer
class SkeletonCard extends StatelessWidget {
  final double height;
  final double? width;

  const SkeletonCard({super.key, this.height = 100, this.width});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: SizedBox(
        height: height,
        width: width,
        child: ShimmerLoading(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer effect widget
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double progress;

  const _SlidingGradientTransform(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * progress, 0, 0);
  }
}
