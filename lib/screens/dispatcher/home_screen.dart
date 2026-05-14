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
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class DispatcherHomeScreen extends ConsumerStatefulWidget {
  const DispatcherHomeScreen({super.key});

  @override
  ConsumerState<DispatcherHomeScreen> createState() => _DispatcherHomeScreenState();
}

class _DispatcherHomeScreenState extends ConsumerState<DispatcherHomeScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  Timer? _pollingTimer;

  List<dynamic> _incidents = [];
  List<dynamic> _ambulances = [];
  bool _isInitialLoading = true;
  String _selectedFilter = 'all';
  
  // Communication panel
  bool _showChatPanel = false;
  final List<Map<String, dynamic>> _chatMessages = [
    {'sender': 'System', 'message': 'Ambulance AMB-201 dispatched to incident INC-2024-003', 'time': '2 min ago', 'type': 'system'},
    {'sender': 'Paramedic Johnson', 'message': 'Arrived on scene, patient stable', 'time': '5 min ago', 'type': 'paramedic'},
    {'sender': 'Dispatcher', 'message': 'All units, heavy traffic reported on Main St', 'time': '10 min ago', 'type': 'dispatcher'},
  ];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchData());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final futures = await Future.wait([
        _apiService.getAssignments(),
        _apiService.getAllAmbulances(),
      ]);

      if (mounted) {
        setState(() {
          _incidents = futures[0];
          _ambulances = futures[1];
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      // Mock data
      setState(() {
        _incidents = _getMockIncidents();
        _ambulances = _getMockAmbulances();
        _isInitialLoading = false;
      });
    }
  }

  List<dynamic> _getMockIncidents() {
    return [
      {'id': 'INC-2024-001', 'emergency_type': 'Cardiac Arrest', 'status': 'pending', 'priority': 'critical', 'patient': {'name': 'John Doe'}, 'patient_location': 'POINT(-74.006 40.7128)', 'created_at': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String()},
      {'id': 'INC-2024-002', 'emergency_type': 'Vehicle Accident', 'status': 'en_route', 'priority': 'high', 'patient': {'name': 'Jane Smith'}, 'patient_location': 'POINT(-73.985 40.7589)', 'ambulance_id': 'AMB-201', 'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()},
      {'id': 'INC-2024-003', 'emergency_type': 'Respiratory Distress', 'status': 'on_scene', 'priority': 'high', 'patient': {'name': 'Bob Wilson'}, 'patient_location': 'POINT(-73.968 40.7489)', 'ambulance_id': 'AMB-202', 'created_at': DateTime.now().subtract(const Duration(minutes: 8)).toIso8601String()},
      {'id': 'INC-2024-004', 'emergency_type': 'Fall Injury', 'status': 'transporting', 'priority': 'medium', 'patient': {'name': 'Alice Brown'}, 'patient_location': 'POINT(-73.956 40.7389)', 'ambulance_id': 'AMB-203', 'created_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String()},
    ];
  }

  List<dynamic> _getMockAmbulances() {
    return [
      {'id': 'AMB-201', 'status': 'responding', 'current_location': 'POINT(-73.99 40.72)', 'paramedic': 'John Smith'},
      {'id': 'AMB-202', 'status': 'on_scene', 'current_location': 'POINT(-73.968 40.7489)', 'paramedic': 'Sarah Johnson'},
      {'id': 'AMB-203', 'status': 'transporting', 'current_location': 'POINT(-73.956 40.7389)', 'paramedic': 'Mike Davis'},
      {'id': 'AMB-204', 'status': 'available', 'current_location': 'POINT(-74.01 40.70)', 'paramedic': 'Emily Wilson'},
      {'id': 'AMB-205', 'status': 'available', 'current_location': 'POINT(-73.98 40.73)', 'paramedic': 'Robert Brown'},
    ];
  }

  LatLng? _parsePostGis(String? pointString) {
    if (pointString == null || !pointString.contains('POINT(')) return null;
    try {
      final coords = pointString.split('POINT(')[1].replaceAll(')', '').split(' ');
      return LatLng(double.parse(coords[1]), double.parse(coords[0]));
    } catch (e) {
      return null;
    }
  }

  List<dynamic> get _filteredIncidents {
    if (_selectedFilter == 'all') return _incidents;
    return _incidents.where((i) => i['priority'] == _selectedFilter).toList();
  }

  int get _unassignedCritical => _incidents
      .where((i) => i['priority'] == 'critical' && i['status'] == 'pending')
      .length;

  int get _activeIncidents => _incidents
      .where((i) => i['status'] != 'completed' && i['status'] != 'cancelled')
      .length;

  int get _availableAmbulances => _ambulances
      .where((a) => a['status'] == 'available')
      .length;

  void _assignNearestAmbulance(dynamic incident) {
    AppTheme.hapticMedium();
    final available = _ambulances.where((a) => a['status'] == 'available').toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available ambulances'), backgroundColor: AppTheme.criticalRed),
      );
      return;
    }
    
    // Mock assignment
    setState(() {
      incident['status'] = 'en_route';
      incident['ambulance_id'] = available.first['id'];
      available.first['status'] = 'responding';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assigned ${available.first['id']} to ${incident['id']}'),
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendBroadcastMessage() {
    if (_chatController.text.isEmpty) return;
    
    AppTheme.hapticLight();
    setState(() {
      _chatMessages.insert(0, {
        'sender': 'Dispatcher (You)',
        'message': _chatController.text,
        'time': 'Just now',
        'type': 'dispatcher',
      });
      _chatController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        body: const Center(child: SpinKitPulse(color: AppTheme.accentOrange, size: 80)),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'dispatcher', activeRoute: '/home', accentColor: AppTheme.accentOrange),
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
            const Icon(Icons.dashboard, color: AppTheme.accentOrange, size: 24),
            const SizedBox(width: 8),
            Text('DISPATCH', style: AppTheme.headingSmall.copyWith(fontSize: 20, letterSpacing: 2, color: AppTheme.accentOrange)),
          ],
        ),
        centerTitle: true,
        actions: [
          // Communication toggle
          IconButton(
            icon: Badge(
              isLabelVisible: _chatMessages.isNotEmpty,
              smallSize: 8,
              child: Icon(_showChatPanel ? Icons.chat_bubble : Icons.chat_bubble_outline, color: AppTheme.accentOrange),
            ),
            onPressed: () => setState(() => _showChatPanel = !_showChatPanel),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              AppTheme.hapticLight();
              _fetchData();
            },
          ),
        ],
      ),
      body: AnimatedBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 900;
            
            return Stack(
              children: [
                // Main content
                Row(
                  children: [
                    // Left/Middle: Map + Stats (flexible)
                    Expanded(
                      flex: isWideScreen ? 2 : 1,
                      child: Column(
                        children: [
                          // Critical Alert Banner
                          if (_unassignedCritical > 0)
                            _buildCriticalAlertBanner(),
                          
                          // Quick Stats Row
                          _buildQuickStats(),
                          
                          // Map
                          Expanded(
                            child: _buildMap(),
                          ),
                          
                          // Bottom incident feed (mobile) or stats (tablet)
                          if (!isWideScreen) 
                            _buildBottomPanel(),
                        ],
                      ),
                    ),
                    
                    // Right: Incident Feed + Chat (wide screens)
                    if (isWideScreen)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildWideSidePanel(),
                          ],
                        ),
                      ),
                  ],
                ),
                
                // Chat Panel Overlay
                if (_showChatPanel)
                  _buildChatPanel(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCriticalAlertBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 100, 16, 0),
      child: GlassCard(
        borderRadius: 16,
        borderColor: AppTheme.criticalRed,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.criticalRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppTheme.criticalRed, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_unassignedCritical CRITICAL ${_unassignedCritical == 1 ? 'INCIDENT' : 'INCIDENTS'} UNASSIGNED',
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppTheme.criticalRed),
                  ),
                  const SizedBox(height: 2),
                  Text('Immediate dispatch required', style: AppTheme.bodySmall),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final critical = _incidents.firstWhere((i) => i['priority'] == 'critical' && i['status'] == 'pending', orElse: () => null);
                if (critical != null) _assignNearestAmbulance(critical);
              },
              icon: const Icon(Icons.local_shipping, size: 18),
              label: const Text('Dispatch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Active', _activeIncidents.toString(), Icons.emergency, AppTheme.criticalRed)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Available', _availableAmbulances.toString(), Icons.local_shipping, Colors.greenAccent)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Avg Response', '5.2m', Icons.timer, AppTheme.criticalTeal)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('On Scene', '3', Icons.check_circle, AppTheme.accentOrange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      onTap: () {},
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.headingSmall.copyWith(fontSize: 22, color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.bodySmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final activeIncidents = _incidents.where((i) => i['status'] != 'completed' && i['status'] != 'cancelled').toList();
    
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(40.7128, -74.0060),
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        MarkerLayer(
          markers: [
            // Ambulances
            ..._ambulances.map((amb) {
              final latLng = _parsePostGis(amb['current_location']);
              if (latLng == null) return null;
              final statusColor = _getAmbulanceStatusColor(amb['status']);
              return Marker(
                point: latLng,
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_shipping, color: statusColor, size: 24)
                      .animate(onPlay: (c) => amb['status'] == 'responding' ? c.repeat(reverse: true) : null)
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds),
                ),
              );
            }).whereType<Marker>(),

            // Incidents
            ...activeIncidents.map((inc) {
              final latLng = _parsePostGis(inc['patient_location']);
              if (latLng == null) return null;
              final priorityColor = _getPriorityColor(inc['priority'] ?? 'medium');
              return Marker(
                point: latLng,
                width: 80,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning, color: priorityColor, size: 30)
                      .animate(onPlay: (c) => c.repeat())
                      .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.seconds)
                      .fade(end: 0.2),
                ),
              );
            }).whereType<Marker>(),
          ],
        ),
      ],
    );
  }

  Color _getAmbulanceStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.greenAccent;
      case 'responding':
      case 'en_route':
        return AppTheme.accentOrange;
      case 'on_scene':
        return Colors.blueAccent;
      case 'transporting':
        return Colors.purpleAccent;
      default:
        return Colors.white54;
    }
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

  Widget _buildBottomPanel() {
    return _buildIncidentFeed();
  }

  Widget _buildWideSidePanel() {
    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 16, top: 100),
      child: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(),
          const SizedBox(height: 12),
          // Incident list
          Expanded(child: _buildIncidentFeed()),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['all', 'critical', 'high', 'medium'];
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            final color = filter == 'all' ? Colors.white : _getPriorityColor(filter);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFilter = filter),
                label: Text(filter.toUpperCase()),
                selectedColor: color.withOpacity(0.3),
                backgroundColor: Colors.white.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: isSelected ? color : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIncidentFeed() {
    final incidents = _filteredIncidents
        .where((i) => i['status'] != 'completed' && i['status'] != 'cancelled')
        .toList();

    if (incidents.isEmpty) {
      return GlassCard(
        borderRadius: 16,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.greenAccent.withOpacity(0.5), size: 48),
              const SizedBox(height: 16),
              Text('All Clear', style: AppTheme.headingSmall),
              const SizedBox(height: 8),
              Text('No active emergencies', style: AppTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: incidents.length,
        itemBuilder: (context, index) => _buildIncidentTile(incidents[index]),
      ),
    );
  }

  Widget _buildIncidentTile(dynamic incident) {
    final priority = incident['priority'] as String? ?? 'medium';
    final status = incident['status'] as String;
    final priorityColor = _getPriorityColor(priority);
    final createdAt = DateTime.tryParse(incident['created_at'] ?? '') ?? DateTime.now();
    final elapsed = DateTime.now().difference(createdAt);
    
    return Dismissible(
      key: Key(incident['id'].toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (status == 'pending') {
          _assignNearestAmbulance(incident);
          return false;
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('DISPATCH', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: priorityColor.withOpacity(0.3)),
        ),
        child: InkWell(
          onTap: () {
            final latLng = _parsePostGis(incident['patient_location']);
            if (latLng != null) {
              _mapController.move(latLng, 16.0);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              incident['emergency_type'] ?? 'Emergency',
                              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: AppTheme.bodySmall.copyWith(
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient: ${incident['patient']?['name'] ?? "Unknown"}',
                        style: AppTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            elapsed.inMinutes < 1 ? 'Just now' : '${elapsed.inMinutes}m ago',
                            style: AppTheme.bodySmall.copyWith(fontSize: 10),
                          ),
                          if (incident['ambulance_id'] != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.local_shipping, size: 12, color: Colors.greenAccent),
                            const SizedBox(width: 4),
                            Text(
                              incident['ambulance_id'],
                              style: AppTheme.bodySmall.copyWith(color: Colors.greenAccent, fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (status == 'pending')
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.criticalRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swipe_left, color: AppTheme.criticalRed, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Positioned(
      right: 16,
      top: 100,
      bottom: 100,
      width: 350,
      child: GlassCard(
        borderRadius: 20,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text('Team Chat', style: AppTheme.headingSmall.copyWith(fontSize: 18)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => setState(() => _showChatPanel = false),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            
            // Messages
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = _chatMessages[index];
                  final isMe = msg['type'] == 'dispatcher';
                  final isSystem = msg['type'] == 'system';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isMe)
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isSystem ? Colors.orangeAccent.withOpacity(0.3) : Colors.blueAccent.withOpacity(0.3),
                            child: Icon(
                              isSystem ? Icons.computer : Icons.person,
                              color: isSystem ? Colors.orangeAccent : Colors.blueAccent,
                              size: 14,
                            ),
                          ),
                        if (!isMe) const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe 
                                ? AppTheme.accentOrange.withOpacity(0.3)
                                : (isSystem ? Colors.orangeAccent.withOpacity(0.15) : Colors.white.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['sender'],
                                style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Text(msg['message'], style: AppTheme.bodyMedium),
                              const SizedBox(height: 2),
                              Text(
                                msg['time'],
                                style: AppTheme.bodySmall.copyWith(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Send message to all units...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendBroadcastMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.accentOrange),
                  onPressed: _sendBroadcastMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideX(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}
