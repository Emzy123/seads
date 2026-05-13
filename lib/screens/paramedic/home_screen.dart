import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';

class ParamedicHomeScreen extends ConsumerStatefulWidget {
  const ParamedicHomeScreen({super.key});

  @override
  ConsumerState<ParamedicHomeScreen> createState() => _ParamedicHomeScreenState();
}

class _ParamedicHomeScreenState extends ConsumerState<ParamedicHomeScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  List<dynamic> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTrackingAndData();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initTrackingAndData() async {
    await _fetchAssignments();
    
    // Get initial position
    try {
      final pos = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = pos);
        _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
      }
    } catch (_) {}

    // Start live tracking and syncing
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Only update if moved by 10 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() => _currentPosition = position);
        _mapController.move(LatLng(position.latitude, position.longitude), _mapController.camera.zoom);
        // Sync to backend
        _apiService.updateLocation(lat: position.latitude, lng: position.longitude);
      }
    });
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final assignments = await _apiService.getAssignments();
      // Filter to assignments assigned to this paramedic's ambulance (assuming backend returns all or filtered)
      // For now, we just display the first active one, or we can filter locally.
      if (mounted) {
        setState(() => _assignments = assignments);
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String incidentId, String newStatus) async {
    try {
      await _apiService.updateIncidentStatus(incidentId: incidentId, status: newStatus);
      await _fetchAssignments(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find the first active assignment (not completed or cancelled)
    final activeAssignment = _assignments.cast<Map<String, dynamic>?>().firstWhere(
      (a) => a != null && a['status'] != 'completed' && a['status'] != 'cancelled',
      orElse: () => null,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('SEADS PARAMEDIC', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.greenAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAssignments,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Live Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null 
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(0, 0),
              initialZoom: 16.0,
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
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.local_shipping, color: Colors.greenAccent, size: 30)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds),
                    ),
                  ],
                ),
            ],
          ),

          // 2. Glassmorphic Assignment Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    border: Border(top: BorderSide(color: Colors.greenAccent.withOpacity(0.3))),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 150, child: Center(child: SpinKitPulse(color: Colors.greenAccent)))
                    : activeAssignment == null
                        ? _buildIdleState()
                        : _buildActiveAssignment(activeAssignment),
                ),
              ),
            ),
          ).animate().slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60),
        const SizedBox(height: 16),
        const Text(
          'No Active Emergencies',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'You are currently available. Standby for dispatch.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildActiveAssignment(Map<String, dynamic> incident) {
    final status = incident['status'] as String;
    final patientName = incident['patient']?['name'] ?? 'Unknown Patient';
    final emergencyType = incident['emergency_type'] ?? 'Emergency';

    String nextActionLabel = 'En Route';
    String nextStatus = 'en_route';
    Color actionColor = Colors.orangeAccent;

    if (status == 'dispatched' || status == 'pending') {
      nextActionLabel = 'Acknowledge & En Route';
      nextStatus = 'en_route';
      actionColor = Colors.orangeAccent;
    } else if (status == 'en_route') {
      nextActionLabel = 'Arrived On Scene';
      nextStatus = 'on_scene';
      actionColor = Colors.blueAccent;
    } else if (status == 'on_scene') {
      nextActionLabel = 'Begin Transporting';
      nextStatus = 'transporting';
      actionColor = Colors.purpleAccent;
    } else if (status == 'transporting') {
      nextActionLabel = 'Mark Completed';
      nextStatus = 'completed';
      actionColor = Colors.greenAccent;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            Text(
              'Just Now', // You could parse created_at here
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          emergencyType,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Patient: $patientName',
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _updateStatus(incident['id'].toString(), nextStatus),
            child: Text(
              nextActionLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white24),
      ],
    );
  }
}
