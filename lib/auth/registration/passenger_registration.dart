import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validator.dart';
import '../../core/utils/id_generator.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/audit_logger.dart';
import '../widgets/registration_stepper.dart';
import '../../core/auth/role_router.dart';

class PassengerRegistration extends StatefulWidget {
  const PassengerRegistration({super.key});

  @override
  State<PassengerRegistration> createState() => _PassengerRegistrationState();
}

class _PassengerRegistrationState extends State<PassengerRegistration> {
  int _currentStep = 0;
  bool _isLoading = false;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Form Data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  File? _profileImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: AppTheme.backgroundDark,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (!context.mounted) return;
                Navigator.pop(context, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (!context.mounted) return;
                Navigator.pop(context, image);
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey1.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey2.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Upload Profile Photo (optional – continue without photo if storage unavailable)
      String photoUrl = '';
      if (_profileImage != null) {
        try {
          photoUrl = await StorageService.uploadFile(
            file: _profileImage!,
            storagePath: 'users/${user.uid}/profile.jpg',
          );
        } catch (e) {
          debugPrint('Profile photo upload failed (non-fatal): $e');
        }
      }

      // 2. Generate Passenger ID
      final passengerId = IdGenerator.generate('PAS');

      // 3. Firestore Transaction
      final db = FirebaseFirestore.instance;
      await db.runTransaction((transaction) async {
        final userRef = db.collection('users').doc(user.uid);
        final passengerRef = db.collection('passengers').doc(passengerId);

        // Update User Doc
        transaction.update(userRef, {
          'displayName': _nameController.text.trim(),
          'roles': FieldValue.arrayUnion(['passenger']),
          'activeRole': 'passenger',
          'profileCompleted': true,
        });

        // Create Passenger Doc
        transaction.set(passengerRef, {
          'passengerId': passengerId,
          'userId': user.uid,
          'fullName': _nameController.text.trim(),
          'profilePhotoUrl': photoUrl,
          'homeAddress': _addressController.text.trim(),
          'emergencyContactName': _emergencyNameController.text.trim(),
          'emergencyContactPhone': _emergencyPhoneController.text.trim(),
          'nicNumber': _nicController.text.trim(),
          'walletBalance': 0,
          'accountStatus': 'active',
          'profileCompletion': 100,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      await AuditLogger.log(user.uid, 'REGISTER_PASSENGER');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => RoleRouter()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) {
      return _buildStep1();
    } else {
      return _buildStep2();
    }
  }

  Widget _buildStep1() {
    return RegistrationStepper(
      currentStep: 0,
      totalSteps: 2,
      title: 'Personal Profile',
      description: 'Tell us a bit about yourself to set up your account.',
      onBack: () => Navigator.pop(context),
      onContinue: _nextStep,
      content: Form(
        key: _formKey1,
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.purpleLight, width: 2),
                      image: _profileImage != null
                          ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                          : null,
                      color: AppTheme.surfaceGlass,
                    ),
                    child: _profileImage == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white24)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: FloatingActionButton.small(
                      onPressed: _pickImage,
                      backgroundColor: AppTheme.purplePrimary,
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Full Name', Icons.person_outline),
              validator: (val) => PayRouteValidator.requiredMinLength(val, 3, 'Full Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecoration('Home Address', Icons.home_outlined),
              validator: (val) => PayRouteValidator.required(val, 'Address'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return RegistrationStepper(
      currentStep: 1,
      totalSteps: 2,
      title: 'Security & ID',
      description: 'Important details for your safety and verification.',
      onBack: () => setState(() => _currentStep--),
      onContinue: _submit,
      isLoading: _isLoading,
      continueLabel: 'Complete Registration',
      content: Form(
        key: _formKey2,
        child: Column(
          children: [
            TextFormField(
              controller: _emergencyNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Emergency Contact Name', Icons.contact_emergency_outlined),
              validator: (val) => PayRouteValidator.required(val, 'Contact Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Emergency Contact Phone', Icons.phone_outlined),
              validator: (val) => PayRouteValidator.phone(val),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            const Text(
              'Identity Verification (Optional)',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nicController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('NIC Number', Icons.badge_outlined),
              validator: (val) => PayRouteValidator.nicOptional(val),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your NIC helps in faster verification or recovery.',
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: AppTheme.purpleLight),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.purpleLight),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _nicController.dispose();
    super.dispose();
  }
}
