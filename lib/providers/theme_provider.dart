import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-session theme preference (system / light / dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
