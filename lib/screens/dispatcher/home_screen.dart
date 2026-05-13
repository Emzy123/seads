import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchData());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final futures = await Future.wait([
        _apiService.getAssignments(), // Fetch incidents
        _apiService.getAllAmbulances(), // Fetch ambulances
      ]);

      if (mounted) {
        setState(() {
          _incidents = futures[0];
          _ambulances = futures[1];
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      // Handle error silently during polling
      if (_isInitialLoading && mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  LatLng? _parsePostGis(String? pointString) {
    if (pointString == null || !pointString.contains('POINT(')) return null;
    try {
      final coords = pointString.split('POINT(')[1].replaceAll(')', '').split(' ');
      // PostGIS point format is POINT(longitude latitude)
      return LatLng(double.parse(coords[1]), double.parse(coords[0]));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: SpinKitPulse(color: Colors.orangeAccent, size: 80)),
      );
    }

    final activeIncidents = _incidents.where((i) => i['status'] != 'completed' && i['status'] != 'cancelled').toList();
    final availableAmbulances = _ambulances.where((a) => a['status'] == 'available').toList();

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
        title: const Text('COMMAND CENTER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.orangeAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _pollingTimer?.cancel();
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Master Map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              // Default to a central city coordinate, ideally this should be dynamic based on the dispatcher's org
              initialCenter: LatLng(9.05785, 7.49508), // Abuja, Nigeria coordinates as an example
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  // Plot Ambulances
                  ..._ambulances.map((amb) {
                    final latLng = _parsePostGis(amb['current_location']);
                    if (latLng == null) return null;
                    final isAvailable = amb['status'] == 'available';
                    return Marker(
                      point: latLng,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.local_shipping,
                        color: isAvailable ? Colors.greenAccent : Colors.blueAccent,
                        size: 24,
                      ),
                    );
                  }).whereType<Marker>(),

                  // Plot Incidents
                  ...activeIncidents.map((inc) {
                    final latLng = _parsePostGis(inc['patient_location']);
                    if (latLng == null) return null;
                    return Marker(
                      point: latLng,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.warning, color: Colors.redAccent, size: 30)
                          .animate(onPlay: (c) => c.repeat())
                          .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.seconds)
                          .fade(end: 0.2),
                    );
                  }).whereType<Marker>(),
                ],
              ),
            ],
          ),

          // 2. Glassmorphic Sliding Dashboard
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      border: Border(top: BorderSide(color: Colors.orangeAccent.withOpacity(0.3))),
                    ),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white30,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatCard('Active Calls', activeIncidents.length.toString(), Colors.redAccent),
                                    _buildStatCard('Available Units', availableAmbulances.length.toString(), Colors.greenAccent),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Text('LIVE FEED', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white54)),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (activeIncidents.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(child: Text('All clear. No active emergencies.', style: TextStyle(color: Colors.white70))),
                                );
                              }
                              final inc = activeIncidents[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                                  child: const Icon(Icons.emergency, color: Colors.redAccent, size: 20),
                                ),
                                title: Text(inc['emergency_type'] ?? 'Emergency', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text('Patient: ${inc['patient']?['name'] ?? "Unknown"} • Status: ${inc['status'].toString().toUpperCase()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                                onTap: () {
                                  // Jump map to incident
                                  final latLng = _parsePostGis(inc['patient_location']);
                                  if (latLng != null) {
                                    _mapController.move(latLng, 16.0);
                                  }
                                },
                              );
                            },
                            childCount: activeIncidents.isEmpty ? 1 : activeIncidents.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
