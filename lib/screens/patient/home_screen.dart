import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../core/offline_queue.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/seads_buttons.dart';
import '../../services/realtime_sync_service.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isDispatching = false;
  bool _isHolding = false;
  double _holdProgress = 0.0;
  Position? _currentPosition;
  final MapController _mapController = MapController();
  StreamSubscription? _notificationSubscription;
  Timer? _holdTimer;

  String _ambulanceStatus = 'none'; // none, dispatched, arriving, arrived
  final RealtimeSyncService _realtime = RealtimeSyncService();
  LatLng? _ambulancePosition;
  String _ambulanceName = 'AMB-201';

  // Medical snapshot data
  Map<String, dynamic> _medicalSnapshot = {
    'blood_type': '—',
    'allergies': <String>['Penicillin', 'Latex'],
    'conditions': <String>['Asthma'],
    'medications': <String>['Albuterol'],
  };

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _listenForNotifications();
    _loadMedicalSnapshot();
    _realtime.start(_pollActiveIncident);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _holdTimer?.cancel();
    _realtime.dispose();
    super.dispose();
  }

  Future<void> _pollActiveIncident() async {
    try {
      final data = await _apiService.getActiveIncident();
      if (!mounted) return;
      if (data.isEmpty || data['incident'] == null) {
        setState(() {
          _ambulanceStatus = 'none';
          _ambulancePosition = null;
        });
        _realtime.reportSuccess();
        return;
      }

      final incident = Map<String, dynamic>.from(data['incident'] as Map);
      final status = incident['status']?.toString() ?? 'none';
      
      final ambName = incident['ambulance_name']?.toString() ?? 'AMB-201';
      final ambLat = incident['ambulance_lat'];
      final ambLng = incident['ambulance_lng'];

      setState(() {
        _ambulanceStatus = (status == 'pending' || status == 'dispatched') 
            ? 'dispatched' 
            : (status == 'en_route' ? 'arriving' : (status == 'on_scene' ? 'arrived' : 'none'));
        _ambulanceName = ambName;
        if (ambLat != null && ambLng != null) {
          _ambulancePosition = LatLng((ambLat as num).toDouble(), (ambLng as num).toDouble());
        } else {
          _ambulancePosition = null;
        }
      });
      _realtime.reportSuccess();
    } catch (_) {
      _realtime.reportFailure();
    }
  }


  Future<void> _loadMedicalSnapshot() async {
    try {
      final profile = await _apiService.getMedicalProfile();
      if (!mounted || profile.isEmpty) return;
      setState(() {
        if (profile.containsKey('blood_type')) {
          final bt = profile['blood_type']?.toString().trim();
          if (bt != null && bt.isNotEmpty) {
            _medicalSnapshot['blood_type'] = bt;
          }
        }
        if (profile.containsKey('allergies')) {
          _medicalSnapshot['allergies'] = ApiService.coerceStringList(profile['allergies']);
        }
        if (profile.containsKey('conditions')) {
          _medicalSnapshot['conditions'] = ApiService.coerceStringList(profile['conditions']);
        }
        if (profile.containsKey('medications')) {
          _medicalSnapshot['medications'] = ApiService.coerceStringList(profile['medications']);
        }
      });
    } catch (_) {}
  }

  void _listenForNotifications() {
    _notificationSubscription = NotificationService()
        .foregroundMessages
        .listen((message) {
      if (!mounted) return;
      final title = message.notification?.title ?? 'SEADS';
      final body = message.notification?.body ?? '';
      
      // Update ambulance status based on message
      if (body.toLowerCase().contains('ambulance') && body.toLowerCase().contains('dispatched')) {
        setState(() => _ambulanceStatus = 'dispatched');
      } else if (body.toLowerCase().contains('arriving') || body.toLowerCase().contains('en route')) {
        setState(() => _ambulanceStatus = 'arriving');
      } else if (body.toLowerCase().contains('arrived') || body.toLowerCase().contains('on scene')) {
        setState(() => _ambulanceStatus = 'arrived');
      }
      
      _showNotificationPreview(title, body);
    });
  }

  void _showNotificationPreview(String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: NotificationPreview(
          title: title,
          message: body,
          icon: Icons.notifications_active,
          color: AppTheme.criticalRed,
          actionLabel: 'View',
          onAction: () {
            Navigator.pop(context);
            // Navigate to relevant screen
          },
        ),
      ),
    );
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = position);
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          16.0,
        );
      }
    } catch (e) {
      // Handle location error silently or show a toast
    }
  }

  void _startHold() {
    if (_isDispatching) return;
    if (!AppTheme.animationsEnabled(context)) {
      _requestSosViaTap();
      return;
    }

    AppTheme.hapticMedium();
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });

    _holdTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _holdProgress += 0.01;
        if (_holdProgress >= 1.0) {
          _holdProgress = 1.0;
          _completeHold();
        }
      });
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  void _completeHold() {
    _holdTimer?.cancel();
    setState(() {
      _isHolding = false;
    });
    AppTheme.hapticSuccess();
    _showSOSConfirmation();
  }

  void _requestSosViaTap() {
    if (_isDispatching) return;
    AppTheme.hapticMedium();
    _showSOSConfirmation();
  }

  void _showSOSConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              border: const Border(top: BorderSide(color: AppTheme.criticalRed)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.criticalRed, size: 64)
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  'Confirm Emergency',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'This will dispatch an ambulance to your current location immediately.',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _requestAmbulance();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.criticalRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Dispatch', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestAmbulance() async {
    setState(() => _isDispatching = true);
    Position? position;
    String? patientId;
    try {
      position = _currentPosition ?? await LocationService.getCurrentPosition();
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('Not logged in');
      patientId = user.uid;

      final response = await _apiService.dispatchAmbulance(
        lat: position.latitude,
        lng: position.longitude,
        patientId: patientId,
        emergencyType: 'Medical Emergency',
      );

      if (mounted) {
        setState(() => _ambulanceStatus = 'dispatched');
        _showSuccessDialog(
          (response['message'] ?? response['detail'] ?? 'Ambulance is en route!').toString(),
        );
      }
    } catch (e) {
      if (position != null && patientId != null) {
        try {
          await OfflineQueue.enqueue(
            type: 'dispatch',
            payload: {
              'lat': position.latitude,
              'lng': position.longitude,
              'patient_id': patientId,
              'emergency_type': 'Medical Emergency',
            },
          );
        if (mounted) {
          setState(() => _ambulanceStatus = 'dispatched');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request queued — will dispatch when connection returns'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ApiService.wrapError(e).userMessage),
                backgroundColor: AppTheme.criticalRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiService.wrapError(e).userMessage),
            backgroundColor: AppTheme.criticalRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDispatching = false);
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              const Text(
                'Ambulance Dispatched',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showLiveTrackingPopup();
                  },
                  child: const Text('Track Ambulance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLiveTrackingPopup() {
    AppTheme.hapticMedium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final ambPos = _ambulancePosition ?? (_currentPosition != null ? LatLng(_currentPosition!.latitude + 0.008, _currentPosition!.longitude + 0.008) : const LatLng(40.72, -74.00));
          final patientPos = _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : const LatLng(40.7128, -74.0060);
          final modalMapController = MapController();

          Color statusColor;
          String statusTitle;
          int currentStep;

          switch (_ambulanceStatus) {
            case 'dispatched':
              statusColor = AppTheme.criticalTeal;
              statusTitle = 'Ambulance Dispatched';
              currentStep = 1;
              break;
            case 'arriving':
              statusColor = AppTheme.statusResponding;
              statusTitle = 'Ambulance En Route';
              currentStep = 2;
              break;
            case 'arrived':
              statusColor = AppTheme.successGreen;
              statusTitle = 'Paramedic On Scene';
              currentStep = 3;
              break;
            default:
              statusColor = AppTheme.criticalTeal;
              statusTitle = 'Tracking Unit';
              currentStep = 1;
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.95),
                    border: Border(top: BorderSide(color: statusColor, width: 2)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.local_shipping, color: statusColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusTitle,
                                  style: AppTheme.headingSmall.copyWith(fontSize: 20, color: statusColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Unit: $_ambulanceName • ETA ~4 mins',
                                  style: AppTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Progress Stepper
                      _buildTrackingStepper(currentStep, statusColor),
                      const SizedBox(height: 20),

                      // Interactive Live Map Container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: modalMapController,
                                options: MapOptions(
                                  initialCenter: patientPos,
                                  initialZoom: 14.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                    subdomains: const ['a', 'b', 'c', 'd'],
                                  ),
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: [ambPos, patientPos],
                                        color: statusColor,
                                        strokeWidth: 4.0,
                                      ),
                                    ],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: patientPos,
                                        width: 60,
                                        height: 60,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppTheme.criticalTeal.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.my_location, color: AppTheme.criticalTeal, size: 28),
                                        ),
                                      ),
                                      Marker(
                                        point: ambPos,
                                        width: 60,
                                        height: 60,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.local_shipping, color: Colors.greenAccent, size: 28),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: FloatingActionButton.small(
                                  heroTag: 'recenter_map_tracking',
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                  onPressed: () {
                                    modalMapController.move(ambPos, 14.0);
                                  },
                                  child: const Icon(Icons.center_focus_strong, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Assigned Paramedic Card
                      GlassCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: statusColor.withOpacity(0.2),
                              child: Icon(Icons.person, color: statusColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Paramedic Johnson',
                                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Text('4.9 Rating • Unit $_ambulanceName', style: AppTheme.bodySmall),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () {
                                AppTheme.hapticLight();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Calling Paramedic Johnson ($_ambulanceName)...'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.phone, color: Colors.greenAccent),
                              style: IconButton.styleFrom(backgroundColor: Colors.greenAccent.withOpacity(0.2)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Emergency Instructions Card
                      GlassCard(
                        borderRadius: 16,
                        borderColor: Colors.orangeAccent.withOpacity(0.4),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'What to do while waiting',
                                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInstructionBullet('Stay calm and stay on line if emergency operators call.'),
                            _buildInstructionBullet('Unlock your front door and turn on porch lights if dark.'),
                            _buildInstructionBullet('Keep pets secured in a separate room.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Actions: Share & Cancel
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                AppTheme.hapticLight();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Live tracking link copied to clipboard'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share Location'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.white30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _confirmCancelRequest(context);
                              },
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const Text('Cancel Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.criticalRed.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
          );
        },
      ),
    );
  }

  Widget _buildTrackingStepper(int currentStep, Color activeColor) {
    final steps = ['Dispatched', 'En Route', 'Arriving', 'On Scene'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isDone = index + 1 <= currentStep;
        final isCurrent = index + 1 == currentStep;
        final color = isDone ? activeColor : Colors.white24;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == 0 ? Colors.transparent : (index <= currentStep - 1 ? activeColor : Colors.white24),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDone ? color : Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(color: isCurrent ? activeColor : Colors.white24, width: 2),
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      size: 12,
                      color: isDone ? Colors.black : Colors.white24,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == steps.length - 1 ? Colors.transparent : (index < currentStep - 1 ? activeColor : Colors.white24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInstructionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: AppTheme.bodySmall.copyWith(color: Colors.white70))),
        ],
      ),
    );
  }

  void _confirmCancelRequest(BuildContext modalContext) {
    showDialog(
      context: modalContext,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Dispatch?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel the emergency ambulance request?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep Active'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(modalContext);
              setState(() {
                _ambulanceStatus = 'none';
                _ambulancePosition = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency request cancelled')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.criticalRed),
            child: const Text('Cancel Emergency'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSnapshot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Medical Snapshot', style: AppTheme.headingSmall.copyWith(fontSize: 18))),
            GestureDetector(
              onTap: () => context.push('/medical-profile'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.criticalTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: AppTheme.criticalTeal, size: 14),
                    const SizedBox(width: 4),
                    Text('Edit', style: AppTheme.bodySmall.copyWith(color: AppTheme.criticalTeal)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMedicalChip(Icons.water_drop, 'Blood Type', _medicalSnapshot['blood_type']?.toString() ?? '—', AppTheme.criticalRed),
              ...(ApiService.coerceStringList(_medicalSnapshot['allergies'])).map((allergy) =>
                _buildMedicalChip(Icons.warning_amber_rounded, 'Allergy', allergy, AppTheme.priorityHigh)
              ),
              ...(ApiService.coerceStringList(_medicalSnapshot['conditions'])).map((condition) =>
                _buildMedicalChip(Icons.medical_services, 'Condition', condition, AppTheme.criticalTeal)
              ),
              ...(ApiService.coerceStringList(_medicalSnapshot['medications'])).map((med) =>
                _buildMedicalChip(Icons.medication, 'Medication', med, AppTheme.accentOrange)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalChip(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTheme.bodySmall.copyWith(fontSize: 10)),
              Text(value, style: AppTheme.bodyMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickAction(Icons.history, 'History', '/history', Colors.blueAccent),
          const SizedBox(width: 16),
          _buildQuickAction(Icons.contacts, 'Contacts', '/contacts', Colors.greenAccent),
          const SizedBox(width: 16),
          _buildQuickAction(Icons.person, 'Profile', '/medical-profile', AppTheme.criticalTeal),
          const SizedBox(width: 16),
          _buildQuickAction(Icons.settings, 'Settings', '/settings', Colors.white54),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, String route, Color color) {
    return GestureDetector(
      onTap: () {
        AppTheme.hapticLight();
        context.push(route);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return EmergencySosButton(
      isDispatching: _isDispatching,
      isHolding: _isHolding,
      holdProgress: _holdProgress,
      onHoldStart: _startHold,
      onHoldEnd: _cancelHold,
      onHoldCancel: _cancelHold,
      onTapAlternative: _requestSosViaTap,
    );
  }

  Widget _buildLiveStatusBar() {
    if (_ambulanceStatus == 'none') return const SizedBox.shrink();
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (_ambulanceStatus) {
      case 'dispatched':
        statusColor = AppTheme.criticalTeal;
        statusText = 'Ambulance Dispatched';
        statusIcon = Icons.local_shipping;
        break;
      case 'arriving':
        statusColor = AppTheme.statusResponding;
        statusText = 'Ambulance Arriving';
        statusIcon = Icons.access_time_filled;
        break;
      case 'arrived':
        statusColor = AppTheme.successGreen;
        statusText = 'Ambulance On Scene';
        statusIcon = Icons.check_circle;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: GlassCard(
        onTap: () {
          AppTheme.hapticLight();
          _showLiveTrackingPopup();
        },
        borderRadius: 16,
        borderColor: statusColor,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('ETA: 4 minutes • Unit: $_ambulanceName • Tap to track', style: AppTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.touch_app, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            BreathingPulse(color: statusColor, size: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'patient', activeRoute: '/home', accentColor: Colors.greenAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: AppTheme.glassBlur, sigmaY: AppTheme.glassBlur),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_hospital, color: AppTheme.criticalTeal, size: 24),
            const SizedBox(width: 8),
            Text('SEADS', style: AppTheme.headingSmall.copyWith(fontSize: 20, letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: StatusIndicator(status: 'online', label: 'Connected'),
            ),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: Stack(
          children: [
            // 1. Live Map Background
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition != null 
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : const LatLng(0, 0),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(
                  markers: [
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        width: 80,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.criticalTeal.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: AppTheme.criticalTeal,
                            size: 30,
                          ).animate(onPlay: (controller) => controller.repeat())
                           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds)
                           .fade(end: 0),
                        ),
                      ),
                    if (_ambulancePosition != null)
                      Marker(
                        point: _ambulancePosition!,
                        width: 80,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Colors.greenAccent,
                            size: 30,
                          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // 2. Live Status Bar (when ambulance dispatched)
            _buildLiveStatusBar(),

            // 3. Glassmorphic Bottom Control Panel
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.glassBorderRadius)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: AppTheme.glassBlur, sigmaY: AppTheme.glassBlur),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    decoration: BoxDecoration(
                      color: AppTheme.glassBackground,
                      border: const Border(
                        top: BorderSide(color: AppTheme.glassBorder),
                      ),
                      boxShadow: AppTheme.glassShadow,
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header
                            userProfileAsync.when(
                              data: (profile) => Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppTheme.criticalTeal.withOpacity(0.2),
                                    child: Text(
                                      profile?.name.substring(0, 1) ?? 'P',
                                      style: AppTheme.headingMedium.copyWith(fontSize: 22, color: AppTheme.criticalTeal),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Good evening,',
                                          style: AppTheme.bodyMedium,
                                        ),
                                        Text(
                                          profile?.name.split(' ')[0] ?? 'Patient',
                                          style: AppTheme.headingSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => SkeletonCard(height: 60),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            
                            const SizedBox(height: 24),

                            // Medical Snapshot
                            _buildMedicalSnapshot(),
                            
                            const SizedBox(height: 20),

                            // Emergency Call Line Banner
                            GlassCard(
                              borderRadius: 16,
                              borderColor: AppTheme.criticalRed,
                              onTap: () async {
                                AppTheme.hapticMedium();
                                final uri = Uri.parse('tel:${AppConfig.emergencyCallLine}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Calling Emergency Line: 09164880144')),
                                    );
                                  }
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.criticalRed.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.phone_in_talk, color: AppTheme.criticalRed, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'EMERGENCY CALL LINE',
                                            style: AppTheme.bodySmall.copyWith(color: AppTheme.criticalRed, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                                          ),
                                          Text(
                                            AppConfig.emergencyCallLine,
                                            style: AppTheme.headingSmall.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.call, color: Colors.greenAccent, size: 14),
                                          SizedBox(width: 6),
                                          Text('CALL', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Center(child: _buildSOSButton()),
                            const SizedBox(height: 24),
                            
                            // Quick Actions
                            _buildQuickActions(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
