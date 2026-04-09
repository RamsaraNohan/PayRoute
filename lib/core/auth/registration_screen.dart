import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../services/firestore_service.dart';
import 'role_router.dart';

class RegistrationScreen extends StatefulWidget {
  final String phoneNumber;
  const RegistrationScreen({super.key, required this.phoneNumber});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehicleController = TextEditingController();
  
  String _selectedRole = 'passenger';
  bool _isSubmitting = false;

  final List<String> _roles = ['passenger', 'driver', 'conductor', 'owner'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final userModel = UserModel(
        userId: user.uid,
        displayName: _nameController.text.trim(),
        phonePrimary: widget.phoneNumber,
        roles: [_selectedRole],
        activeRole: _selectedRole,
        profileCompleted: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestoreService.createUser(userModel);
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleRouter()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Tell us more about yourself', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 32),
              
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('I am a...'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: AppTheme.glassCard(),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          dropdownColor: AppTheme.backgroundDark,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                          onChanged: (val) => setState(() => _selectedRole = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                    _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboard: TextInputType.emailAddress),
                    _buildTextField(_addressController, 'Home Address', Icons.home_outlined),
                    
                    if (_selectedRole == 'driver' || _selectedRole == 'conductor') ...[
                      const Divider(color: Colors.white24, height: 40),
                      _buildLabel('Staff Information'),
                      _buildTextField(_licenseController, 'Driving License Number', Icons.badge_outlined),
                      _buildTextField(_vehicleController, 'Assigned Vehicle Number', Icons.directions_bus_outlined),
                    ],
                    
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: AppTheme.primaryButton(),
                      child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Complete Registration', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.glassCard(),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: AppTheme.purpleLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
}
