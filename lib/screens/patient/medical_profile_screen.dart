import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';

class MedicalProfileScreen extends ConsumerStatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  ConsumerState<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends ConsumerState<MedicalProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _apiService.getMedicalProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          _populateControllers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateControllers() {
    _bloodTypeController.text = _profile?['blood_type']?.toString() ?? '';
    _allergiesController.text = ApiService.coerceStringList(_profile?['allergies']).join(', ');
    _medicationsController.text = ApiService.coerceStringList(_profile?['medications']).join(', ');
    _conditionsController.text = ApiService.coerceStringList(_profile?['conditions']).join(', ');
    _notesController.text = _profile?['additional_notes']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'patient', activeRoute: '/medical-profile', accentColor: Colors.blueAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('MEDICAL PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: SpinKitPulse(color: Colors.blueAccent, size: 60))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Critical Info Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.redAccent.withOpacity(0.3), Colors.orangeAccent.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.health_and_safety, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Critical Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Visible to paramedics during emergencies',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCriticalInfoRow('Blood Type', _profile?['blood_type'] ?? 'Not specified', Icons.bloodtype),
                _buildCriticalInfoRow('Allergies', (_profile?['allergies'] as List?)?.join(', ') ?? 'None listed', Icons.warning),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Blood Type Section
          _buildSection(
            title: 'Blood Type',
            icon: Icons.water_drop,
            color: Colors.redAccent,
            content: _isEditing
                ? _buildDropdownField(
                    value: _bloodTypeController.text.isEmpty ? null : _bloodTypeController.text,
                    items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'],
                    onChanged: (value) => setState(() => _bloodTypeController.text = value ?? ''),
                  )
                : _buildInfoCard(
                    _profile?['blood_type'] ?? 'Not specified',
                    'Your blood type is critical for emergency transfusions',
                    Icons.water_drop,
                    Colors.redAccent,
                  ),
          ),
          
          // Allergies Section
          _buildSection(
            title: 'Allergies',
            icon: Icons.warning,
            color: Colors.orangeAccent,
            content: _isEditing
                ? _buildTextField(
                    controller: _allergiesController,
                    hint: 'e.g., Penicillin, Peanuts, Latex (comma separated)',
                    maxLines: 2,
                  )
                : _buildTagsList(
                    (_profile?['allergies'] as List?) ?? [],
                    Colors.orangeAccent,
                    'No allergies recorded',
                  ),
          ),
          
          // Medications Section
          _buildSection(
            title: 'Current Medications',
            icon: Icons.medication,
            color: Colors.blueAccent,
            content: _isEditing
                ? _buildTextField(
                    controller: _medicationsController,
                    hint: 'e.g., Insulin, Blood pressure meds (comma separated)',
                    maxLines: 3,
                  )
                : _buildTagsList(
                    (_profile?['medications'] as List?) ?? [],
                    Colors.blueAccent,
                    'No medications recorded',
                  ),
          ),
          
          // Medical Conditions Section
          _buildSection(
            title: 'Medical Conditions',
            icon: Icons.local_hospital,
            color: Colors.purpleAccent,
            content: _isEditing
                ? _buildTextField(
                    controller: _conditionsController,
                    hint: 'e.g., Diabetes, Asthma, Heart condition (comma separated)',
                    maxLines: 3,
                  )
                : _buildTagsList(
                    (_profile?['conditions'] as List?) ?? [],
                    Colors.purpleAccent,
                    'No conditions recorded',
                  ),
          ),
          
          // Additional Notes Section
          _buildSection(
            title: 'Additional Notes',
            icon: Icons.notes,
            color: Colors.greenAccent,
            content: _isEditing
                ? _buildTextField(
                    controller: _notesController,
                    hint: 'Any other important information for emergency responders...',
                    maxLines: 4,
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      _profile?['additional_notes']?.toString().isNotEmpty == true
                          ? _profile!['additional_notes']
                          : 'No additional notes',
                      style: TextStyle(
                        color: _profile?['additional_notes']?.toString().isNotEmpty == true
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        fontStyle: _profile?['additional_notes']?.toString().isNotEmpty == true
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ),
          ),
          
          if (_isEditing) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _populateControllers();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Privacy Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.white.withOpacity(0.5), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This information is securely stored and only shared with authorized medical personnel during emergencies.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoCard(String value, String description, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: value == 'Not specified' ? Colors.white.withOpacity(0.5) : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsList(List<dynamic> items, Color color, String emptyMessage) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          emptyMessage,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Chip(
          avatar: Icon(_getItemIcon(item.toString()), size: 16, color: color),
          label: Text(item.toString()),
          backgroundColor: color.withOpacity(0.2),
          side: BorderSide(color: color.withOpacity(0.3)),
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        );
      }).toList(),
    );
  }

  IconData _getItemIcon(String item) {
    final lower = item.toLowerCase();
    if (lower.contains('penicillin') || lower.contains('allerg')) return Icons.warning;
    if (lower.contains('insulin') || lower.contains('diabetes')) return Icons.water_drop;
    if (lower.contains('heart')) return Icons.favorite;
    if (lower.contains('asthma') || lower.contains('lung')) return Icons.air;
    return Icons.check_circle;
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.black.withOpacity(0.9),
          style: const TextStyle(color: Colors.white),
          hint: const Text('Select blood type', style: TextStyle(color: Colors.white54)),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          items: items.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isEditing = false);
    
    // Parse comma-separated values
    final allergies = _allergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final medications = _medicationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final conditions = _conditionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    try {
      await _apiService.updateMedicalProfile({
        'blood_type': _bloodTypeController.text,
        'allergies': allergies,
        'medications': medications,
        'conditions': conditions,
        'additional_notes': _notesController.text,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical profile updated successfully'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
