import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';

class ApiService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: AppConfig.backendUrl,
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => status != null && status < 500,
  ));

  /// Returns current Firebase ID token or null if not signed in.
  Future<String?> _getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /// Dispatches the nearest available ambulance to the given coordinates.
  /// Sends the Firebase ID token in the Authorization header so the backend
  /// can verify the caller's identity.
  Future<Map<String, dynamic>> dispatchAmbulance({
    required double lat,
    required double lng,
    required String patientId,
    required String emergencyType,
    String? description,
  }) async {
    final token = await _getToken();
    final response = await dio.post(
      '/api/dispatch',
      data: {
        'lat': lat,
        'lng': lng,
        'patient_id': patientId,
        'emergency_type': emergencyType,
        'description': description,
      },
      options: Options(
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
    return response.data;
  }

  /// Updates the paramedic's live ambulance location
  Future<void> updateLocation({required double lat, required double lng}) async {
    final token = await _getToken();
    if (token == null) return;
    
    await dio.put(
      '/api/ambulances/location',
      data: {'lat': lat, 'lng': lng},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Updates the status of an emergency incident
  Future<void> updateIncidentStatus({required String incidentId, required String status}) async {
    final token = await _getToken();
    if (token == null) return;

    await dio.put(
      '/api/incidents/$incidentId/status',
      data: {'status': status},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// Fetches all active incidents (Dispatcher/Paramedic view)
  Future<List<dynamic>> getAssignments() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/incidents',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    
    return response.data['incidents'] ?? [];
  }

  /// Fetches all ambulances (Dispatcher view)
  Future<List<dynamic>> getAllAmbulances() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/ambulances',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    
    return response.data['ambulances'] ?? [];
  }
}
