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

  /// Saves the device's FCM push token to the backend for notifications
  Future<void> saveFcmToken(String fcmToken) async {
    final token = await _getToken();
    if (token == null) return;

    await dio.post(
      '/api/users/fcm-token',
      data: {'fcm_token': fcmToken},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ==================== PATIENT API METHODS ====================

  /// Fetches emergency history for the current patient
  Future<List<dynamic>> getEmergencyHistory() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/patients/history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['history'] ?? [];
  }

  /// Fetches emergency contacts for the current patient
  Future<List<dynamic>> getEmergencyContacts() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/patients/contacts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['contacts'] ?? [];
  }

  /// Fetches medical profile for the current patient
  Future<Map<String, dynamic>> getMedicalProfile() async {
    final token = await _getToken();
    if (token == null) return {};

    final response = await dio.get(
      '/api/patients/medical-profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data ?? {};
  }

  /// Updates medical profile for the current patient
  Future<void> updateMedicalProfile(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) return;

    await dio.put(
      '/api/patients/medical-profile',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ==================== PARAMEDIC API METHODS ====================

  /// Fetches assignment history for the current paramedic
  Future<List<dynamic>> getAssignmentHistory() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/paramedics/history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['assignments'] ?? [];
  }

  /// Fetches performance stats for the current paramedic
  Future<Map<String, dynamic>> getPerformanceStats({String period = 'week'}) async {
    final token = await _getToken();
    if (token == null) return {};

    final response = await dio.get(
      '/api/paramedics/stats',
      queryParameters: {'period': period},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data ?? {};
  }

  // ==================== DISPATCHER API METHODS ====================

  /// Fetches fleet information for dispatchers
  Future<List<dynamic>> getFleet() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/dispatchers/fleet',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['fleet'] ?? [];
  }

  /// Fetches staff list for dispatchers
  Future<List<dynamic>> getStaff() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/dispatchers/staff',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['staff'] ?? [];
  }

  /// Fetches incident log for dispatchers
  Future<List<dynamic>> getIncidentLog({Map<String, dynamic>? filters}) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/dispatchers/incidents',
      queryParameters: filters,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['incidents'] ?? [];
  }

  /// Fetches analytics reports for dispatchers
  Future<Map<String, dynamic>> getAnalytics({String period = 'week'}) async {
    final token = await _getToken();
    if (token == null) return {};

    final response = await dio.get(
      '/api/dispatchers/analytics',
      queryParameters: {'period': period},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data ?? {};
  }
}
