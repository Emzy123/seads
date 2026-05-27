/// Parses shift payloads from `/api/paramedics/shifts`.
class ShiftRecord {
  final String id;
  final String type;
  final DateTime start;
  final DateTime end;
  final String status;
  final String partner;
  final String ambulanceId;

  ShiftRecord({
    required this.id,
    required this.type,
    required this.start,
    required this.end,
    required this.status,
    required this.partner,
    required this.ambulanceId,
  });

  factory ShiftRecord.fromJson(Map<String, dynamic> json) {
    return ShiftRecord(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Shift',
      start: _parseDate(json['start']),
      end: _parseDate(json['end']),
      status: json['status']?.toString() ?? 'scheduled',
      partner: json['partner']?.toString() ?? '',
      ambulanceId: json['ambulance_id']?.toString() ?? json['ambulanceId']?.toString() ?? '',
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

/// Groups [ShiftRecord] by calendar day for calendar UIs.
Map<DateTime, List<ShiftRecord>> groupShiftsByDay(List<ShiftRecord> shifts) {
  final map = <DateTime, List<ShiftRecord>>{};
  for (final s in shifts) {
    final key = DateTime(s.start.year, s.start.month, s.start.day);
    map.putIfAbsent(key, () => []).add(s);
  }
  return map;
}
