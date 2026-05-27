import 'package:hive_flutter/hive_flutter.dart';
import '../services/api_service.dart';

/// Persistent FIFO queue for actions that failed while offline.
class OfflineQueue {
  static const _boxName = 'offline_queue_v1';
  static const _maxRetries = 5;
  static Box<dynamic>? _box;

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  static int get pendingCount => _box?.length ?? 0;

  static Future<void> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await init();
    await _box!.add({
      'type': type,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'retries': 0,
    });
  }

  static Future<int> processAll(ApiService api) async {
    await init();
    if (_box == null || _box!.isEmpty) return 0;

    var synced = 0;
    final keys = _box!.keys.toList();

    for (final key in keys) {
      final raw = _box!.get(key);
      if (raw is! Map) {
        await _box!.delete(key);
        continue;
      }
      final item = Map<String, dynamic>.from(raw);
      final type = item['type']?.toString() ?? '';
      final payload = Map<String, dynamic>.from(item['payload'] as Map? ?? {});
      final retries = (item['retries'] as int?) ?? 0;

      try {
        await _execute(api, type, payload);
        await _box!.delete(key);
        synced++;
      } catch (_) {
        if (retries >= _maxRetries) {
          await _box!.delete(key);
        } else {
          item['retries'] = retries + 1;
          await _box!.put(key, item);
        }
      }
    }
    return synced;
  }

  static Future<void> _execute(
    ApiService api,
    String type,
    Map<String, dynamic> payload,
  ) async {
    switch (type) {
      case 'dispatch':
        await api.dispatchAmbulance(
          lat: (payload['lat'] as num).toDouble(),
          lng: (payload['lng'] as num).toDouble(),
          patientId: payload['patient_id'].toString(),
          emergencyType: payload['emergency_type']?.toString() ?? 'Medical Emergency',
          description: payload['description']?.toString(),
        );
        break;
      case 'location':
        await api.updateLocation(
          lat: (payload['lat'] as num).toDouble(),
          lng: (payload['lng'] as num).toDouble(),
        );
        break;
      case 'incident_status':
        await api.updateIncidentStatus(
          incidentId: payload['incident_id'].toString(),
          status: payload['status'].toString(),
        );
        break;
      case 'paramedic_status':
        await api.updateParamedicStatus(payload['status'].toString());
        break;
      default:
        throw UnsupportedError('Unknown offline action: $type');
    }
  }
}
