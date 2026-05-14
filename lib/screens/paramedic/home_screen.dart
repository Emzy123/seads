import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class ParamedicHomeScreen extends ConsumerStatefulWidget {
  const ParamedicHomeScreen({super.key});

  @override
  ConsumerState<ParamedicHomeScreen> createState() => _ParamedicHomeScreenState();
}

class _ParamedicHomeScreenState extends ConsumerState<ParamedicHomeScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  List<dynamic> _assignments = [];
  bool _isLoading = true;
  int _currentTab = 0;
  
  // Status management
  String _currentStatus = 'available';
  final List<String> _statusOptions = ['available', 'responding', 'on_scene', 'transporting', 'offline'];
  
  // Equipment data
  final List<Map<String, dynamic>> _equipment = [
    {'name': 'Defibrillator', 'checked': true, 'lastChecked': DateTime.now().subtract(const Duration(hours: 2)), 'status': 'operational'},
    {'name': 'Oxygen Tank', 'checked': true, 'lastChecked': DateTime.now().subtract(const Duration(hours: 4)), 'status': 'operational'},
    {'name': 'First Aid Kit', 'checked': false, 'lastChecked': DateTime.now().subtract(const Duration(days: 1)), 'status': 'warning'},
    {'name': 'Stretcher', 'checked': true, 'lastChecked': DateTime.now().subtract(const Duration(hours: 6)), 'status': 'operational'},
    {'name': 'Ventilator', 'checked': true, 'lastChecked': DateTime.now().subtract(const Duration(hours: 3)), 'status': 'operational'},
    {'name': 'Medication Bag', 'checked': false, 'lastChecked': DateTime.now().subtract(const Duration(days: 2)), 'status': 'critical'},
  ];

  // Performance stats
  final Map<String, dynamic> _performanceStats = {
    'avgResponseTime': 6.2,
    'totalIncidents': 156,
    'completionRate': 94.2,
    'rating': 4.8,
    'weeklyData': [5.8, 6.1, 6.2, 5.9, 6.4, 6.2, 6.2],
  };

  // Calendar
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _shifts = {};

  @override
  void initState() {
    super.initState();
    _initTrackingAndData();
    _generateMockShifts();
  }

  void _generateMockShifts() {
    final now = DateTime.now();
    for (int i = -7; i < 30; i++) {
      final date = now.add(Duration(days: i));
      if (i % 3 == 0) {
        _shifts[DateTime(date.year, date.month, date.day)] = ['Day Shift (08:00-20:00)'];
      } else if (i % 3 == 1) {
        _shifts[DateTime(date.year, date.month, date.day)] = ['Night Shift (20:00-08:00)'];
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initTrackingAndData() async {
    await _fetchAssignments();
    
    try {
      final pos = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = pos);
        _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
      }
    } catch (_) {}

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() => _currentPosition = position);
        _apiService.updateLocation(lat: position.latitude, lng: position.longitude);
      }
    });
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final assignments = await _apiService.getAssignments();
      if (mounted) {
        setState(() => _assignments = assignments);
      }
    } catch (e) {
      // Mock data
      setState(() => _assignments = _getMockAssignments());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> _getMockAssignments() {
    return [
      {
        'id': 'INC-001',
        'status': 'dispatched',
        'emergency_type': 'Cardiac Arrest',
        'patient': {'name': 'Emma Watson'},
        'location': {'lat': 40.7128, 'lng': -74.0060},
        'priority': 'critical',
        'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
    ];
  }

  Future<void> _updateStatus(String incidentId, String newStatus) async {
    AppTheme.hapticMedium();
    try {
      await _apiService.updateIncidentStatus(incidentId: incidentId, status: newStatus);
      await _fetchAssignments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppTheme.criticalRed),
        );
      }
    }
  }

  void _changeParamedicStatus(String newStatus) {
    AppTheme.hapticLight();
    setState(() => _currentStatus = newStatus);
    // TODO: Sync to backend
  }

  void _checkEquipment(int index) {
    AppTheme.hapticLight();
    setState(() {
      _equipment[index]['checked'] = !(_equipment[index]['checked'] ?? false);
      _equipment[index]['lastChecked'] = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'paramedic', activeRoute: '/home', accentColor: Colors.greenAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: AppTheme.glassBlur, sigmaY: AppTheme.glassBlur),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping, color: Colors.greenAccent, size: 24),
            const SizedBox(width: 8),
            Text('PARAMEDIC', style: AppTheme.headingSmall.copyWith(fontSize: 20, letterSpacing: 2, color: Colors.greenAccent)),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: StatusIndicator(
                status: _currentStatus == 'offline' ? 'offline' : 'online',
                label: _currentStatus.replaceAll('_', ' ').toUpperCase(),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: Column(
          children: [
            // Status Toggle Bar
            _buildStatusToggle(),
            
            // Tab Content
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildActiveTab(),
                  _buildScheduleTab(),
                  _buildPerformanceTab(),
                  _buildEquipmentTab(),
                ],
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Current Status', style: AppTheme.bodyMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_currentStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BreathingPulse(color: _getStatusColor(_currentStatus), size: 8),
                    const SizedBox(width: 6),
                    Text(
                      _currentStatus.replaceAll('_', ' ').toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: _getStatusColor(_currentStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                final isSelected = _currentStatus == status;
                final color = _getStatusColor(status);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    onSelected: (_) => _changeParamedicStatus(status),
                    label: Text(status.replaceAll('_', ' ').toUpperCase()),
                    selectedColor: color,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.greenAccent;
      case 'responding':
      case 'en_route':
        return Colors.orangeAccent;
      case 'on_scene':
        return Colors.blueAccent;
      case 'transporting':
        return Colors.purpleAccent;
      case 'offline':
        return Colors.white54;
      default:
        return Colors.greenAccent;
    }
  }

  Widget _buildActiveTab() {
    final activeAssignment = _assignments.cast<Map<String, dynamic>?>().firstWhere(
      (a) => a != null && a['status'] != 'completed' && a['status'] != 'cancelled',
      orElse: () => null,
    );

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(0, 0),
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 80,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_shipping, color: Colors.greenAccent, size: 30)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Assignment Panel
        if (activeAssignment != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildAssignmentCard(activeAssignment),
          )
        else
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: GlassCard(
              borderRadius: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60),
                  const SizedBox(height: 16),
                  Text('No Active Emergencies', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'You are currently available. Standby for dispatch.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> incident) {
    final status = incident['status'] as String;
    final priority = incident['priority'] as String? ?? 'medium';
    final patientName = incident['patient']?['name'] ?? 'Unknown Patient';
    final emergencyType = incident['emergency_type'] ?? 'Emergency';

    String nextActionLabel = 'En Route';
    String nextStatus = 'en_route';
    Color actionColor = Colors.orangeAccent;

    if (status == 'dispatched' || status == 'pending') {
      nextActionLabel = 'Accept & En Route';
      nextStatus = 'en_route';
      actionColor = Colors.orangeAccent;
    } else if (status == 'en_route') {
      nextActionLabel = 'Arrived On Scene';
      nextStatus = 'on_scene';
      actionColor = Colors.blueAccent;
    } else if (status == 'on_scene') {
      nextActionLabel = 'Begin Transport';
      nextStatus = 'transporting';
      actionColor = Colors.purpleAccent;
    } else if (status == 'transporting') {
      nextActionLabel = 'Mark Completed';
      nextStatus = 'completed';
      actionColor = Colors.greenAccent;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.glassBorderRadius)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: AppTheme.glassBlur, sigmaY: AppTheme.glassBlur),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.glassBackground,
            border: Border(
              top: BorderSide(color: _getPriorityColor(priority)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getPriorityColor(priority)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emergency, color: _getPriorityColor(priority), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            priority.toUpperCase(),
                            style: AppTheme.bodySmall.copyWith(
                              color: _getPriorityColor(priority),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('2 min ago', style: AppTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 16),
                Text(emergencyType, style: AppTheme.headingMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text('Patient: $patientName', style: AppTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text('2.3 km away • ETA: 4 min', style: AppTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(incident['id'].toString(), nextStatus),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(nextActionLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return AppTheme.criticalRed;
      case 'high':
        return AppTheme.priorityHigh;
      case 'medium':
        return AppTheme.priorityMedium;
      case 'low':
        return AppTheme.criticalTeal;
      default:
        return Colors.white54;
    }
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule', style: AppTheme.headingMedium),
          const SizedBox(height: 20),
          GlassCard(
            borderRadius: 16,
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
              eventLoader: (day) => _shifts[DateTime(day.year, day.month, day.day)] ?? [],
              calendarStyle: CalendarStyle(
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white70),
                outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: AppTheme.headingSmall.copyWith(fontSize: 18),
                leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Upcoming Shifts', style: AppTheme.headingSmall.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          ..._buildUpcomingShifts(),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingShifts() {
    final upcoming = _shifts.entries
        .where((e) => e.key.isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .take(3)
        .toList();
    
    return upcoming.map<Widget>((entry) {
      final isToday = isSameDay(entry.key, DateTime.now());
      return GlassCard(
        borderRadius: 12,
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isToday ? Colors.greenAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM').format(entry.key).toUpperCase(),
                    style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  ),
                  Text(
                    entry.key.day.toString(),
                    style: AppTheme.headingSmall.copyWith(fontSize: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.value.first, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    isToday ? 'Today' : DateFormat('EEEE').format(entry.key),
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isToday)
              ElevatedButton(
                onPressed: () {
                  AppTheme.hapticMedium();
                  _changeParamedicStatus('available');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Start'),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance', style: AppTheme.headingMedium),
          const SizedBox(height: 20),
          
          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Avg Response',
                  '${_performanceStats['avgResponseTime']} min',
                  Icons.timer,
                  _performanceStats['avgResponseTime'] < 7 ? Colors.greenAccent : AppTheme.priorityHigh,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Total Calls',
                  '${_performanceStats['totalIncidents']}',
                  Icons.assignment,
                  Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Completion',
                  '${_performanceStats['completionRate']}%',
                  Icons.check_circle,
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Rating',
                  '⭐ ${_performanceStats['rating']}',
                  Icons.star,
                  Colors.yellow,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Weekly Chart
          Text('Response Time Trend (minutes)', style: AppTheme.headingSmall.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          GlassCard(
            borderRadius: 16,
            child: SizedBox(
              height: 120,
              child: _buildMiniChart(_performanceStats['weeklyData'] as List<double>),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTheme.headingSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildMiniChart(List<double> data) {
    return CustomPaint(
      size: const Size(double.infinity, 100),
      painter: LineChartPainter(data, Colors.greenAccent),
    );
  }

  Widget _buildEquipmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Equipment Check', style: AppTheme.headingMedium),
              GestureDetector(
                onTap: () {
                  AppTheme.hapticMedium();
                  // Mark all checked
                  for (int i = 0; i < _equipment.length; i++) {
                    _checkEquipment(i);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      Text('Check All', style: AppTheme.bodySmall.copyWith(color: Colors.greenAccent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._equipment.asMap().entries.map((entry) => _buildEquipmentItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildEquipmentItem(int index, Map<String, dynamic> item) {
    final isChecked = item['checked'] as bool;
    final lastChecked = item['lastChecked'] as DateTime;
    final hoursAgo = DateTime.now().difference(lastChecked).inHours;
    final isStale = hoursAgo > 12;
    final status = item['status'] as String;
    
    Color statusColor;
    switch (status) {
      case 'operational':
        statusColor = Colors.greenAccent;
        break;
      case 'warning':
        statusColor = AppTheme.priorityHigh;
        break;
      case 'critical':
        statusColor = AppTheme.criticalRed;
        break;
      default:
        statusColor = Colors.white54;
    }

    return GlassCard(
      borderRadius: 12,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _checkEquipment(index),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _checkEquipment(index),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isChecked 
                    ? Colors.greenAccent.withOpacity(0.2) 
                    : (isStale ? AppTheme.criticalRed.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isChecked 
                      ? Colors.greenAccent 
                      : (isStale ? AppTheme.criticalRed : Colors.white.withOpacity(0.3)),
                ),
              ),
              child: Icon(
                isChecked ? Icons.check_circle : Icons.circle_outlined,
                color: isChecked 
                    ? Colors.greenAccent 
                    : (isStale ? AppTheme.criticalRed : Colors.white54),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isChecked ? 'Just checked' : '$hoursAgo hours ago',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isStale && !isChecked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.criticalRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CHECK REQUIRED',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.criticalRed,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return GlassCard(
      borderRadius: 0,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.emergency, 'Active', 0, Colors.greenAccent),
            _buildNavItem(Icons.calendar_today, 'Schedule', 1, Colors.blueAccent),
            _buildNavItem(Icons.insights, 'Stats', 2, AppTheme.accentOrange),
            _buildNavItem(Icons.build, 'Equipment', 3, Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color color) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        AppTheme.hapticLight();
        setState(() => _currentTab = index);
      },
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: isSelected ? color : Colors.white.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  LineChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height * 0.8 - size.height * 0.1;
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
