import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class ComplaintScreen extends StatefulWidget {
  final String? tripId;
  final String? busId;
  const ComplaintScreen({super.key, this.tripId, this.busId});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  String _selectedCategory = 'Driver Behaviour';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Driver Behaviour',
    'Overcrowding',
    'Overcharging',
    'Bus Condition',
    'Delay',
    'Other',
  ];

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('complaints').add({
        'passengerId': uid,
        'tripId': widget.tripId,
        'busId': widget.busId,
        'category': _selectedCategory,
        'content': _contentController.text.trim(),
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted. We\'ll review it shortly.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('File a Complaint'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'We take every complaint seriously. Your report helps us improve the service.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Category Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: AppTheme.glassCard(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: AppTheme.backgroundDark,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Trip ref chips
                if (widget.busId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: AppTheme.glassCard(),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_bus, color: AppTheme.purpleLight, size: 18),
                        const SizedBox(width: 8),
                        Text('Bus: ${widget.busId}  •  Trip: ${widget.tripId ?? 'N/A'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                if (widget.busId != null) const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _contentController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Please provide at least 10 characters.' : null,
                  decoration: InputDecoration(
                    hintText: 'Describe what happened...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.purpleLight),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Complaint'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
