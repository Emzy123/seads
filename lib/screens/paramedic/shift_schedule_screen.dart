import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/app_drawer.dart';

class ShiftScheduleScreen extends ConsumerStatefulWidget {
  const ShiftScheduleScreen({super.key});

  @override
  ConsumerState<ShiftScheduleScreen> createState() => _ShiftScheduleScreenState();
}

class _ShiftScheduleScreenState extends ConsumerState<ShiftScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock shift data
  final Map<DateTime, List<Shift>> _shifts = {};
  final List<ShiftSwapRequest> _swapRequests = [];

  @override
  void initState() {
    super.initState();
    _generateMockShifts();
  }

  void _generateMockShifts() {
    final now = DateTime.now();
    for (int i = -7; i < 30; i++) {
      final date = now.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      
      // Generate varying shifts
      if (i % 3 == 0) {
        _shifts[dateKey] = [
          Shift(
            type: 'Day Shift',
            start: DateTime(date.year, date.month, date.day, 8, 0),
            end: DateTime(date.year, date.month, date.day, 20, 0),
            status: i < 0 ? 'completed' : (i == 0 ? 'active' : 'scheduled'),
            partner: 'Paramedic Johnson',
            ambulanceId: 'AMB-204',
          ),
        ];
      } else if (i % 3 == 1) {
        _shifts[dateKey] = [
          Shift(
            type: 'Night Shift',
            start: DateTime(date.year, date.month, date.day, 20, 0),
            end: DateTime(date.year, date.month, date.day + 1, 8, 0),
            status: i < 0 ? 'completed' : (i == 0 ? 'active' : 'scheduled'),
            partner: 'Paramedic Smith',
            ambulanceId: 'AMB-205',
          ),
        ];
      }
    }

    _swapRequests.addAll([
      ShiftSwapRequest(
        id: '1',
        requesterName: 'Paramedic Davis',
        requesterShift: 'Dec 15 - Day Shift',
        yourShift: 'Dec 16 - Day Shift',
        status: 'pending',
      ),
    ]);
  }

  List<Shift> _getShiftsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _shifts[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'paramedic', activeRoute: '/schedule', accentColor: Colors.greenAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('SHIFT SCHEDULE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.greenAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _showSwapRequests(),
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _requestTimeOff(),
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.beach_access),
        label: const Text('Request Time Off'),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Shift Card
          _buildCurrentShiftCard(),
          const SizedBox(height: 24),

          // Calendar
          _buildCalendar(),
          const SizedBox(height: 24),

          // Selected Day Shifts
          if (_selectedDay != null) ...[
            Text(
              'Shifts for ${DateFormat('MMMM dd').format(_selectedDay!)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ..._getShiftsForDay(_selectedDay!).map((shift) => _buildShiftCard(shift)),
            if (_getShiftsForDay(_selectedDay!).isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No shifts scheduled',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ),
          ],

          const SizedBox(height: 24),

          // Upcoming Shifts
          const Text(
            'Upcoming Shifts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ..._buildUpcomingShifts(),

          const SizedBox(height: 24),

          // Shift Stats
          _buildShiftStats(),
        ],
      ),
    );
  }

  Widget _buildCurrentShiftCard() {
    final currentShifts = _getShiftsForDay(DateTime.now());
    final activeShift = currentShifts.firstWhere(
      (s) => s.status == 'active',
      orElse: () => Shift(type: '', start: DateTime.now(), end: DateTime.now(), status: 'none', partner: '', ambulanceId: ''),
    );

    if (activeShift.status == 'none') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule, color: Colors.white54, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Active Shift',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your next shift will appear here',
                    style: TextStyle(fontSize: 13, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.greenAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.black, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'ON DUTY',
                      style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activeShift.ambulanceId,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            activeShift.type,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('h:mm a').format(activeShift.start)} - ${DateFormat('h:mm a').format(activeShift.end)}',
            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(
                'Partner: ${activeShift.partner}',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Clock Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _requestSwap(activeShift),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Request Swap'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
          eventLoader: _getShiftsForDay,
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            defaultTextStyle: const TextStyle(color: Colors.white),
            weekendTextStyle: const TextStyle(color: Colors.white70),
            outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
          headerStyle: HeaderStyle(
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            formatButtonTextStyle: const TextStyle(color: Colors.white),
            formatButtonDecoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.white70),
            weekendStyle: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftCard(Shift shift) {
    final isDayShift = shift.type.toLowerCase().contains('day');
    final isCompleted = shift.status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isCompleted ? Colors.white.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDayShift ? Colors.orangeAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDayShift ? Icons.wb_sunny : Icons.nights_stay,
            color: isDayShift ? Colors.orangeAccent : Colors.blueAccent,
          ),
        ),
        title: Text(shift.type, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(
          '${DateFormat('h:mm a').format(shift.start)} - ${DateFormat('h:mm a').format(shift.end)}\nWith: ${shift.partner}',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.white.withOpacity(0.1)
                    : Colors.greenAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shift.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.white54 : Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              shift.ambulanceId,
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUpcomingShifts() {
    final now = DateTime.now();
    final upcoming = _shifts.entries
        .where((e) => e.key.isAfter(now.subtract(const Duration(days: 1))))
        .take(3)
        .expand((e) => e.value)
        .where((s) => s.status != 'completed')
        .toList();

    if (upcoming.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'No upcoming shifts scheduled',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
        ),
      ];
    }

    return upcoming.map((shift) => _buildShiftCard(shift)).toList();
  }

  Widget _buildShiftStats() {
    final totalShifts = _shifts.values.expand((s) => s).length;
    final completedShifts = _shifts.values.expand((s) => s).where((s) => s.status == 'completed').length;
    final dayShifts = _shifts.values.expand((s) => s).where((s) => s.type.toLowerCase().contains('day')).length;
    final nightShifts = _shifts.values.expand((s) => s).where((s) => s.type.toLowerCase().contains('night')).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shift Statistics (30 Days)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Total', totalShifts.toString(), Icons.calendar_today)),
              Expanded(child: _buildStatItem('Completed', completedShifts.toString(), Icons.check_circle)),
              Expanded(child: _buildStatItem('Day', dayShifts.toString(), Icons.wb_sunny)),
              Expanded(child: _buildStatItem('Night', nightShifts.toString(), Icons.nights_stay)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
      ],
    );
  }

  void _showSwapRequests() {
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
              border: const Border(top: BorderSide(color: Colors.greenAccent)),
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
                const Text('Shift Swap Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                if (_swapRequests.isEmpty)
                  Center(
                    child: Text(
                      'No pending swap requests',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  )
                else
                  ..._swapRequests.map((request) => _buildSwapRequestCard(request)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwapRequestCard(ShiftSwapRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.greenAccent.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.greenAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.requesterName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Wants to swap shifts', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('PENDING', style: TextStyle(fontSize: 10, color: Colors.orangeAccent)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_forward, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Their shift: ${request.requesterShift}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your shift: ${request.yourShift}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _requestSwap(Shift shift) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Swap request feature coming soon')),
    );
  }

  void _requestTimeOff() {
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
                const Text('Request Time Off', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'From Date',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'To Date',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Reason (optional)',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Time off request submitted')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Shift {
  final String type;
  final DateTime start;
  final DateTime end;
  final String status;
  final String partner;
  final String ambulanceId;

  Shift({
    required this.type,
    required this.start,
    required this.end,
    required this.status,
    required this.partner,
    required this.ambulanceId,
  });
}

class ShiftSwapRequest {
  final String id;
  final String requesterName;
  final String requesterShift;
  final String yourShift;
  final String status;

  ShiftSwapRequest({
    required this.id,
    required this.requesterName,
    required this.requesterShift,
    required this.yourShift,
    required this.status,
  });
}
