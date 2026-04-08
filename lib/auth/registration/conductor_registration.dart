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
import '../../core/utils/device_info_util.dart';
import '../widgets/registration_stepper.dart';
import '../../core/auth/role_router.dart';

class ConductorRegistration extends StatefulWidget {
  const ConductorRegistration({super.key});

  @override
  State<ConductorRegistration> createState() => _ConductorRegistrationState();
}

class _ConductorRegistrationState extends State<ConductorRegistration> {
  int _currentStep = 0;
  bool _isLoading = false;
  final _picker = ImagePicker();

  // Form Keys
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1: Personal
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _nicController = TextEditingController();
  File? _profileImage;

  // Step 2: Professional
  String _expYears = '1-3 Years';
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _licenseNoController = TextEditingController(); // Optional for conductors

  // Step 3: Verification
  File? _selfieImage;

  Future<void> _pickImage(String type) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case 'profile': _profileImage = File(pickedFile.path); break;
          case 'selfie': _selfieImage = File(pickedFile.path); break;
        }
      });
    }
  }

  void _nextStep() {
    bool valid = false;
    if (_currentStep == 0) {
      valid = _formKey1.currentState!.validate() && _profileImage != null;
      if (_profileImage == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo required')));
    } else if (_currentStep == 1) {
      valid = _formKey2.currentState!.validate();
    } else if (_currentStep == 2) {
      if (_selfieImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selfie required for verification')));
        return;
      }
      _submit();
      return;
    }

    if (valid) setState(() => _currentStep++);
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final conductorId = IdGenerator.generate('CON');
      final deviceInfo = await DeviceInfoUtil.getInfo();

      // 1. Upload photos
      final profileUrl = await StorageService.uploadFile(file: _profileImage!, storagePath: 'users/${user.uid}/profile.jpg');
      final selfieUrl = await StorageService.uploadFile(file: _selfieImage!, storagePath: 'conductors/$conductorId/selfie.jpg');

      // 2. Firestore Transaction
      final db = FirebaseFirestore.instance;
      await db.runTransaction((transaction) async {
        final userRef = db.collection('users').doc(user.uid);
        final conductorRef = db.collection('conductors').doc(conductorId);

        transaction.update(userRef, {
          'displayName': _nameController.text.trim(),
          'roles': FieldValue.arrayUnion(['conductor']),
          'activeRole': 'conductor',
          'profileCompleted': true,
        });

        transaction.set(conductorRef, {
          'conductorId': conductorId,
          'userId': user.uid,
          'fullName': _nameController.text.trim(),
          'nicNumber': _nicController.text.trim(),
          'address': _addressController.text.trim(),
          'profilePhotoUrl': profileUrl,
          'ticketExperience': _expYears,
          'licenseNumber': _licenseNoController.text.trim(),
          'emergencyContactName': _emergencyNameController.text.trim(),
          'emergencyContactPhone': _emergencyPhoneController.text.trim(),
          'selfiePhotoUrl': selfieUrl,
          'verificationStatus': 'pending',
          'verificationNote': '',
          'verificationLevel': 1,
          'accountStatus': 'active',
          'deviceId': deviceInfo['deviceId'] ?? 'unknown',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      await AuditLogger.log(user.uid, 'REGISTER_CONDUCTOR');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => RoleRouter()), (route) => false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      default: return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return RegistrationStepper(
      currentStep: 0, totalSteps: 3, title: 'Personal Profile', description: 'Basic identification for your professional conductor account.',
      onBack: () => Navigator.pop(context), onContinue: _nextStep,
      content: Form(key: _formKey1, child: Column(children: [
        _buildImagePicker('profile', _profileImage, 'Profile Photo'),
        const SizedBox(height: 24),
        _buildTextField(_nameController, 'Full Name', Icons.person_outline, validator: (v) => PayRouteValidator.requiredMinLength(v, 3, 'Full Name')),
        const SizedBox(height: 16),
        _buildTextField(_nicController, 'NIC Number', Icons.badge_outlined, validator: (v) => PayRouteValidator.nic(v)),
        const SizedBox(height: 16),
        _buildTextField(_addressController, 'Home Address', Icons.home_outlined, maxLines: 2, validator: (v) => PayRouteValidator.required(v, 'Address')),
      ])),
    );
  }

  Widget _buildStep2() {
    return RegistrationStepper(
      currentStep: 1, totalSteps: 3, title: 'Professional Info', description: 'Add your ticketeing experience and emergency contact.',
      onBack: () => setState(() => _currentStep--), onContinue: _nextStep,
      content: Form(key: _formKey2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ticketing Experience', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _expYears, items: ['1-3 Years', '3-5 Years', '5-10 Years', '10+ Years'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _expYears = v!), dropdownColor: AppTheme.backgroundDark, style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('', Icons.history),
        ),
        const SizedBox(height: 24),
        _buildTextField(_licenseNoController, 'National Conductor ID (Optional)', Icons.credit_card_outlined),
        const SizedBox(height: 24),
        _buildTextField(_emergencyNameController, 'Emergency Contact Name', Icons.contact_emergency_outlined, validator: (v) => PayRouteValidator.required(v, 'Contact Name')),
        const SizedBox(height: 16),
        _buildTextField(_emergencyPhoneController, 'Emergency Phone', Icons.phone_outlined, validator: (v) => PayRouteValidator.phone(v)),
      ])),
    );
  }

  Widget _buildStep4() { // Step 3 build
    return RegistrationStepper(
      currentStep: 2, totalSteps: 3, title: 'Identity Verification', description: 'Take a selfie holding your NIC for final verification.',
      onBack: () => setState(() => _currentStep--), onContinue: _nextStep, isLoading: _isLoading, continueLabel: 'Submit for Review',
      content: Column(children: [
        _buildImagePicker('selfie', _selfieImage, 'Take Selfie Verification', height: 200),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(16), decoration: AppTheme.glassCard(), child: const Row(children: [
          Icon(Icons.info_outline, color: AppTheme.purpleLight), SizedBox(width: 12),
          Expanded(child: Text('Ensure your face and ID are clearly visible in the photo.', style: TextStyle(color: Colors.white70, fontSize: 13))),
        ])),
      ]),
    );
  }

  // Reuse helper methods from DriverRegistration or move to a mixin if needed.
  // For now local is fine.
  Widget _buildStep3() => _buildStep4(); // Fix naming

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(controller: ctrl, style: const TextStyle(color: Colors.white), maxLines: maxLines, decoration: _inputDecoration(label, icon), validator: validator);
  }

  Widget _buildImagePicker(String type, File? file, String label, {double height = 120}) {
    return InkWell(onTap: () => _pickImage(type), child: Container(width: double.infinity, height: height, decoration: BoxDecoration(color: AppTheme.surfaceGlass, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10), image: file != null ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null),
      child: file == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.white54, size: 32), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]) : null));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white60), prefixIcon: Icon(icon, color: AppTheme.purpleLight), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.purpleLight)));
  }

  @override void dispose() { _nameController.dispose(); _addressController.dispose(); _nicController.dispose(); _emergencyNameController.dispose(); _emergencyPhoneController.dispose(); _licenseNoController.dispose(); super.dispose(); }
}
