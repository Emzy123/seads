import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';

class EquipmentCheckScreen extends ConsumerStatefulWidget {
  const EquipmentCheckScreen({super.key});

  @override
  ConsumerState<EquipmentCheckScreen> createState() => _EquipmentCheckScreenState();
}

class _EquipmentCheckScreenState extends ConsumerState<EquipmentCheckScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _equipment = [];
  bool _isLoading = true;
  String _lastCheck = 'Never';

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    // Mock data for demo - in real app, fetch from API
    setState(() {
      _equipment = [
        {'name': 'Defibrillator', 'category': 'Critical', 'status': 'ok', 'icon': Icons.monitor_heart, 'lastChecked': 'Today, 08:00'},
        {'name': 'Oxygen Tank', 'category': 'Critical', 'status': 'ok', 'icon': Icons.air, 'lastChecked': 'Today, 08:00'},
        {'name': 'First Aid Kit', 'category': 'Critical', 'status': 'warning', 'icon': Icons.medical_services, 'lastChecked': 'Yesterday'},
        {'name': 'Stretcher', 'category': 'Equipment', 'status': 'ok', 'icon': Icons.bed, 'lastChecked': 'Today, 08:00'},
        {'name': 'Blood Pressure Monitor', 'category': 'Monitoring', 'status': 'ok', 'icon': Icons.favorite_border, 'lastChecked': 'Today, 08:00'},
        {'name': 'Pulse Oximeter', 'category': 'Monitoring', 'status': 'ok', 'icon': Icons.speed, 'lastChecked': 'Today, 08:00'},
        {'name': 'Emergency Medications', 'category': 'Critical', 'status': 'ok', 'icon': Icons.medication, 'lastChecked': 'Today, 08:00'},
        {'name': 'Splints & Bandages', 'category': 'Supplies', 'status': 'low', 'icon': Icons.healing, 'lastChecked': '3 days ago'},
        {'name': 'IV Supplies', 'category': 'Supplies', 'status': 'ok', 'icon': Icons.water_drop, 'lastChecked': 'Today, 08:00'},
        {'name': 'Communication Radio', 'category': 'Equipment', 'status': 'ok', 'icon': Icons.radio, 'lastChecked': 'Today, 08:00'},
        {'name': 'GPS Unit', 'category': 'Equipment', 'status': 'warning', 'icon': Icons.gps_fixed, 'lastChecked': 'Yesterday'},
        {'name': 'Flashlight', 'category': 'Equipment', 'status': 'ok', 'icon': Icons.flashlight_on, 'lastChecked': 'Today, 08:00'},
      ];
      _isLoading = false;
    });
  }

  int get _okCount => _equipment.where((e) => e['status'] == 'ok').length;
  int get _warningCount => _equipment.where((e) => e['status'] == 'warning').length;
  int get _lowCount => _equipment.where((e) => e['status'] == 'low').length;
  int get _criticalCount => _equipment.where((e) => e['category'] == 'Critical' && e['status'] != 'ok').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'paramedic', activeRoute: '/equipment', accentColor: Colors.greenAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('EQUIPMENT CHECK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.greenAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEquipment,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: SpinKitPulse(color: Colors.greenAccent, size: 60))
          : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startFullCheck,
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.fact_check),
        label: const Text('Start Check'),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Status Overview
        Container(
          margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _criticalCount > 0
                  ? [Colors.redAccent.withOpacity(0.3), Colors.orangeAccent.withOpacity(0.2)]
                  : [Colors.greenAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _criticalCount > 0 ? Colors.redAccent.withOpacity(0.3) : Colors.greenAccent.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _criticalCount > 0 ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _criticalCount > 0 ? Icons.warning : Icons.check_circle,
                      color: _criticalCount > 0 ? Colors.redAccent : Colors.greenAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _criticalCount > 0 ? 'Equipment Issues Found' : 'All Systems Operational',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last checked: $_lastCheck',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusIndicator('OK', _okCount, Colors.greenAccent),
                  _buildStatusIndicator('Warning', _warningCount, Colors.orangeAccent),
                  _buildStatusIndicator('Low Stock', _lowCount, Colors.redAccent),
                ],
              ),
            ],
          ),
        ),

        // Filter Tabs
        DefaultTabController(
          length: 4,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                indicatorColor: Colors.greenAccent,
                labelColor: Colors.greenAccent,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Critical'),
                  Tab(text: 'Supplies'),
                  Tab(text: 'Equipment'),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 420,
                child: TabBarView(
                  children: [
                    _buildEquipmentList('all'),
                    _buildEquipmentList('Critical'),
                    _buildEquipmentList('Supplies'),
                    _buildEquipmentList('Equipment'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildEquipmentList(String filter) {
    final filtered = filter == 'all'
        ? _equipment
        : _equipment.where((e) => e['category'] == filter || (filter == 'Critical' && e['category'] == 'Critical')).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildEquipmentCard(item);
      },
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> item) {
    final status = item['status'] as String;
    final isCritical = item['category'] == 'Critical';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'ok':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case 'warning':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.warning;
        break;
      case 'low':
        statusColor = Colors.redAccent;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.white54;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: status == 'ok' ? Colors.white.withOpacity(0.1) : statusColor.withOpacity(0.5),
          width: status == 'ok' ? 1 : 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showEquipmentDetails(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'] as IconData, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (isCritical) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CRITICAL',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last checked: ${item['lastChecked']}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEquipmentDetails(Map<String, dynamic> item) {
    final status = item['status'] as String;
    Color statusColor;
    switch (status) {
      case 'ok':
        statusColor = Colors.greenAccent;
        break;
      case 'warning':
        statusColor = Colors.orangeAccent;
        break;
      case 'low':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.white54;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              border: Border(top: BorderSide(color: statusColor)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Icon(item['icon'] as IconData, color: statusColor, size: 40),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${item['category']}',
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Current Status', status.toUpperCase(), statusColor),
                _buildDetailRow('Last Checked', item['lastChecked'] as String, Colors.white70),
                _buildDetailRow('Next Check Due', 'Before next shift', Colors.white70),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            item['status'] = 'ok';
                            item['lastChecked'] = 'Just now';
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Mark OK'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _reportIssue(item);
                        },
                        icon: const Icon(Icons.report_problem),
                        label: const Text('Report Issue'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  void _reportIssue(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report Issue', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('What issue are you experiencing with ${item['name']}?', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ...[
              'Low stock/supplies',
              'Equipment malfunction',
              'Needs replacement',
              'Other issue',
            ].map((issue) => RadioListTile(
              title: Text(issue, style: const TextStyle(color: Colors.white, fontSize: 14)),
              value: issue,
              groupValue: null,
              onChanged: (_) {},
              activeColor: Colors.greenAccent,
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Issue reported to dispatch')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _startFullCheck() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Starting Equipment Check', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.greenAccent),
            const SizedBox(height: 20),
            Text(
              'Please verify all ${_equipment.length} items are present and operational.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      setState(() {
        _lastCheck = 'Just now';
        for (var item in _equipment) {
          item['lastChecked'] = 'Just now';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment check completed successfully'),
          backgroundColor: Colors.greenAccent,
        ),
      );
    });
  }
}
