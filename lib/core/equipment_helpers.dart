import 'package:flutter/material.dart';

/// Maps API equipment rows to UI list items (icons are client-side).
Map<String, dynamic> normalizeEquipmentItem(Map<String, dynamic> raw) {
  final name = raw['name']?.toString() ?? 'Item';
  return {
    'name': name,
    'category': raw['category']?.toString() ?? 'Equipment',
    'status': raw['status']?.toString() ?? 'ok',
    'icon': _iconForName(name),
    'lastChecked': _formatLastChecked(raw['last_checked'] ?? raw['lastChecked']),
    'checked': raw['checked'] == true,
  };
}

IconData _iconForName(String name) {
  final n = name.toLowerCase();
  if (n.contains('defibr')) return Icons.monitor_heart;
  if (n.contains('oxygen')) return Icons.air;
  if (n.contains('first aid')) return Icons.medical_services;
  if (n.contains('stretcher') || n.contains('bed')) return Icons.bed;
  if (n.contains('pressure')) return Icons.favorite_border;
  if (n.contains('oximeter') || n.contains('pulse')) return Icons.speed;
  if (n.contains('medication')) return Icons.medication;
  if (n.contains('bandage') || n.contains('splint')) return Icons.healing;
  if (n.contains('iv')) return Icons.water_drop;
  if (n.contains('radio')) return Icons.radio;
  if (n.contains('gps')) return Icons.gps_fixed;
  if (n.contains('flash')) return Icons.flashlight_on;
  return Icons.medical_information_outlined;
}

String _formatLastChecked(dynamic value) {
  if (value == null) return 'Unknown';
  final dt = DateTime.tryParse(value.toString());
  if (dt == null) return value.toString();
  final now = DateTime.now();
  if (now.difference(dt).inDays == 0) {
    return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  if (now.difference(dt).inDays == 1) return 'Yesterday';
  return '${now.difference(dt).inDays} days ago';
}
