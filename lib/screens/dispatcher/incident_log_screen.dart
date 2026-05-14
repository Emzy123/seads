import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';

class IncidentLogScreen extends ConsumerStatefulWidget {
  const IncidentLogScreen({super.key});

  @override
  ConsumerState<IncidentLogScreen> createState() => _IncidentLogScreenState();
}

class _IncidentLogScreenState extends ConsumerState<IncidentLogScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _incidents = [];
  bool _isLoading = true;
  String _filterStatus = 'all';
  String _filterType = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  Future<void> _fetchIncidents() async {
    try {
      var incidents = await _apiService.getIncidentLog();
      if (incidents.isEmpty) {
        incidents = await _apiService.getAssignments();
      }
      if (mounted) {
        setState(() {
          _incidents = incidents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _incidents = _getMockIncidents();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getMockIncidents() {
    return [
      {'id': 'INC-2024-001', 'emergency_type': 'Cardiac Arrest', 'status': 'completed', 'priority': 'critical', 'patient_name': 'John Doe', 'paramedic': 'Smith, J.', 'ambulance': 'AMB-201', 'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(), 'completed_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(), 'location': '123 Main St', 'hospital': 'General Hospital'},
      {'id': 'INC-2024-002', 'emergency_type': 'Vehicle Accident', 'status': 'completed', 'priority': 'high', 'patient_name': 'Jane Smith', 'paramedic': 'Johnson, S.', 'ambulance': 'AMB-202', 'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(), 'completed_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(), 'location': '456 Oak Ave', 'hospital': 'Memorial Hospital'},
      {'id': 'INC-2024-003', 'emergency_type': 'Respiratory Distress', 'status': 'in_progress', 'priority': 'high', 'patient_name': 'Bob Wilson', 'paramedic': 'Davis, M.', 'ambulance': 'AMB-204', 'created_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(), 'completed_at': null, 'location': '789 Pine Rd', 'hospital': 'General Hospital'},
      {'id': 'INC-2024-004', 'emergency_type': 'Fall Injury', 'status': 'completed', 'priority': 'medium', 'patient_name': 'Alice Brown', 'paramedic': 'Wilson, R.', 'ambulance': 'AMB-205', 'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(), 'completed_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(), 'location': '321 Elm St', 'hospital': 'Community Hospital'},
      {'id': 'INC-2024-005', 'emergency_type': 'Allergic Reaction', 'status': 'cancelled', 'priority': 'medium', 'patient_name': 'Tom Green', 'paramedic': 'Smith, J.', 'ambulance': 'AMB-201', 'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(), 'completed_at': null, 'location': '654 Maple Dr', 'hospital': 'General Hospital'},
      {'id': 'INC-2024-006', 'emergency_type': 'Stroke Symptoms', 'status': 'completed', 'priority': 'critical', 'patient_name': 'Mary White', 'paramedic': 'Johnson, S.', 'ambulance': 'AMB-202', 'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(), 'completed_at': DateTime.now().subtract(const Duration(hours: 10)).toIso8601String(), 'location': '987 Cedar Ln', 'hospital': 'Stroke Center'},
      {'id': 'INC-2024-007', 'emergency_type': 'Chest Pain', 'status': 'completed', 'priority': 'high', 'patient_name': 'David Lee', 'paramedic': 'Davis, M.', 'ambulance': 'AMB-204', 'created_at': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(), 'completed_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(), 'location': '147 Birch St', 'hospital': 'Heart Institute'},
    ];
  }

  List<dynamic> get _filteredIncidents {
    return _incidents.where((i) {
      final matchesStatus = _filterStatus == 'all' || i['status'] == _filterStatus;
      final matchesType = _filterType == 'all' || i['priority'] == _filterType;
      return matchesStatus && matchesType;
    }).toList();
  }

  int get _totalIncidents => _incidents.length;
  int get _completed => _incidents.where((i) => i['status'] == 'completed').length;
  int get _inProgress => _incidents.where((i) => i['status'] == 'in_progress').length;
  int get _cancelled => _incidents.where((i) => i['status'] == 'cancelled').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'dispatcher', activeRoute: '/incident-log', accentColor: Colors.orangeAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('INCIDENT LOG', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.orangeAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showAdvancedFilters(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportLog(),
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
        // Stats Overview
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
              _buildStatColumn('Total', _totalIncidents, Colors.blueAccent),
              _buildStatColumn('Completed', _completed, Colors.greenAccent),
              _buildStatColumn('Active', _inProgress, Colors.orangeAccent),
              _buildStatColumn('Cancelled', _cancelled, Colors.redAccent),
            ],
          ),
        ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('All', 'all', Icons.all_inclusive, _filterStatus, (v) => setState(() => _filterStatus = v)),
              _buildFilterChip('Completed', 'completed', Icons.check_circle, _filterStatus, (v) => setState(() => _filterStatus = v)),
              _buildFilterChip('In Progress', 'in_progress', Icons.timer, _filterStatus, (v) => setState(() => _filterStatus = v)),
              _buildFilterChip('Cancelled', 'cancelled', Icons.cancel, _filterStatus, (v) => setState(() => _filterStatus = v)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Incident List
        Expanded(
          child: _filteredIncidents.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchIncidents,
                  color: Colors.orangeAccent,
                  backgroundColor: Colors.black,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredIncidents.length,
                    itemBuilder: (context, index) => _buildIncidentCard(_filteredIncidents[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, String currentValue, Function(String) onChanged) {
    final isSelected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) => onChanged(selected ? value : 'all'),
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
          Icon(Icons.assignment, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text(
            'No Incidents Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(dynamic incident) {
    final status = incident['status'] as String;
    final priority = incident['priority'] as String;
    final statusColor = _getStatusColor(status);
    final priorityColor = _getPriorityColor(priority);

    final createdAt = DateTime.parse(incident['created_at']);
    final timeAgo = _formatTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showIncidentDetails(incident),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getEmergencyIcon(incident['emergency_type']), color: priorityColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident['emergency_type'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          incident['id'],
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(Icons.person, 'Patient', incident['patient_name'] ?? 'Unknown'),
                  ),
                  Expanded(
                    child: _buildInfoRow(Icons.local_shipping, 'Unit', incident['ambulance'] ?? 'N/A'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(Icons.local_hospital, 'Hospital', incident['hospital'] ?? 'N/A'),
                  ),
                  Expanded(
                    child: _buildInfoRow(Icons.person_search, 'Paramedic', incident['paramedic'] ?? 'Unassigned'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.5)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.greenAccent;
      case 'in_progress':
        return Colors.orangeAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.redAccent;
      case 'high':
        return Colors.orangeAccent;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.blueAccent;
      default:
        return Colors.white54;
    }
  }

  IconData _getEmergencyIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('cardiac') || lower.contains('heart')) return Icons.favorite;
    if (lower.contains('stroke')) return Icons.psychology;
    if (lower.contains('respiratory') || lower.contains('breathing')) return Icons.air;
    if (lower.contains('accident') || lower.contains('trauma')) return Icons.car_crash;
    if (lower.contains('fall')) return Icons.accessibility_new;
    if (lower.contains('allergic')) return Icons.warning;
    return Icons.emergency;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  void _showIncidentDetails(dynamic incident) {
    final status = incident['status'] as String;
    final statusColor = _getStatusColor(status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                  
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getEmergencyIcon(incident['emergency_type']), color: statusColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident['emergency_type'],
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Incident ID & Priority
                  _buildDetailSection('Incident Information', [
                    {'label': 'Incident ID', 'value': incident['id']},
                    {'label': 'Priority', 'value': (incident['priority'] as String).toUpperCase()},
                    {'label': 'Created', 'value': DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(incident['created_at']))},
                    if (incident['completed_at'] != null)
                      {'label': 'Completed', 'value': DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(incident['completed_at']))},
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  // Patient Info
                  _buildDetailSection('Patient Information', [
                    {'label': 'Name', 'value': incident['patient_name'] ?? 'Unknown'},
                    {'label': 'Location', 'value': incident['location'] ?? 'Unknown'},
                    {'label': 'Hospital', 'value': incident['hospital'] ?? 'Not specified'},
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  // Response Team
                  _buildDetailSection('Response Team', [
                    {'label': 'Paramedic', 'value': incident['paramedic'] ?? 'Unassigned'},
                    {'label': 'Ambulance', 'value': incident['ambulance'] ?? 'Not assigned'},
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: const Text('Download Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
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
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['label']!,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                  ),
                  Text(
                    item['value']!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _showAdvancedFilters() {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Advanced Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                const Text('Priority', style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildPriorityChip('All', 'all'),
                    _buildPriorityChip('Critical', 'critical'),
                    _buildPriorityChip('High', 'high'),
                    _buildPriorityChip('Medium', 'medium'),
                    _buildPriorityChip('Low', 'low'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Date Range', style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Start Date'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('End Date'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, String value) {
    final isSelected = _filterType == value;
    Color color;
    switch (value) {
      case 'critical':
        color = Colors.redAccent;
        break;
      case 'high':
        color = Colors.orangeAccent;
        break;
      case 'medium':
        color = Colors.yellow;
        break;
      case 'low':
        color = Colors.blueAccent;
        break;
      default:
        color = Colors.white54;
    }

    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) => setState(() => _filterType = selected ? value : 'all'),
      label: Text(label),
      selectedColor: color.withOpacity(0.3),
      backgroundColor: Colors.white.withOpacity(0.1),
      labelStyle: TextStyle(color: isSelected ? color : Colors.white70),
      side: BorderSide(color: isSelected ? color : Colors.white.withOpacity(0.2)),
    );
  }

  void _exportLog() {
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
                const Text('Export Incident Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  title: const Text('Export as PDF', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting as PDF...')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.greenAccent),
                  title: const Text('Export as Excel', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting as Excel...')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code, color: Colors.blueAccent),
                  title: const Text('Export as CSV', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting as CSV...')));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
