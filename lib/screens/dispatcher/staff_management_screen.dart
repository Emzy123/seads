import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _staff = [];
  bool _isLoading = true;
  String _filterRole = 'all';
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getStaff();
      if (!mounted) return;
      setState(() {
        _staff = list.isNotEmpty ? List<dynamic>.from(list) : _mockStaff();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _staff = _mockStaff();
        _isLoading = false;
      });
    }
  }

  List<dynamic> _mockStaff() {
    return [
      {'id': '1', 'name': 'John Smith', 'role': 'paramedic', 'status': 'on_duty', 'email': 'john.smith@seads.com', 'phone': '+1 555-0101', 'shift': 'Day', 'rating': 4.8, 'incidents': 156, 'join_date': '2022-03-15'},
      {'id': '2', 'name': 'Sarah Johnson', 'role': 'paramedic', 'status': 'on_duty', 'email': 'sarah.j@seads.com', 'phone': '+1 555-0102', 'shift': 'Night', 'rating': 4.9, 'incidents': 203, 'join_date': '2021-06-20'},
      {'id': '3', 'name': 'Michael Davis', 'role': 'paramedic', 'status': 'off_duty', 'email': 'm.davis@seads.com', 'phone': '+1 555-0103', 'shift': 'Day', 'rating': 4.6, 'incidents': 134, 'join_date': '2023-01-10'},
      {'id': '4', 'name': 'Emily Wilson', 'role': 'dispatcher', 'status': 'on_duty', 'email': 'emily.w@seads.com', 'phone': '+1 555-0104', 'shift': 'Day', 'rating': 4.7, 'incidents': 0, 'join_date': '2022-08-05'},
      {'id': '5', 'name': 'Robert Brown', 'role': 'paramedic', 'status': 'on_leave', 'email': 'r.brown@seads.com', 'phone': '+1 555-0105', 'shift': 'Night', 'rating': 4.5, 'incidents': 98, 'join_date': '2023-04-12'},
      {'id': '6', 'name': 'Lisa Anderson', 'role': 'paramedic', 'status': 'on_duty', 'email': 'lisa.a@seads.com', 'phone': '+1 555-0106', 'shift': 'Day', 'rating': 4.8, 'incidents': 167, 'join_date': '2022-11-18'},
      {'id': '7', 'name': 'James Taylor', 'role': 'dispatcher', 'status': 'off_duty', 'email': 'j.taylor@seads.com', 'phone': '+1 555-0107', 'shift': 'Night', 'rating': 4.6, 'incidents': 0, 'join_date': '2021-09-25'},
      {'id': '8', 'name': 'Maria Garcia', 'role': 'paramedic', 'status': 'on_duty', 'email': 'maria.g@seads.com', 'phone': '+1 555-0108', 'shift': 'Day', 'rating': 4.9, 'incidents': 189, 'join_date': '2022-05-30'},
    ];
  }

  List<dynamic> get _filteredStaff {
    return _staff.where((s) {
      final matchesRole = _filterRole == 'all' || s['role'] == _filterRole;
      final matchesStatus = _filterStatus == 'all' || s['status'] == _filterStatus;
      final matchesSearch = _searchQuery.isEmpty || 
          s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesStatus && matchesSearch;
    }).toList();
  }

  int get _totalStaff => _staff.length;
  int get _onDuty => _staff.where((s) => s['status'] == 'on_duty').length;
  int get _offDuty => _staff.where((s) => s['status'] == 'off_duty').length;
  int get _onLeave => _staff.where((s) => s['status'] == 'on_leave').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'dispatcher', activeRoute: '/staff', accentColor: Colors.orangeAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('STAFF MANAGEMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.orangeAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddStaffDialog(),
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
        // Staff Stats
        Container(
          margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStaffStat('Total', _totalStaff, Colors.blueAccent, Icons.people),
              _buildStaffStat('On Duty', _onDuty, Colors.greenAccent, Icons.person),
              _buildStaffStat('Off Duty', _offDuty, Colors.white70, Icons.person_off),
              _buildStaffStat('On Leave', _onLeave, Colors.orangeAccent, Icons.beach_access),
            ],
          ),
        ),

        // Search & Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search staff by name or email...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('All Roles', 'all', Icons.all_inclusive, _filterRole, (v) => setState(() => _filterRole = v)),
              _buildFilterChip('Paramedics', 'paramedic', Icons.local_shipping, _filterRole, (v) => setState(() => _filterRole = v)),
              _buildFilterChip('Dispatchers', 'dispatcher', Icons.headset, _filterRole, (v) => setState(() => _filterRole = v)),
              _buildFilterChip('All Status', 'all', Icons.circle, _filterStatus, (v) => setState(() => _filterStatus = v)),
              _buildFilterChip('On Duty', 'on_duty', Icons.check_circle, _filterStatus, (v) => setState(() => _filterStatus = v)),
              _buildFilterChip('Off Duty', 'off_duty', Icons.cancel, _filterStatus, (v) => setState(() => _filterStatus = v)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Staff List
        Expanded(
          child: _filteredStaff.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredStaff.length,
                  itemBuilder: (context, index) => _buildStaffCard(_filteredStaff[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildStaffStat(String label, int count, Color color, IconData icon) {
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
          Icon(Icons.people, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text(
            'No Staff Found',
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

  Widget _buildStaffCard(dynamic staff) {
    final status = staff['status'] as String;
    final role = staff['role'] as String;
    final statusColor = _getStatusColor(status);
    final roleIcon = role == 'paramedic' ? Icons.local_shipping : Icons.headset;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showStaffDetails(staff),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(roleIcon, color: statusColor, size: 28),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['name'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff['email'],
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.star, size: 12, color: Colors.yellow.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          staff['rating'].toString(),
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                        ),
                        if (role == 'paramedic') ...[
                          const SizedBox(width: 12),
                          Icon(Icons.assignment, size: 12, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            '${staff['incidents']} incidents',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                color: Colors.black.withOpacity(0.9),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditStaffDialog(staff);
                      break;
                    case 'schedule':
                      _showScheduleDialog(staff);
                      break;
                    case 'message':
                      _sendMessage(staff);
                      break;
                    case 'deactivate':
                      _deactivateStaff(staff);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Edit Profile')])),
                  const PopupMenuItem(value: 'schedule', child: Row(children: [Icon(Icons.schedule, size: 20), SizedBox(width: 12), Text('View Schedule')])),
                  const PopupMenuItem(value: 'message', child: Row(children: [Icon(Icons.message, size: 20), SizedBox(width: 12), Text('Send Message')])),
                  const PopupMenuItem(value: 'deactivate', child: Row(children: [Icon(Icons.block, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('Deactivate', style: TextStyle(color: Colors.redAccent))])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'on_duty':
        return Colors.greenAccent;
      case 'off_duty':
        return Colors.white54;
      case 'on_leave':
        return Colors.orangeAccent;
      default:
        return Colors.white54;
    }
  }

  void _showStaffDetails(dynamic staff) {
    final status = staff['status'] as String;
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
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: statusColor.withOpacity(0.2),
                          child: Icon(
                            staff['role'] == 'paramedic' ? Icons.local_shipping : Icons.headset,
                            color: statusColor,
                            size: 50,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      staff['name'],
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${staff['role'].toString().toUpperCase()} • ${status.toUpperCase().replaceAll('_', ' ')}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildDetailSection('Contact Information', [
                    {'icon': Icons.email, 'label': 'Email', 'value': staff['email']},
                    {'icon': Icons.phone, 'label': 'Phone', 'value': staff['phone']},
                  ]),
                  const SizedBox(height: 20),
                  _buildDetailSection('Work Information', [
                    {'icon': Icons.schedule, 'label': 'Shift', 'value': staff['shift']},
                    {'icon': Icons.calendar_today, 'label': 'Joined', 'value': staff['join_date']},
                    {'icon': Icons.star, 'label': 'Rating', 'value': '⭐ ${staff['rating']}'},
                    if (staff['role'] == 'paramedic')
                      {'icon': Icons.assignment, 'label': 'Total Incidents', 'value': staff['incidents'].toString()},
                  ]),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.message),
                          label: const Text('Send Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showScheduleDialog(staff),
                          icon: const Icon(Icons.schedule),
                          label: const Text('View Schedule'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black,
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

  Widget _buildDetailSection(String title, List<Map<String, dynamic>> items) {
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
                children: [
                  Icon(item['icon'] as IconData, size: 20, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 12),
                  Text(
                    '${item['label']}: ',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                  ),
                  Expanded(
                    child: Text(
                      item['value'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _showAddStaffDialog() {
    // Add staff dialog implementation
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildStaffForm(),
    );
  }

  void _showEditStaffDialog(dynamic staff) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildStaffForm(staff: staff),
    );
  }

  Widget _buildStaffForm({dynamic staff}) {
    final isEditing = staff != null;
    return ClipRRect(
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
              Text(
                isEditing ? 'Edit Staff' : 'Add New Staff',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              _buildTextField('Full Name', staff?['name'] ?? ''),
              const SizedBox(height: 16),
              _buildTextField('Email Address', staff?['email'] ?? '', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', staff?['phone'] ?? '', keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Staff updated' : 'Staff added successfully')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Add Staff'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value, {TextInputType? keyboardType}) {
    return TextField(
      controller: TextEditingController(text: value),
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent)),
      ),
    );
  }

  void _showScheduleDialog(dynamic staff) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule for ${staff['name']} coming soon')),
    );
  }

  void _sendMessage(dynamic staff) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening chat with ${staff['name']}...')),
    );
  }

  void _deactivateStaff(dynamic staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deactivate Staff?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to deactivate ${staff['name']}? This will prevent them from accessing the system.',
          style: const TextStyle(color: Colors.white70),
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
                SnackBar(content: Text('${staff['name']} has been deactivated')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}
