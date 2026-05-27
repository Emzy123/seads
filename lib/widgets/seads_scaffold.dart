import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard SEADS page shell: gradient background + optional glass app bar.
class SeadsScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Color? accentColor;
  final bool extendBodyBehindAppBar;

  const SeadsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.floatingActionButton,
    this.accentColor,
    this.extendBodyBehindAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        foregroundColor: accent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: AppTheme.glassBlur, sigmaY: AppTheme.glassBlur),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),
        actions: actions,
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(child: body),
      ),
    );
  }
}
