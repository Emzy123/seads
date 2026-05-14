import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';

class FleetManagementScreen extends ConsumerStatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  ConsumerState<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends ConsumerState<FleetManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _ambulances = [];
  bool _isLoading = true;
  String _filterStatus = 'all';
  dynamic _selectedAmbulance;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchFleet();
  }

  Future<void> _fetchFleet() async {
    try {
      final ambulances = await _apiService.getAllAmbulances();
      if (mounted) {
        setState(() {
          _ambulances = ambulances;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Mock data
      setState(() {
        _ambulances = _getMockFleet();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getMockFleet() {
    return [
      {'id': 'AMB-201', 'status': 'available', 'type': 'Type II', 'current_location': 'POINT(7.49508 9.05785)', 'driver': 'Paramedic Smith', 'mileage': 45200, 'fuel_level': 85, 'last_service': '2024-01-15'},
      {'id': 'AMB-202', 'status': 'on_mission', 'type': 'Type III', 'current_location': 'POINT(7.50234 9.06345)', 'driver': 'Paramedic Johnson', 'mileage': 38900, 'fuel_level': 62, 'last_service': '2024-02-01'},
      {'id': 'AMB-203', 'status': 'maintenance', 'type': 'Type II', 'current_location': null, 'driver': 'Unassigned', 'mileage': 67800, 'fuel_level': 30, 'last_service': '2023-12-10'},
      {'id': 'AMB-204', 'status': 'available', 'type': 'Type III', 'current_location': 'POINT(7.48921 9.05234)', 'driver': 'Paramedic Davis', 'mileage': 23400, 'fuel_level': 92, 'last_service': '2024-02-20'},
      {'id': 'AMB-205', 'status': 'on_mission', 'type': 'Type II', 'current_location': 'POINT(7.51123 9.07123)', 'driver': 'Paramedic Wilson', 'mileage': 52300, 'fuel_level': 45, 'last_service': '2024-01-28'},
      {'id': 'AMB-206', 'status': 'offline', 'type': 'Type III', 'current_location': null, 'driver': 'Unassigned', 'mileage': 89100, 'fuel_level': 15, 'last_service': '2023-11-15'},
    ];
  }

  List<dynamic> get _filteredAmbulances {
    if (_filterStatus == 'all') return _ambulances;
    return _ambulances.where((a) => a['status'] == _filterStatus).toList();
  }

  int get _availableCount => _ambulances.where((a) => a['status'] == 'available').length;
  int get _onMissionCount => _ambulances.where((a) => a['status'] == 'on_mission').length;
  int get _maintenanceCount => _ambulances.where((a) => a['status'] == 'maintenance').length;
  int get _offlineCount => _ambulances.where((a) => a['status'] == 'offline').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'dispatcher', activeRoute: '/fleet', accentColor: Colors.orangeAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('FLEET MANAGEMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.orangeAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAmbulanceDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFleet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: SpinKitPulse(color: Colors.orangeAccent, size: 60))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Fleet Overview Stats
        Container(
          margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent.withOpacity(0.2), Colors.redAccent.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFleetStat('Available', _availableCount, Colors.greenAccent, Icons.check_circle),
              _buildFleetStat('On Mission', _onMissionCount, Colors.blueAccent, Icons.local_shipping),
              _buildFleetStat('Maintenance', _maintenanceCount, Colors.orangeAccent, Icons.build),
              _buildFleetStat('Offline', _offlineCount, Colors.redAccent, Icons.offline_bolt),
            ],
          ),
        ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('All', 'all', Icons.all_inclusive),
              _buildFilterChip('Available', 'available', Icons.check_circle),
              _buildFilterChip('On Mission', 'on_mission', Icons.local_shipping),
              _buildFilterChip('Maintenance', 'maintenance', Icons.build),
              _buildFilterChip('Offline', 'offline', Icons.offline_bolt),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Fleet List
        Expanded(
          child: _filteredAmbulances.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchFleet,
                  color: Colors.orangeAccent,
                  backgroundColor: Colors.black,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredAmbulances.length,
                    itemBuilder: (context, index) {
                      final ambulance = _filteredAmbulances[index];
                      return _buildAmbulanceCard(ambulance);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFleetStat(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) => setState(() => _filterStatus = selected ? value : 'all'),
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white70),
        label: Text(label),
        backgroundColor: Colors.white.withOpacity(0.1),
        selectedColor: Colors.orangeAccent,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text(
            'No Ambulances Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filter',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceCard(dynamic ambulance) {
    final status = ambulance['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showAmbulanceDetails(ambulance),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ambulance['id'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ambulance['type']} • Driver: ${ambulance['driver']}',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(Icons.local_gas_station, 'Fuel', '${ambulance['fuel_level']}%', _getFuelColor(ambulance['fuel_level'])),
                  ),
                  Expanded(
                    child: _buildDetailItem(Icons.speed, 'Mileage', '${ambulance['mileage']}', Colors.white70),
                  ),
                  Expanded(
                    child: _buildDetailItem(Icons.build, 'Service', ambulance['last_service'] ?? 'N/A', Colors.white70),
                  ),
                ],
              ),
              if (ambulance['current_location'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.greenAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'GPS Active - Tracking enabled',
                        style: TextStyle(fontSize: 12, color: Colors.greenAccent.withOpacity(0.8)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showLocationOnMap(ambulance),
                      child: const Text('View Map'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.5)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.greenAccent;
      case 'on_mission':
        return Colors.blueAccent;
      case 'maintenance':
        return Colors.orangeAccent;
      case 'offline':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle;
      case 'on_mission':
        return Icons.local_shipping;
      case 'maintenance':
        return Icons.build;
      case 'offline':
        return Icons.offline_bolt;
      default:
        return Icons.help;
    }
  }

  Color _getFuelColor(int level) {
    if (level > 70) return Colors.greenAccent;
    if (level > 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _showAmbulanceDetails(dynamic ambulance) {
    final status = ambulance['status'] as String;
    final statusColor = _getStatusColor(status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.95),
                border: Border(top: BorderSide(color: statusColor)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_getStatusIcon(status), color: statusColor, size: 40),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ambulance['id'],
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection('Vehicle Information', [
                    {'label': 'Type', 'value': ambulance['type']},
                    {'label': 'Mileage', 'value': '${ambulance['mileage']} km'},
                    {'label': 'Fuel Level', 'value': '${ambulance['fuel_level']}%'},
                    {'label': 'Last Service', 'value': ambulance['last_service'] ?? 'Unknown'},
                  ]),
                  const SizedBox(height: 20),
                  _buildDetailSection('Current Assignment', [
                    {'label': 'Driver', 'value': ambulance['driver']},
                    {'label': 'Status', 'value': status.replaceAll('_', ' ').toUpperCase()},
                    {'label': 'Location', 'value': ambulance['current_location'] != null ? 'GPS Active' : 'N/A'},
                  ]),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateAmbulanceStatus(ambulance),
                          icon: const Icon(Icons.edit),
                          label: const Text('Update Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.build),
                          label: const Text('Schedule Service'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (ambulance['current_location'] != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showLocationOnMap(ambulance),
                        icon: const Icon(Icons.map),
                        label: const Text('View on Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['label']!, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                  Text(item['value']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _showLocationOnMap(dynamic ambulance) {
    // Show location on map
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening map for ${ambulance['id']}...')),
    );
  }

  void _updateAmbulanceStatus(dynamic ambulance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              border: const Border(top: BorderSide(color: Colors.orangeAccent)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Update Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                ...['available', 'on_mission', 'maintenance', 'offline'].map((status) => ListTile(
                  leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                  title: Text(status.toUpperCase().replaceAll('_', ' '), style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      ambulance['status'] = status;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status updated to ${status.replaceAll('_', ' ')}')),
                    );
                  },
                )).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAmbulanceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              border: const Border(top: BorderSide(color: Colors.orangeAccent)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add New Ambulance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                _buildTextField('Ambulance ID', 'e.g., AMB-207'),
                const SizedBox(height: 16),
                _buildTextField('Type', 'Type II or Type III'),
                const SizedBox(height: 16),
                _buildTextField('Initial Mileage', '0'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ambulance added successfully')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Ambulance'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orangeAccent),
        ),
      ),
    );
  }
}
