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

class OwnerRegistration extends StatefulWidget {
  const OwnerRegistration({super.key});

  @override
  State<OwnerRegistration> createState() => _OwnerRegistrationState();
}

class BusRegData {
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  File? frontPhoto;
  File? rmvPhoto;
  File? insurancePhoto;

  void dispose() {
    regNoController.dispose();
    capacityController.dispose();
    routeController.dispose();
  }
}

class _OwnerRegistrationState extends State<OwnerRegistration> {
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

  // Step 2: Business
  final _businessNameController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  int _busCount = 1;

  // Step 3: Fleet (Dynamic)
  final List<BusRegData> _fleet = [BusRegData()];
  final PageController _busPageController = PageController();
  int _currentBusIndex = 0;

  // Step 4: Verification
  File? _selfieImage;

  Future<void> _pickImage(String type, {int? busIndex, String? subType}) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (type == 'profile') { _profileImage = File(pickedFile.path); }
        else if (type == 'selfie') { _selfieImage = File(pickedFile.path); }
        else if (type == 'bus' && busIndex != null) {
          if (subType == 'front') _fleet[busIndex].frontPhoto = File(pickedFile.path);
          if (subType == 'rmv') _fleet[busIndex].rmvPhoto = File(pickedFile.path);
          if (subType == 'ins') _fleet[busIndex].insurancePhoto = File(pickedFile.path);
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
      // Adjust fleet list size
      while (_fleet.length < _busCount) { _fleet.add(BusRegData()); }
      while (_fleet.length > _busCount) { 
        var data = _fleet.removeLast();
        data.dispose();
      }
    } else if (_currentStep == 2) {
      // Validate current bus page before proceeding or finishing loop
      final currentBus = _fleet[_currentBusIndex];
      if (currentBus.regNoController.text.isEmpty || currentBus.capacityController.text.isEmpty || 
          currentBus.frontPhoto == null || currentBus.rmvPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete all required bus details & photos')));
        return;
      }
      
      if (_currentBusIndex < _fleet.length - 1) {
        setState(() => _currentBusIndex++);
        _busPageController.animateToPage(_currentBusIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        return;
      }
      valid = true;
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
      final ownerId = IdGenerator.generate('OWN');
      final deviceInfo = await DeviceInfoUtil.getInfo();

      // 1. Upload Baseline Photos (non-fatal if storage unavailable)
      String profileUrl = '';
      String selfieUrl = '';
      try {
        profileUrl = await StorageService.uploadFile(file: _profileImage!, storagePath: 'users/${user.uid}/profile.jpg');
      } catch (e) { debugPrint('Owner profile photo upload failed: $e'); }
      try {
        selfieUrl = await StorageService.uploadFile(file: _selfieImage!, storagePath: 'owners/$ownerId/selfie.jpg');
      } catch (e) { debugPrint('Owner selfie upload failed: $e'); }

      // 2. Prep Firestore Docs
      final db = FirebaseFirestore.instance;
      final busDocs = <Map<String, dynamic>>[];
      
      for (int i = 0; i < _fleet.length; i++) {
        final b = _fleet[i];
        final busId = IdGenerator.generate('BUS');
        
        // Upload Bus Photos (non-fatal if storage unavailable)
        String fUrl = '';
        String rUrl = '';
        String iUrl = '';
        try {
          fUrl = await StorageService.uploadFile(file: b.frontPhoto!, storagePath: 'buses/$busId/front.jpg');
        } catch (e) { debugPrint('Bus front photo upload failed: $e'); }
        try {
          rUrl = await StorageService.uploadFile(file: b.rmvPhoto!, storagePath: 'buses/$busId/rmv.jpg');
        } catch (e) { debugPrint('Bus RMV photo upload failed: $e'); }
        if (b.insurancePhoto != null) {
          try {
            iUrl = await StorageService.uploadFile(file: b.insurancePhoto!, storagePath: 'buses/$busId/insurance.jpg');
          } catch (e) { debugPrint('Bus insurance photo upload failed: $e'); }
        }

        busDocs.add({
          'busId': busId,
          'registrationNumber': b.regNoController.text.trim().toUpperCase(),
          'ownerId': ownerId,        // OWN-XXXXXXXX — used by TripService wallet lookup
          'ownerUserId': user.uid,   // Firebase Auth UID — used by OwnerDashboard queries
          'capacity': int.tryParse(b.capacityController.text) ?? 54,
          'routeId': b.routeController.text.trim(),
          'status': 'offline',
          'todayIncomeCents': 0,
          'frontPhotoUrl': fUrl,
          'rmvBookUrl': rUrl,
          'insuranceUrl': iUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'verificationStatus': 'pending', // requirement: all data must be approved
        });
      }

      // 3. Batch Write
      final batch = db.batch();
      final userRef = db.collection('users').doc(user.uid);
      final ownerRef = db.collection('owners').doc(ownerId);
      
      batch.update(userRef, {
        'displayName': _nameController.text.trim(),
        'roles': FieldValue.arrayUnion(['owner']),
        'activeRole': 'owner',
        'profileCompleted': true,
      });

      batch.set(ownerRef, {
        'ownerId': ownerId,
        'userId': user.uid,
        'fullName': _nameController.text.trim(),
        'nicNumber': _nicController.text.trim(),
        'address': _addressController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'phoneSecondary': _secondaryPhoneController.text.trim(),
        'profilePhotoUrl': profileUrl,
        'selfiePhotoUrl': selfieUrl,
        'verificationStatus': 'pending',
        'totalBuses': _fleet.length,
        'accountStatus': 'active',
        'deviceId': deviceInfo['deviceId'] ?? 'unknown',
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (var bus in busDocs) {
        batch.set(db.collection('buses').doc(bus['busId']), bus);
      }

      await batch.commit();
      await AuditLogger.log(user.uid, 'REGISTER_OWNER');

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

  Widget _buildStep1() {
    return RegistrationStepper(
      currentStep: 0, totalSteps: 4, title: 'Owner Profile', description: 'Personal identification for fleet management.',
      onBack: () => Navigator.pop(context), onContinue: _nextStep,
      content: Form(key: _formKey1, child: Column(children: [
        _buildImagePicker('profile', _profileImage, 'Profile Photo'),
        const SizedBox(height: 24),
        _buildTextField(_nameController, 'Full Name', Icons.person_outline, validator: (v) => PayRouteValidator.required(v, 'Full Name')),
        const SizedBox(height: 16),
        _buildTextField(_nicController, 'NIC Number', Icons.badge_outlined, validator: (v) => PayRouteValidator.nic(v)),
        const SizedBox(height: 16),
        _buildTextField(_addressController, 'Home Address', Icons.home_outlined, maxLines: 2, validator: (v) => PayRouteValidator.required(v, 'Address')),
      ])),
    );
  }

  Widget _buildStep2() {
    return RegistrationStepper(
      currentStep: 1, totalSteps: 4, title: 'Business Info', description: 'Tell us about your transport business.',
      onBack: () => setState(() => _currentStep--), onContinue: _nextStep,
      content: Form(key: _formKey2, child: Column(children: [
        _buildTextField(_businessNameController, 'Business / Personal Trading Name', Icons.business_outlined),
        const SizedBox(height: 16),
        _buildTextField(_secondaryPhoneController, 'Secondary Contact Phone', Icons.phone_android, validator: (v) => v!.isNotEmpty ? PayRouteValidator.phone(v) : null),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(16), decoration: AppTheme.glassCard(), child: Column(children: [
          const Text('Total Buses to Register', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.remove, color: Colors.white), onPressed: () => setState(() => _busCount = _busCount > 1 ? _busCount - 1 : 1)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Text('$_busCount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () => setState(() => _busCount++)),
          ]),
        ])),
      ])),
    );
  }

  Widget _buildStep3() {
    return RegistrationStepper(
      currentStep: 2, totalSteps: 4, title: 'Fleet Details', description: 'Enter details for Bus ${_currentBusIndex + 1} of $_busCount.',
      onBack: () {
        if (_currentBusIndex > 0) {
          setState(() => _currentBusIndex--);
          _busPageController.animateToPage(_currentBusIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        } else {
          setState(() => _currentStep--);
        }
      },
      onContinue: _nextStep, 
      continueLabel: _currentBusIndex < _fleet.length - 1 ? 'Next Bus' : 'Next Step',
      content: SizedBox(height: 500, child: PageView.builder(
        controller: _busPageController, physics: const NeverScrollableScrollPhysics(), itemCount: _fleet.length,
        itemBuilder: (context, index) {
          final b = _fleet[index];
          return SingleChildScrollView(child: Column(children: [
            _buildTextField(b.regNoController, 'Vehicle Registration No', Icons.commute, validator: (v) => PayRouteValidator.vehicleNumber(v)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildTextField(b.capacityController, 'Capacity', Icons.groups, keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(b.routeController, 'Route (e.g. 138)', Icons.route)),
            ]),
            const SizedBox(height: 24),
            const Text('Required Documents', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildImagePicker('bus', b.frontPhoto, 'Bus Exterior Front', busIndex: index, subType: 'front'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildImagePicker('bus', b.rmvPhoto, 'RMV Log Book', busIndex: index, subType: 'rmv')),
              const SizedBox(width: 12),
              Expanded(child: _buildImagePicker('bus', b.insurancePhoto, 'Insurance Card', busIndex: index, subType: 'ins')),
            ]),
          ]));
        },
      )),
    );
  }

  Widget _buildStep4() {
    return RegistrationStepper(
      currentStep: 3, totalSteps: 4, title: 'Owner Verification', description: 'Final identity check to access the owner panel.',
      onBack: () => setState(() => _currentStep--), onContinue: _nextStep, isLoading: _isLoading, continueLabel: 'Submit Registration',
      content: Column(children: [
        _buildImagePicker('selfie', _selfieImage, 'Take Identity Selfie', height: 200),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(16), decoration: AppTheme.glassCard(), child: const Row(children: [
          Icon(Icons.security, color: Colors.greenAccent), SizedBox(width: 12),
          Expanded(child: Text('Your data is encrypted and only used for professional verification.', style: TextStyle(color: Colors.white70, fontSize: 13))),
        ])),
      ]),
    );
  }

  // --- HELPERS (Synced with DriverRegistration style) ---
  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {String? Function(String?)? validator, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(controller: ctrl, style: const TextStyle(color: Colors.white), keyboardType: keyboardType, maxLines: maxLines, decoration: _inputDecoration(label, icon), validator: validator);
  }

  Widget _buildImagePicker(String type, File? file, String label, {double height = 110, int? busIndex, String? subType}) {
    return InkWell(onTap: () => _pickImage(type, busIndex: busIndex, subType: subType), child: Container(width: double.infinity, height: height, decoration: BoxDecoration(color: AppTheme.surfaceGlass, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10), image: file != null ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null),
      child: file == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.white54, size: 28), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))]) : null));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white60), prefixIcon: Icon(icon, color: AppTheme.purpleLight), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.purpleLight)));
  }

  @override void dispose() { _nameController.dispose(); _addressController.dispose(); _nicController.dispose(); _businessNameController.dispose(); _secondaryPhoneController.dispose(); for (var b in _fleet) { b.dispose(); } super.dispose(); }
}

extension ColorExt on BuildContext {
  Color get primaryColor => Theme.of(this).primaryColor;
}
