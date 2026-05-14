import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

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
  bool _showConfirmation = false;
  String _ambulanceStatus = 'none'; // none, dispatched, arriving, arrived

  // Medical snapshot data
  final Map<String, dynamic> _medicalSnapshot = {
    'blood_type': 'A+',
    'allergies': ['Penicillin', 'Latex'],
    'conditions': ['Asthma'],
    'medications': ['Albuterol'],
  };

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _listenForNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _holdTimer?.cancel();
    super.dispose();
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
      _showConfirmation = true;
    });
    AppTheme.hapticSuccess();
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
                          setState(() => _showConfirmation = false);
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
    try {
      final position = _currentPosition ?? await LocationService.getCurrentPosition();

      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('Not logged in');

      final response = await _apiService.dispatchAmbulance(
        lat: position.latitude,
        lng: position.longitude,
        patientId: user.uid,
        emergencyType: 'Medical Emergency',
      );

      if (mounted) {
        setState(() => _ambulanceStatus = 'dispatched');
        _showSuccessDialog(response['message'] ?? 'Ambulance is en route!');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Track Ambulance', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
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
            Text('Medical Snapshot', style: AppTheme.headingSmall.copyWith(fontSize: 18)),
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
              _buildMedicalChip(Icons.water_drop, 'Blood Type', _medicalSnapshot['blood_type'], AppTheme.criticalRed),
              ...(_medicalSnapshot['allergies'] as List).map((allergy) => 
                _buildMedicalChip(Icons.warning_amber_rounded, 'Allergy', allergy, AppTheme.priorityHigh)
              ),
              ...(_medicalSnapshot['conditions'] as List).map((condition) => 
                _buildMedicalChip(Icons.medical_services, 'Condition', condition, AppTheme.criticalTeal)
              ),
              ...(_medicalSnapshot['medications'] as List).map((med) => 
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickAction(Icons.history, 'History', '/history', Colors.blueAccent),
        _buildQuickAction(Icons.contacts, 'Contacts', '/contacts', Colors.greenAccent),
        _buildQuickAction(Icons.person, 'Profile', '/medical-profile', AppTheme.criticalTeal),
        _buildQuickAction(Icons.settings, 'Settings', '/settings', Colors.white54),
      ],
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
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: () => _cancelHold(),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppTheme.criticalRed,
              AppTheme.criticalRed.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.criticalRed.withOpacity(0.5 + (_isHolding ? _holdProgress * 0.3 : 0)),
              blurRadius: 30 + (_isHolding ? _holdProgress * 20 : 0),
              spreadRadius: 10 + (_isHolding ? _holdProgress * 15 : 0),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring
            if (_isHolding || _holdProgress > 0)
              SizedBox(
                width: 136,
                height: 136,
                child: CircularProgressIndicator(
                  value: _holdProgress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                ),
              ),
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isDispatching)
                  const SpinKitDoubleBounce(color: Colors.white, size: 40)
                else ...[
                  const Icon(Icons.emergency, color: Colors.white, size: 36),
                  const SizedBox(height: 4),
                  Text(
                    _isHolding ? 'Hold...' : 'SOS',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      )
      .animate(target: _isHolding ? 1 : 0)
      .scale(begin: const Offset(1, 1), end: const Offset(0.95, 0.95), duration: 100.ms),
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
                  Text('ETA: 4 minutes • Unit: AMB-201', style: AppTheme.bodySmall),
                ],
              ),
            ),
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
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
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
                          
                          const SizedBox(height: 32),

                          // SOS Button
                          Center(child: _buildSOSButton()),
                          
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              _isHolding ? 'Keep holding to confirm...' : 'Hold for 3 seconds to dispatch',
                              style: AppTheme.bodySmall,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Quick Actions
                          _buildQuickActions(),
                        ],
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
