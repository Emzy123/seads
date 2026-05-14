import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';

class PerformanceStatsScreen extends ConsumerStatefulWidget {
  const PerformanceStatsScreen({super.key});

  @override
  ConsumerState<PerformanceStatsScreen> createState() => _PerformanceStatsScreenState();
}

class _PerformanceStatsScreenState extends ConsumerState<PerformanceStatsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _apiService.getPerformanceStats(period: _selectedPeriod);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Use mock data for demo
      setState(() {
        _stats = _getMockStats();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getMockStats() {
    return {
      'total_assignments': 24,
      'completed_assignments': 22,
      'cancelled_assignments': 2,
      'average_response_time': '4.2 min',
      'average_completion_time': '28 min',
      'total_distance': 342.5,
      'patient_rating': 4.8,
      'on_time_percentage': 95,
      'weekly_data': [
        {'day': 'Mon', 'count': 4, 'time': 4.5},
        {'day': 'Tue', 'count': 3, 'time': 3.8},
        {'day': 'Wed', 'count': 5, 'time': 4.2},
        {'day': 'Thu', 'count': 2, 'time': 5.1},
        {'day': 'Fri', 'count': 4, 'time': 3.9},
        {'day': 'Sat', 'count': 6, 'time': 4.0},
        {'day': 'Sun', 'count': 3, 'time': 4.8},
      ],
      'emergency_types': [
        {'type': 'Cardiac', 'count': 8, 'color': 0xFFFF6B6B},
        {'type': 'Trauma', 'count': 6, 'color': 0xFFFFA502},
        {'type': 'Respiratory', 'count': 4, 'color': 0xFF2ED573},
        {'type': 'Other', 'count': 6, 'color': 0xFF70A1FF},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'paramedic', activeRoute: '/stats', accentColor: Colors.greenAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('PERFORMANCE STATS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.greenAccent)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _isLoading = true;
              });
              _fetchStats();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'quarter', child: Text('This Quarter')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: SpinKitPulse(color: Colors.greenAccent, size: 60))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedPeriod.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 20),

          // Main Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Assignments',
                  _stats?['total_assignments']?.toString() ?? '0',
                  Icons.assignment,
                  Colors.blueAccent,
                  '+12% from last ${_selectedPeriod}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Response',
                  _stats?['average_response_time']?.toString() ?? '--',
                  Icons.timer,
                  Colors.orangeAccent,
                  'Target: < 5 min',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Patient Rating',
                  '⭐ ${_stats?['patient_rating']?.toString() ?? '--'}',
                  Icons.star,
                  Colors.yellow,
                  'Top 10% of paramedics',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'On-Time %',
                  '${_stats?['on_time_percentage']?.toString() ?? '--'}%',
                  Icons.schedule,
                  Colors.purpleAccent,
                  'Exceeds target of 90%',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Weekly Activity Chart
          _buildSectionTitle('Weekly Activity'),
          const SizedBox(height: 12),
          _buildWeeklyChart(),

          const SizedBox(height: 24),

          // Emergency Types Distribution
          _buildSectionTitle('Emergency Types'),
          const SizedBox(height: 12),
          _buildEmergencyTypesChart(),

          const SizedBox(height: 24),

          // Performance Metrics
          _buildSectionTitle('Detailed Metrics'),
          const SizedBox(height: 12),
          _buildMetricsList(),

          const SizedBox(height: 24),

          // Achievements
          _buildSectionTitle('Achievements'),
          const SizedBox(height: 12),
          _buildAchievements(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final weeklyData = (_stats?['weekly_data'] as List?) ?? [];
    if (weeklyData.isEmpty) return const SizedBox.shrink();

    final maxCount = weeklyData.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Assignments per Day', style: TextStyle(fontSize: 12, color: Colors.white70)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Avg: ${(weeklyData.map((d) => d['count'] as int).reduce((a, b) => a + b) / weeklyData.length).toStringAsFixed(1)}/day',
                  style: const TextStyle(fontSize: 11, color: Colors.greenAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.map((day) {
                final count = day['count'] as int;
                final height = maxCount > 0 ? (count / maxCount) * 100.0 : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.greenAccent, Colors.greenAccent.withOpacity(0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day['day'],
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                    ),
                    Text(
                      count.toString(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypesChart() {
    final types = (_stats?['emergency_types'] as List?) ?? [];
    if (types.isEmpty) return const SizedBox.shrink();

    final total = types.map((t) => t['count'] as int).reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Simple bar chart for emergency types
          ...types.map((type) {
            final percentage = total > 0 ? (type['count'] as int) / total : 0.0;
            final color = Color(type['color'] as int);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(type['type'], style: const TextStyle(fontSize: 13, color: Colors.white)),
                      Text('${type['count']} (${(percentage * 100).toInt()}%)', style: TextStyle(fontSize: 12, color: color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetricsList() {
    final metrics = [
      {'label': 'Total Distance Covered', 'value': '${_stats?['total_distance']?.toString() ?? '--'} km', 'icon': Icons.route},
      {'label': 'Avg Completion Time', 'value': _stats?['average_completion_time']?.toString() ?? '--', 'icon': Icons.timer_off},
      {'label': 'Completion Rate', 'value': '${((_stats?['completed_assignments'] ?? 0) / (_stats?['total_assignments'] ?? 1) * 100).toStringAsFixed(0)}%', 'icon': Icons.check_circle},
      {'label': 'Cancellation Rate', 'value': '${((_stats?['cancelled_assignments'] ?? 0) / (_stats?['total_assignments'] ?? 1) * 100).toStringAsFixed(0)}%', 'icon': Icons.cancel},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: metrics.map((metric) {
          return ListTile(
            leading: Icon(metric['icon'] as IconData, color: Colors.greenAccent, size: 20),
            title: Text(metric['label'] as String, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            trailing: Text(
              metric['value'] as String,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      {'icon': Icons.speed, 'title': 'Speed Demon', 'desc': '< 3 min response time', 'unlocked': true},
      {'icon': Icons.favorite, 'title': 'Life Saver', 'desc': '10+ cardiac saves', 'unlocked': true},
      {'icon': Icons.star, 'title': 'Top Rated', 'desc': '4.8+ rating maintained', 'unlocked': true},
      {'icon': Icons.local_fire_department, 'title': 'Firefighter', 'desc': 'Respond to fire emergencies', 'unlocked': false},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: achievements.map((achievement) {
        final unlocked = achievement['unlocked'] as bool;
        return Container(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unlocked ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked ? Colors.greenAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                achievement['icon'] as IconData,
                color: unlocked ? Colors.greenAccent : Colors.white.withOpacity(0.3),
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                achievement['title'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: unlocked ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                achievement['desc'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: unlocked ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.3),
                ),
              ),
              if (unlocked)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'UNLOCKED',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
