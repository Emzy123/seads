import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';

class AssignmentHistoryScreen extends ConsumerStatefulWidget {
  const AssignmentHistoryScreen({super.key});

  @override
  ConsumerState<AssignmentHistoryScreen> createState() => _AssignmentHistoryScreenState();
}

class _AssignmentHistoryScreenState extends ConsumerState<AssignmentHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _history = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await _apiService.getAssignmentHistory();
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredHistory {
    if (_filterStatus == 'all') return _history;
    return _history.where((h) => h['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'paramedic', activeRoute: '/assignment-history', accentColor: Colors.greenAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('ASSIGNMENT HISTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.greenAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportHistory(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: SpinKitPulse(color: Colors.greenAccent, size: 60))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Stats Summary
        Container(
          margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(child: _buildStatItem('Total', _history.length.toString(), Icons.assignment, Colors.blueAccent)),
              Container(width: 1, height: 50, color: Colors.white.withOpacity(0.2)),
              Expanded(child: _buildStatItem('Completed', _history.where((h) => h['status'] == 'completed').length.toString(), Icons.check_circle, Colors.greenAccent)),
              Container(width: 1, height: 50, color: Colors.white.withOpacity(0.2)),
              Expanded(child: _buildStatItem('This Month', _history.where((h) {
                final date = h['created_at'] != null ? DateTime.parse(h['created_at']) : null;
                if (date == null) return false;
                final now = DateTime.now();
                return date.month == now.month && date.year == now.year;
              }).length.toString(), Icons.calendar_today, Colors.orangeAccent)),
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
              _buildFilterChip('Completed', 'completed', Icons.check_circle),
              _buildFilterChip('Cancelled', 'cancelled', Icons.cancel),
              _buildFilterChip('In Progress', 'in_progress', Icons.timer),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // History List
        Expanded(
          child: _filteredHistory.isEmpty ? _buildEmptyState() : _buildHistoryList(),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
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
        selectedColor: Colors.greenAccent,
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
            'No Assignments Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed assignments will appear here',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: Colors.greenAccent,
      backgroundColor: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredHistory.length,
        itemBuilder: (context, index) {
          final assignment = _filteredHistory[index];
          return _buildAssignmentCard(assignment);
        },
      ),
    );
  }

  Widget _buildAssignmentCard(dynamic assignment) {
    final status = assignment['status'] as String? ?? 'unknown';
    final createdAt = assignment['created_at'] != null
        ? DateTime.parse(assignment['created_at'])
        : DateTime.now();
    final completedAt = assignment['completed_at'] != null
        ? DateTime.tryParse(assignment['completed_at'])
        : null;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        break;
      case 'in_progress':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.timer;
        break;
      default:
        statusColor = Colors.blueAccent;
        statusIcon = Icons.assignment;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showAssignmentDetails(assignment),
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
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment['emergency_type'] ?? 'Medical Emergency',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
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
                      status.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(Icons.person, 'Patient', assignment['patient_name'] ?? 'Unknown'),
                  ),
                  Expanded(
                    child: _buildDetailRow(Icons.location_on, 'Distance', '${assignment['distance_km']?.toString() ?? '--'} km'),
                  ),
                ],
              ),
              if (completedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(Icons.schedule, 'Duration', _calculateDuration(createdAt, completedAt)),
                    ),
                    Expanded(
                      child: _buildDetailRow(Icons.star, 'Rating', '⭐ ${assignment['rating']?.toString() ?? '--'}'),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.5)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  void _showFilterSheet() {
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
              color: Colors.black.withOpacity(0.9),
              border: const Border(top: BorderSide(color: Colors.greenAccent)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.greenAccent),
                  title: const Text('Date Range', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.sort, color: Colors.greenAccent),
                  title: const Text('Sort By', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.emergency, color: Colors.greenAccent),
                  title: const Text('Emergency Type', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssignmentDetails(dynamic assignment) {
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
                color: Colors.black.withOpacity(0.9),
                border: const Border(top: BorderSide(color: Colors.greenAccent)),
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
                  const Text('Assignment Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  // Add detailed info here
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.download),
                      label: const Text('Download Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _exportHistory() {
    // Export to PDF/Excel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting assignment history...')),
    );
  }
}
