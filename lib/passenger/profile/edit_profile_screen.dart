import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validator.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/audit_logger.dart';
import '../../providers/passenger_provider.dart';

/// Allows a passenger to edit their mutable profile fields.
///
/// Fraud controls:
///   - NIC is locked once set (cannot be changed after initial registration).
///   - Phone number is read-only (tied to Firebase Auth, cannot be changed here).
///   - Wallet balance is never editable from the client.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  File? _newProfileImage;
  bool _isLoading = false;
  String _existingPhotoUrl = '';
  String _passengerId = '';
  bool _nicAlreadySet = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  void _loadCurrentValues() {
    final passenger = ref.read(passengerStreamProvider).value;
    if (passenger != null) {
      _nameController.text = passenger.fullName;
      _addressController.text = passenger.homeAddress;
      _emergencyNameController.text = passenger.emergencyContactName;
      _emergencyPhoneController.text = passenger.emergencyContactPhone;
      _existingPhotoUrl = passenger.profilePhotoUrl;
      _passengerId = passenger.passengerId;
      _nicAlreadySet = passenger.nicNumber.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: AppTheme.backgroundDark,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () async => Navigator.pop(ctx, await picker.pickImage(source: ImageSource.camera, imageQuality: 70)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async => Navigator.pop(ctx, await picker.pickImage(source: ImageSource.gallery, imageQuality: 70)),
            ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _newProfileImage = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      String photoUrl = _existingPhotoUrl;
      if (_newProfileImage != null) {
        photoUrl = await StorageService.uploadFile(
          file: _newProfileImage!,
          storagePath: 'users/$uid/profile.jpg',
        );
      }

      // Only update the fields that passengers are allowed to change.
      // Wallet balance, NIC (if already set), role, and userId are never updated here.
      final updates = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'homeAddress': _addressController.text.trim(),
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactPhone': _emergencyPhoneController.text.trim(),
        'profilePhotoUrl': photoUrl,
      };

      await FirebaseFirestore.instance.collection('passengers').doc(_passengerId).update(updates);

      // Also keep the users doc display name in sync
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': _nameController.text.trim(),
      });

      await AuditLogger.log(uid, 'UPDATE_PROFILE');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('SAVE', style: TextStyle(color: AppTheme.purpleLight, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppTheme.purpleLight.withValues(alpha: 0.3),
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!) as ImageProvider
                            : (_existingPhotoUrl.isNotEmpty ? NetworkImage(_existingPhotoUrl) : null),
                        child: (_newProfileImage == null && _existingPhotoUrl.isEmpty)
                            ? const Icon(Icons.person, size: 52, color: Colors.white54)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.purpleLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.backgroundDark, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _sectionLabel('Basic Information'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Full Name', Icons.person_outline),
                validator: (v) => PayRouteValidator.requiredMinLength(v, 3, 'Full Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDecoration('Home Address', Icons.home_outlined),
                validator: (v) => PayRouteValidator.required(v, 'Address'),
              ),
              const SizedBox(height: 28),

              _sectionLabel('Emergency Contact'),
              TextFormField(
                controller: _emergencyNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Emergency Contact Name', Icons.contact_emergency_outlined),
                validator: (v) => PayRouteValidator.required(v, 'Contact Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Emergency Contact Phone', Icons.phone_outlined),
                validator: (v) => PayRouteValidator.phone(v),
              ),
              const SizedBox(height: 28),

              // Locked fields (read-only, shown for transparency)
              _sectionLabel('Verified Identity (Read-Only)'),
              if (_nicAlreadySet)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: AppTheme.glassCard(),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.white38, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NIC Number', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            SizedBox(height: 2),
                            Text('NIC on file — cannot be changed', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCard(),
                child: Row(
                  children: [
                    const Icon(Icons.phone_locked_outlined, color: Colors.white38, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Phone Number', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          FirebaseAuth.instance.currentUser?.phoneNumber ?? 'Verified',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.lock_outline, color: Colors.white24, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Phone and NIC cannot be changed to prevent fraudulent account takeovers.',
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: AppTheme.primaryButton(),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
      );

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: AppTheme.purpleLight),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.purpleLight)),
      );
}
