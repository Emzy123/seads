import 'package:flutter/material.dart';
import '../config.dart';

/// Centralized demo payloads used only when [AppConfig.isDemoMode] is true.
class DemoData {
  DemoData._();

  static List<T> orEmpty<T>(List<T> fromApi, List<T> Function() mock) {
    if (fromApi.isNotEmpty) return fromApi;
    return AppConfig.isDemoMode ? mock() : <T>[];
  }

  static Map<String, dynamic> orMap(
    Map<String, dynamic> fromApi,
    Map<String, dynamic> Function() mock,
  ) {
    if (fromApi.isNotEmpty) return fromApi;
    return AppConfig.isDemoMode ? mock() : <String, dynamic>{};
  }

  static List<dynamic> mockAssignments() => [
        {
          'id': 'INC-001',
          'status': 'dispatched',
          'emergency_type': 'Cardiac Arrest',
          'patient': {'name': 'Emma Watson'},
          'location': {'lat': 40.7128, 'lng': -74.0060},
          'priority': 'critical',
          'created_at':
              DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
      ];

  static List<dynamic> mockIncidents() => [
        {
          'id': 'INC-2024-001',
          'emergency_type': 'Cardiac Arrest',
          'status': 'pending',
          'priority': 'critical',
          'patient': {'name': 'John Doe'},
          'patient_location': 'POINT(-74.006 40.7128)',
          'created_at':
              DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
        },
        {
          'id': 'INC-2024-002',
          'emergency_type': 'Vehicle Accident',
          'status': 'en_route',
          'priority': 'high',
          'patient': {'name': 'Jane Smith'},
          'patient_location': 'POINT(-73.985 40.7589)',
          'ambulance_id': 'AMB-201',
          'created_at':
              DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
      ];

  static List<dynamic> mockAmbulances() => [
        {
          'id': 'AMB-0916',
          'name': 'SEADS-0916 (Emergency Line)',
          'status': 'available',
          'current_location': 'POINT(-73.98 40.74)',
          'paramedic': 'Emergency Paramedic Duty',
          'phone': AppConfig.emergencyCallLine,
        },
        {
          'id': 'AMB-201',
          'status': 'responding',
          'current_location': 'POINT(-73.99 40.72)',
          'paramedic': 'John Smith',
          'phone': '+2348030000001',
        },
        {
          'id': 'AMB-204',
          'status': 'available',
          'current_location': 'POINT(-74.01 40.70)',
          'paramedic': 'Emily Wilson',
          'phone': '+2348030000002',
        },
      ];

  static List<dynamic> mockFleet() => [
        {
          'id': 'AMB-0916',
          'name': 'SEADS-0916 (Emergency Call Line)',
          'status': 'available',
          'type': 'ALS Emergency Unit',
          'paramedic': 'Emergency Paramedic Duty',
          'phone': AppConfig.emergencyCallLine,
          'last_maintenance': '2024-02-10',
          'fuel_level': 100,
          'mileage': '2,400 km',
        },
        {
          'id': 'AMB-201',
          'status': 'responding',
          'type': 'ALS',
          'paramedic': 'John Smith',
          'phone': '+2348030000001',
          'last_maintenance': '2024-01-15',
          'fuel_level': 85,
          'mileage': '12,500 km',
        },
        {
          'id': 'AMB-204',
          'status': 'available',
          'type': 'BLS',
          'paramedic': 'Emily Wilson',
          'phone': '+2348030000002',
          'last_maintenance': '2024-02-01',
          'fuel_level': 90,
          'mileage': '8,200 km',
        },
      ];

  static List<dynamic> mockStaff() => [
        {
          'id': 'P-001',
          'name': 'John Smith',
          'role': 'paramedic',
          'status': 'on_duty',
          'rating': 4.8,
        },
        {
          'id': 'P-002',
          'name': 'Sarah Johnson',
          'role': 'paramedic',
          'status': 'off_duty',
          'rating': 4.6,
        },
      ];

  static Map<String, dynamic> mockPerformanceStats() => {
        'total_assignments': 42,
        'completed': 38,
        'avg_response_time': '4.1 min',
        'rating': 4.7,
      };

  static List<Map<String, dynamic>> mockEquipment() => [
        {
          'name': 'Defibrillator',
          'category': 'Critical',
          'status': 'ok',
          'icon': Icons.monitor_heart,
          'lastChecked': 'Today, 08:00',
        },
        {
          'name': 'Oxygen Tank',
          'category': 'Critical',
          'status': 'ok',
          'icon': Icons.air,
          'lastChecked': 'Today, 08:00',
        },
        {
          'name': 'First Aid Kit',
          'category': 'Critical',
          'status': 'warning',
          'icon': Icons.medical_services,
          'lastChecked': 'Yesterday',
        },
      ];

  static List<dynamic> mockShifts() {
    final now = DateTime.now();
    return [
      {
        'id': 'shift-demo-1',
        'type': 'Day Shift',
        'start': DateTime(now.year, now.month, now.day, 8).toIso8601String(),
        'end': DateTime(now.year, now.month, now.day, 20).toIso8601String(),
        'status': 'active',
        'partner': 'Paramedic Johnson',
        'ambulance_id': 'AMB-204',
      },
    ];
  }

  static Map<String, dynamic> mockAnalytics() => {
        'overview': {
          'total_incidents': 156,
          'avg_response_time': '4.2 min',
          'completion_rate': 94.2,
          'patient_satisfaction': 4.7,
          'daily_incidents': [12, 18, 15, 22, 19, 25, 45],
          'response_time_trend': [5.1, 4.8, 4.5, 4.3, 4.2, 4.1, 4.2],
        },
        'incidents': {
          'by_type': [
            {'type': 'Cardiac Emergency', 'count': 42, 'percentage': 27},
            {'type': 'Trauma', 'count': 38, 'percentage': 24},
          ],
          'by_priority': [
            {'priority': 'Critical', 'count': 45, 'color': 0xFFFF6B6B},
            {'priority': 'High', 'count': 67, 'color': 0xFFFFA502},
          ],
          'by_hour': List.generate(
            24,
            (i) => {'hour': i, 'count': (i % 5) + 1},
          ),
        },
        'fleet': {
          'utilization_rate': 78.5,
          'avg_distance_per_incident': 8.3,
          'fuel_consumption': 1245,
          'maintenance_cost': 15400,
          'vehicle_performance': [
            {'id': 'AMB-201', 'incidents': 28, 'rating': 4.8},
          ],
        },
        'personnel': {
          'total_paramedics': 24,
          'on_duty': 18,
          'avg_rating': 4.6,
          'top_performers': [
            {
              'name': 'Paramedic Johnson',
              'incidents': 42,
              'rating': 4.9,
              'response_time': '3.2 min',
            },
          ],
        },
      };
}
