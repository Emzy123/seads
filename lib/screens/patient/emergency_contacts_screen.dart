import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final contacts = await _apiService.getEmergencyContacts();
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _launchPhone(String? number) async {
    if (number == null || number.trim().isEmpty) return;
    final digits = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$digits');
    if (!await launchUrl(uri)) {
      throw Exception('Could not start call');
    }
  }

  Future<void> _launchSms(String? number) async {
    if (number == null || number.trim().isEmpty) return;
    final digits = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('sms:$digits');
    if (!await launchUrl(uri)) {
      throw Exception('Could not open messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(userRole: 'patient', activeRoute: '/contacts', accentColor: Colors.blueAccent),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: const Text('EMERGENCY CONTACTS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddContactDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: SpinKitPulse(color: Colors.blueAccent, size: 60))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('Could not load contacts', style: AppTheme.headingSmall),
            const SizedBox(height: 8),
            Text(_error!, style: AppTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchContacts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Quick Actions Header
        Container(
          margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
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
                    child: const Icon(Icons.emergency, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Emergency',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Call emergency services immediately',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.call,
                      label: 'Police',
                      number: '911',
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.local_fire_department,
                      label: 'Fire Dept',
                      number: '911',
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.local_hospital,
                      label: 'Hospital',
                      number: '911',
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Personal Contacts Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Your Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddContactDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        
        // Contacts List
        Expanded(
          child: _contacts.isEmpty ? _buildEmptyState() : _buildContactsList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String number,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _showCallDialog(label, number),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text(
            'No Emergency Contacts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Add family members or trusted contacts',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddContactDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Your First Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(dynamic contact) {
    final relationship = contact['relationship'] ?? 'Contact';
    final isPrimary = contact['is_primary'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPrimary ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isPrimary ? Colors.redAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                  child: Text(
                    (contact['name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? Colors.redAccent : Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            contact['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isPrimary) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'PRIMARY',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        relationship,
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact['phone'] ?? 'No phone number',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: Colors.black.withOpacity(0.9),
                  onSelected: (value) {
                    switch (value) {
                      case 'call':
                        _showCallDialog(contact['name'], contact['phone']);
                        break;
                      case 'edit':
                        _showEditContactDialog(contact);
                        break;
                      case 'delete':
                        _showDeleteConfirm(contact);
                        break;
                      case 'primary':
                        _setAsPrimary(contact);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'call', child: Row(children: [Icon(Icons.call, size: 20), SizedBox(width: 12), Text('Call')])),
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Edit')])),
                    if (!isPrimary)
                      const PopupMenuItem(value: 'primary', child: Row(children: [Icon(Icons.star, size: 20), SizedBox(width: 12), Text('Set as Primary')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.redAccent))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCallDialog(contact['name'], contact['phone']),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: const BorderSide(color: Colors.greenAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchSms(contact['phone']?.toString()),
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog() {
    // Implementation for adding contact
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildContactForm(),
    );
  }

  void _showEditContactDialog(dynamic contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildContactForm(contact: contact),
    );
  }

  Widget _buildContactForm({dynamic contact}) {
    return _ContactFormSheet(
      contact: contact,
      apiService: _apiService,
      onSaved: () {
        Navigator.pop(context);
        _fetchContacts();
      },
    );
  }

  void _showCallDialog(String name, String? number) {
    if (number == null || number.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Call $name?', style: const TextStyle(color: Colors.white)),
        content: Text(number, style: const TextStyle(fontSize: 18, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _launchPhone(number);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Call failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.call),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(dynamic contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Contact?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove ${contact['name']}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final id = contact['id']?.toString();
              if (id == null) return;
              try {
                await _apiService.deleteEmergencyContact(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact removed')),
                  );
                  _fetchContacts();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppTheme.criticalRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _setAsPrimary(dynamic contact) async {
    final id = contact['id']?.toString();
    if (id == null) return;
    try {
      await _apiService.updateEmergencyContact(
        contactId: id,
        name: contact['name']?.toString() ?? '',
        phone: contact['phone']?.toString() ?? '',
        relationship: contact['relationship']?.toString() ?? 'Contact',
        isPrimary: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primary contact updated')),
        );
        _fetchContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: AppTheme.criticalRed),
        );
      }
    }
  }
}

class _ContactFormSheet extends StatefulWidget {
  final dynamic contact;
  final ApiService apiService;
  final VoidCallback onSaved;

  const _ContactFormSheet({
    required this.contact,
    required this.apiService,
    required this.onSaved,
  });

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationshipController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _nameController = TextEditingController(text: c?['name']?.toString() ?? '');
    _phoneController = TextEditingController(text: c?['phone']?.toString() ?? '');
    _relationshipController = TextEditingController(text: c?['relationship']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final relationship = _relationshipController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone are required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final isEditing = widget.contact != null;
      if (isEditing) {
        await widget.apiService.updateEmergencyContact(
          contactId: widget.contact['id'].toString(),
          name: name,
          phone: phone,
          relationship: relationship.isEmpty ? 'Contact' : relationship,
        );
      } else {
        await widget.apiService.addEmergencyContact(
          name: name,
          phone: phone,
          relationship: relationship.isEmpty ? 'Contact' : relationship,
        );
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: AppTheme.criticalRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;
    return ClipRRect(
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
            color: Colors.black.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: Colors.blueAccent)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 24),
              Text(
                isEditing ? 'Edit Contact' : 'Add Emergency Contact',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'This contact will be notified during emergencies',
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              _buildTextField('Full Name', _nameController, Icons.person),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Relationship', _relationshipController, Icons.people),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Add Contact'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}
