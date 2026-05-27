import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config.dart';
import '../../core/api_exception.dart';
import '../../core/demo_data.dart';
import '../../core/equipment_helpers.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/seads_states.dart';
import '../../widgets/status_badge.dart';

class EquipmentCheckScreen extends ConsumerStatefulWidget {
  const EquipmentCheckScreen({super.key});

  @override
  ConsumerState<EquipmentCheckScreen> createState() => _EquipmentCheckScreenState();
}

class _EquipmentCheckScreenState extends ConsumerState<EquipmentCheckScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _equipment = [];
  bool _isLoading = true;
  String? _error;
  String _lastCheck = 'Never';

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await _apiService.getEquipment();
      if (!mounted) return;
      setState(() {
        _equipment = raw
            .whereType<Map>()
            .map((e) => normalizeEquipmentItem(Map<String, dynamic>.from(e)))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (AppConfig.isDemoMode) {
        setState(() {
          _equipment = DemoData.mockEquipment();
          _isLoading = false;
        });
      } else {
        setState(() {
          _equipment = [];
          _error = ApiService.wrapError(e).userMessage;
          _isLoading = false;
        });
      }
    }
  }

  int get _okCount => _equipment.where((e) => e['status'] == 'ok').length;
  int get _warningCount => _equipment.where((e) => e['status'] == 'warning').length;
  int get _lowCount => _equipment.where((e) => e['status'] == 'low').length;
  int get _criticalCount =>
      _equipment.where((e) => e['category'] == 'Critical' && e['status'] != 'ok').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(
        userRole: 'paramedic',
        activeRoute: '/equipment',
        accentColor: Colors.greenAccent,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text(
          'EQUIPMENT CHECK',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.greenAccent),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEquipment),
        ],
      ),
      body: _isLoading
          ? const SeadsLoadingState(label: 'Loading equipment…')
          : _error != null
              ? SeadsErrorState(message: _error, onRetry: _loadEquipment)
              : _equipment.isEmpty
                  ? const SeadsEmptyState(
                      icon: Icons.medical_services_outlined,
                      title: 'No equipment checklist',
                      message: 'Your unit checklist will appear here once assigned.',
                    )
                  : _buildContent(),
      floatingActionButton: _equipment.isEmpty
          ? null
          : FloatingActionButton.extended(
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
              color: _criticalCount > 0
                  ? Colors.redAccent.withOpacity(0.3)
                  : Colors.greenAccent.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _criticalCount > 0 ? Icons.warning : Icons.check_circle,
                    color: _criticalCount > 0 ? Colors.redAccent : Colors.greenAccent,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _criticalCount > 0 ? 'Equipment Issues Found' : 'All Systems Operational',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _equipment.length,
            itemBuilder: (context, index) => _buildEquipmentCard(_equipment[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> item) {
    final status = item['status'] as String;
    final color = status == 'ok'
        ? Colors.greenAccent
        : status == 'warning'
            ? Colors.orangeAccent
            : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      child: ListTile(
        leading: Icon(item['icon'] as IconData, color: color),
        title: Text(item['name'] as String, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '${item['category']} · ${item['lastChecked']}',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        trailing: StatusBadge(status: status, label: status.toUpperCase(), showPulse: false),
      ),
    );
  }

  Future<void> _startFullCheck() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.criticalTeal),
            SizedBox(height: 16),
            Text('Submitting checklist…', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );

    try {
      final items = _equipment
          .map((e) => {
                'name': e['name'],
                'status': e['status'],
                'checked': true,
              })
          .toList();
      await _apiService.submitEquipmentChecklist(items);
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _lastCheck = 'Just now';
        for (final item in _equipment) {
          item['lastChecked'] = 'Just now';
          item['checked'] = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipment check submitted')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.wrapError(e).userMessage),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
    }
  }
}
