import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';

class ReportsAnalyticsScreen extends ConsumerStatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  ConsumerState<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends ConsumerState<ReportsAnalyticsScreen> {
  String _selectedPeriod = 'week';
  String _selectedReport = 'overview';

  final Map<String, dynamic> _mockData = {
    'overview': {
      'total_incidents': 156,
      'avg_response_time': '4.2 min',
      'completion_rate': 94.2,
      'patient_satisfaction': 4.7,
      'daily_incidents': [12, 18, 15, 22, 19, 25, 45],
      'response_time_trend': [5.1, 4.8, 4.5, 4.3, 4.2, 4.1, 4.2],
    },
    'incidents': {
      'by_type': [
        {'type': 'Cardiac Emergency', 'count': 42, 'percentage': 27},
        {'type': 'Trauma', 'count': 38, 'percentage': 24},
        {'type': 'Respiratory', 'count': 28, 'percentage': 18},
        {'type': 'Neurological', 'count': 18, 'percentage': 12},
        {'type': 'Other', 'count': 30, 'percentage': 19},
      ],
      'by_priority': [
        {'priority': 'Critical', 'count': 45, 'color': 0xFFFF6B6B},
        {'priority': 'High', 'count': 67, 'color': 0xFFFFA502},
        {'priority': 'Medium', 'count': 32, 'color': 0xFF2ED573},
        {'priority': 'Low', 'count': 12, 'color': 0xFF70A1FF},
      ],
      'by_hour': List.generate(24, (i) => {'hour': i, 'count': Random().nextInt(20) + 1}),
    },
    'fleet': {
      'utilization_rate': 78.5,
      'avg_distance_per_incident': 8.3,
      'fuel_consumption': 1245,
      'maintenance_cost': 15400,
      'vehicle_performance': [
        {'id': 'AMB-201', 'incidents': 28, 'rating': 4.8},
        {'id': 'AMB-202', 'incidents': 32, 'rating': 4.6},
        {'id': 'AMB-204', 'incidents': 24, 'rating': 4.9},
        {'id': 'AMB-205', 'incidents': 31, 'rating': 4.7},
      ],
    },
    'personnel': {
      'total_paramedics': 24,
      'on_duty': 18,
      'avg_rating': 4.6,
      'top_performers': [
        {'name': 'Paramedic Johnson', 'incidents': 42, 'rating': 4.9, 'response_time': '3.2 min'},
        {'name': 'Paramedic Smith', 'incidents': 38, 'rating': 4.8, 'response_time': '3.5 min'},
        {'name': 'Paramedic Davis', 'incidents': 35, 'rating': 4.8, 'response_time': '3.4 min'},
        {'name': 'Paramedic Wilson', 'incidents': 33, 'rating': 4.7, 'response_time': '3.6 min'},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'dispatcher', activeRoute: '/reports', accentColor: Colors.orangeAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('REPORTS & ANALYTICS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.orangeAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportReport(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'day', child: Text('Today')),
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'quarter', child: Text('This Quarter')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Type Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildReportTypeChip('Overview', 'overview', Icons.dashboard),
                _buildReportTypeChip('Incidents', 'incidents', Icons.warning),
                _buildReportTypeChip('Fleet', 'fleet', Icons.local_shipping),
                _buildReportTypeChip('Personnel', 'personnel', Icons.people),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Period Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PERIOD: ${_selectedPeriod.toUpperCase()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Report Content
          _buildReportContent(),
        ],
      ),
    );
  }

  Widget _buildReportTypeChip(String label, String value, IconData icon) {
    final isSelected = _selectedReport == value;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedReport = value),
        avatar: Icon(icon, size: 18, color: isSelected ? Colors.black : Colors.orangeAccent),
        label: Text(label),
        selectedColor: Colors.orangeAccent,
        backgroundColor: Colors.white.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReport) {
      case 'overview':
        return _buildOverviewReport();
      case 'incidents':
        return _buildIncidentsReport();
      case 'fleet':
        return _buildFleetReport();
      case 'personnel':
        return _buildPersonnelReport();
      default:
        return _buildOverviewReport();
    }
  }

  Widget _buildOverviewReport() {
    final data = _mockData['overview'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Cards
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Total Incidents',
                data['total_incidents'].toString(),
                Icons.warning,
                Colors.redAccent,
                '+12% vs last ${_selectedPeriod}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Avg Response',
                data['avg_response_time'],
                Icons.timer,
                Colors.blueAccent,
                '-0.3 min improvement',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Completion Rate',
                '${data['completion_rate']}%',
                Icons.check_circle,
                Colors.greenAccent,
                'Exceeds target of 90%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Satisfaction',
                '⭐ ${data['patient_satisfaction']}',
                Icons.star,
                Colors.yellow,
                'Based on 124 reviews',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Daily Incidents Chart
        _buildSectionTitle('Daily Incident Volume'),
        const SizedBox(height: 12),
        _buildBarChart(data['daily_incidents'] as List, Colors.orangeAccent),
        
        const SizedBox(height: 24),
        
        // Response Time Trend
        _buildSectionTitle('Response Time Trend (minutes)'),
        const SizedBox(height: 12),
        _buildLineChart(data['response_time_trend'] as List, Colors.blueAccent),
      ],
    );
  }

  Widget _buildIncidentsReport() {
    final data = _mockData['incidents'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // By Type
        _buildSectionTitle('Incidents by Type'),
        const SizedBox(height: 12),
        _buildIncidentTypeChart(data['by_type'] as List),
        
        const SizedBox(height: 24),
        
        // By Priority
        _buildSectionTitle('Incidents by Priority'),
        const SizedBox(height: 12),
        _buildPriorityChart(data['by_priority'] as List),
        
        const SizedBox(height: 24),
        
        // Hourly Distribution
        _buildSectionTitle('Hourly Distribution'),
        const SizedBox(height: 12),
        _buildHourlyChart(data['by_hour'] as List),
      ],
    );
  }

  Widget _buildFleetReport() {
    final data = _mockData['fleet'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fleet KPIs
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Utilization',
                '${data['utilization_rate']}%',
                Icons.local_shipping,
                Colors.blueAccent,
                'Fleet efficiency metric',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Avg Distance',
                '${data['avg_distance_per_incident']} km',
                Icons.route,
                Colors.greenAccent,
                'Per incident average',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Fuel Used',
                '${data['fuel_consumption']} L',
                Icons.local_gas_station,
                Colors.orangeAccent,
                'This ${_selectedPeriod}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Maintenance',
                '\$${NumberFormat('#,###').format(data['maintenance_cost'])}',
                Icons.build,
                Colors.redAccent,
                'Operational costs',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Vehicle Performance
        _buildSectionTitle('Vehicle Performance'),
        const SizedBox(height: 12),
        ...((data['vehicle_performance'] as List).map((v) => _buildVehiclePerformanceCard(v))),
      ],
    );
  }

  Widget _buildPersonnelReport() {
    final data = _mockData['personnel'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personnel KPIs
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Total Paramedics',
                data['total_paramedics'].toString(),
                Icons.people,
                Colors.blueAccent,
                'Active roster',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'On Duty Now',
                data['on_duty'].toString(),
                Icons.person,
                Colors.greenAccent,
                'Currently active',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: _buildKPICard(
            'Team Avg Rating',
            '⭐ ${data['avg_rating']}',
            Icons.star,
            Colors.yellow,
            'Patient satisfaction',
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Top Performers
        _buildSectionTitle('Top Performers'),
        const SizedBox(height: 12),
        ...((data['top_performers'] as List).map((p) => _buildPerformerCard(p))),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
          ),
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

  Widget _buildBarChart(List data, Color color) {
    final maxValue = (data as List<int>).reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.asMap().entries.map((entry) {
                final height = maxValue > 0 ? (entry.value / maxValue) * 100 : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(entry.value.toString(), style: TextStyle(fontSize: 10, color: color)),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][entry.key],
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
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

  Widget _buildLineChart(List data, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: LineChartPainter(data as List<double>, color),
      ),
    );
  }

  Widget _buildIncidentTypeChart(List types) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: (types as List).map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(type['type'], style: const TextStyle(fontSize: 13, color: Colors.white)),
                    Text('${type['count']} (${type['percentage']}%)', style: const TextStyle(fontSize: 13, color: Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: type['percentage'] / 100,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent.withOpacity(0.7)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityChart(List priorities) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: (priorities as List).map((p) {
          final color = Color(p['color']);
          final percentage = p['count'] / priorities.fold(0, (sum, p) => sum + (p['count'] as int));
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: color),
                    ),
                    child: Center(
                      child: Text(
                        p['count'].toString(),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(p['priority'], style: TextStyle(fontSize: 12, color: color)),
                  Text('${(percentage * 100).toInt()}%', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHourlyChart(List hours) {
    final maxCount = (hours as List).map((h) => h['count'] as int).reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: (hours).map((h) {
            final height = maxCount > 0 ? (h['count'] / maxCount) * 100 : 0.0;
            final hour = h['hour'] as int;
            return Expanded(
              child: Tooltip(
                message: '${h['count']} incidents at ${hour.toString().padLeft(2, '0')}:00',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: height,
                  decoration: BoxDecoration(
                    color: hour >= 8 && hour <= 20 ? Colors.blueAccent : Colors.blueAccent.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVehiclePerformanceCard(dynamic v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_shipping, color: Colors.blueAccent),
        ),
        title: Text(v['id'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text('${v['incidents']} incidents handled', style: TextStyle(color: Colors.white.withOpacity(0.6))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.yellow, size: 18),
            const SizedBox(width: 4),
            Text(v['rating'].toString(), style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerCard(dynamic p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.greenAccent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.greenAccent.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.greenAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('${p['incidents']} incidents • ${p['response_time']} avg response', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 20),
                const SizedBox(width: 4),
                Text(p['rating'].toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting report as PDF...')),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  LineChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 6, Paint()..color = color.withOpacity(0.3)..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
