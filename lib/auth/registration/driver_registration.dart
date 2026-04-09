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

class DriverRegistration extends StatefulWidget {
  const DriverRegistration({super.key});

  @override
  State<DriverRegistration> createState() => _DriverRegistrationState();
}

class _DriverRegistrationState extends State<DriverRegistration> {
  int _currentStep = 0;
  bool _isLoading = false;
  final _picker = ImagePicker();

  // Form Keys
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Step 1: Personal
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _nicController = TextEditingController();
  File? _profileImage;

  // Step 2: License
  final _licenseNoController = TextEditingController();
  DateTime? _licenseExpiry;
  File? _licenseFront;
  File? _licenseBack;

  // Step 3: Professional
  String _expYears = '1-3 Years';
  final List<String> _allSkills = ['Bus Operator', 'Hilly Routes', 'Night Driving', 'First Aid', 'Mechanic', 'Long Distance'];
  final List<String> _selectedSkills = [];
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Step 4: Verification
  File? _selfieImage;

  Future<void> _pickImage(String type) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case 'profile': _profileImage = File(pickedFile.path); break;
          case 'licenseFront': _licenseFront = File(pickedFile.path); break;
          case 'licenseBack': _licenseBack = File(pickedFile.path); break;
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
      valid = _formKey2.currentState!.validate() && _licenseExpiry != null && _licenseFront != null && _licenseBack != null;
      if (_licenseExpiry == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expiry date required')));
      if (_licenseFront == null || _licenseBack == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Both license photos required')));
    } else if (_currentStep == 2) {
      valid = _formKey3.currentState!.validate() && _selectedSkills.isNotEmpty;
      if (_selectedSkills.isEmpty) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one skill')));
    } else if (_currentStep == 3) {
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
      final driverId = IdGenerator.generate('DRV');
      final deviceInfo = await DeviceInfoUtil.getInfo();

      // 1. Upload all photos (non-fatal if storage unavailable)
      String profileUrl = '';
      String licenseFrontUrl = '';
      String licenseBackUrl = '';
      String selfieUrl = '';
      try {
        profileUrl = await StorageService.uploadFile(file: _profileImage!, storagePath: 'users/${user.uid}/profile.jpg');
      } catch (e) { debugPrint('Driver profile photo upload failed: $e'); }
      try {
        licenseFrontUrl = await StorageService.uploadFile(file: _licenseFront!, storagePath: 'drivers/$driverId/license_front.jpg');
      } catch (e) { debugPrint('License front upload failed: $e'); }
      try {
        licenseBackUrl = await StorageService.uploadFile(file: _licenseBack!, storagePath: 'drivers/$driverId/license_back.jpg');
      } catch (e) { debugPrint('License back upload failed: $e'); }
      try {
        selfieUrl = await StorageService.uploadFile(file: _selfieImage!, storagePath: 'drivers/$driverId/selfie.jpg');
      } catch (e) { debugPrint('Selfie upload failed: $e'); }

      // 2. Firestore Transaction
      final db = FirebaseFirestore.instance;
      await db.runTransaction((transaction) async {
        final userRef = db.collection('users').doc(user.uid);
        final driverRef = db.collection('drivers').doc(driverId);

        transaction.update(userRef, {
          'displayName': _nameController.text.trim(),
          'roles': FieldValue.arrayUnion(['driver']),
          'activeRole': 'driver',
          'profileCompleted': true,
        });

        transaction.set(driverRef, {
          'driverId': driverId,
          'userId': user.uid,
          'fullName': _nameController.text.trim(),
          'nicNumber': _nicController.text.trim(),
          'address': _addressController.text.trim(),
          'profilePhotoUrl': profileUrl,
          'licenseNumber': _licenseNoController.text.trim(),
          'licenseExpiry': Timestamp.fromDate(_licenseExpiry!),
          'licenseFrontUrl': licenseFrontUrl,
          'licenseBackUrl': licenseBackUrl,
          'experienceYears': _expYears,
          'skills': _selectedSkills,
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

      await AuditLogger.log(user.uid, 'REGISTER_DRIVER');

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
      case 3: return _buildStep4();
      default: return const SizedBox();
    }
  }

  // --- UI STEPS ---

  Widget _buildStep1() {
    return RegistrationStepper(
      currentStep: 0, totalSteps: 4, title: 'Personal Profile', description: 'Basic identification for your professional driver account.',
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
      currentStep: 1, totalSteps: 4, title: 'Driving License', description: 'Upload your valid driving license for verification.',
      onBack: () => setState(() => _currentStep--), onContinue: _nextStep,
      content: Form(key: _formKey2, child: Column(children: [
        _buildTextField(_licenseNoController, 'License Number', Icons.credit_card_outlined, validator: (v) => PayRouteValidator.licenseNumber(v)),
        const SizedBox(height: 16),
        _buildDatePicker('License Expiry Date', _licenseExpiry, (d) => setState(() => _licenseExpiry = d)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _buildImagePicker('licenseFront', _licenseFront, 'License Front')),
          const SizedBox(width: 16),
          Expanded(child: _buildImagePicker('licenseBack', _licenseBack, 'License Back')),
        ]),
      ])),
    );
  }

  Widget _buildStep3() {
    return RegistrationStepper(
      currentStep: 2, totalSteps: 4, title: 'Professional Info', description: 'Add your experience and driving skills.',
      onBack: () => setState(() => _currentStep--), onContinue: _nextStep,
      content: Form(key: _formKey3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Driving Experience', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _expYears, items: ['1-3 Years', '3-5 Years', '5-10 Years', '10+ Years'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _expYears = v!), dropdownColor: AppTheme.backgroundDark, style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('', Icons.history),
        ),
        const SizedBox(height: 24),
        const Text('Skills & Expertise', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: _allSkills.map((s) => FilterChip(
          label: Text(s), selected: _selectedSkills.contains(s), onSelected: (v) => setState(() => v ? _selectedSkills.add(s) : _selectedSkills.remove(s)),
          selectedColor: AppTheme.purplePrimary, backgroundColor: AppTheme.surfaceGlass, labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        )).toList()),
        const SizedBox(height: 24),
        _buildTextField(_emergencyNameController, 'Emergency Contact Name', Icons.contact_emergency_outlined, validator: (v) => PayRouteValidator.required(v, 'Contact Name')),
        const SizedBox(height: 16),
        _buildTextField(_emergencyPhoneController, 'Emergency Phone', Icons.phone_outlined, validator: (v) => PayRouteValidator.phone(v)),
      ])),
    );
  }

  Widget _buildStep4() {
    return RegistrationStepper(
      currentStep: 3, totalSteps: 4, title: 'Identity Verification', description: 'Take a selfie holding your NIC or License for final verification.',
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

  // --- HELPERS ---

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(controller: ctrl, style: const TextStyle(color: Colors.white), maxLines: maxLines, decoration: _inputDecoration(label, icon), validator: validator);
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onPicked) {
    return InkWell(onTap: () async {
      final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
      if (picked != null) onPicked(picked);
    }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: AppTheme.glassCard(), child: Row(children: [
      Icon(Icons.calendar_today, color: AppTheme.purpleLight), const SizedBox(width: 12),
      Text(date == null ? label : '${date.day}/${date.month}/${date.year}', style: TextStyle(color: date == null ? Colors.white60 : Colors.white)),
    ])));
  }

  Widget _buildImagePicker(String type, File? file, String label, {double height = 120}) {
    return InkWell(onTap: () => _pickImage(type), child: Container(width: double.infinity, height: height, decoration: BoxDecoration(color: AppTheme.surfaceGlass, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10), image: file != null ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null),
      child: file == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.white54, size: 32), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]) : null));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white60), prefixIcon: Icon(icon, color: AppTheme.purpleLight), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.purpleLight)));
  }

  @override void dispose() { _nameController.dispose(); _addressController.dispose(); _nicController.dispose(); _licenseNoController.dispose(); _emergencyNameController.dispose(); _emergencyPhoneController.dispose(); super.dispose(); }
}
