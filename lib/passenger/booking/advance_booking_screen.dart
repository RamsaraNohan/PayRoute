import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/passenger_provider.dart';

class AdvanceBookingScreen extends ConsumerStatefulWidget {
  const AdvanceBookingScreen({super.key});

  @override
  ConsumerState<AdvanceBookingScreen> createState() => _AdvanceBookingScreenState();
}

class _AdvanceBookingScreenState extends ConsumerState<AdvanceBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedRoute = 'Route 138 – Kottawa to Pettah';
  String _selectedSeatPref = 'Any';
  int _companions = 0;
  bool _isSubmitting = false;

  final List<String> _routes = [
    'Route 138 – Kottawa to Pettah',
    'Route 120 – Horana to Pettah',
    'Route 240 – Gampaha to Pettah',
    'Route 187 – Kaduwela to Pettah',
  ];

  final List<String> _seatPrefs = ['Any', 'Window Seat', 'Aisle Seat', 'Front Row', 'Back Row'];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.purpleLight),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.purpleLight),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Use the real passenger doc ID (PAS-XXXX), not the Auth UID
      final passenger = ref.read(passengerStreamProvider).value;
      if (passenger == null) throw Exception('Passenger profile not found.');
      final dateTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );

      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': passenger.passengerId,
        'route': _selectedRoute,
        'scheduledTime': dateTime.toIso8601String(),
        'seatPreference': _selectedSeatPref,
        'companionCount': _companions,
        'status': 'CONFIRMED',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
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
    final dateFormat = DateFormat('EEE, MMM d yyyy');

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Advance Booking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Book your seat in advance and skip the queue.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Route selection
              _sectionLabel('Select Route'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: AppTheme.glassCard(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRoute,
                    dropdownColor: const Color(0xFF1A1A2E),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setState(() => _selectedRoute = v!),
                    items: _routes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date + Time row
              _sectionLabel('Journey Date & Time'),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassCard(),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.purpleLight, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDate != null ? dateFormat.format(_selectedDate!) : 'Pick date',
                              style: TextStyle(color: _selectedDate != null ? Colors.white : Colors.white38),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassCard(),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: AppTheme.purpleLight, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime != null ? _selectedTime!.format(context) : 'Pick time',
                              style: TextStyle(color: _selectedTime != null ? Colors.white : Colors.white38),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Seat preference
              _sectionLabel('Seat Preference'),
              Wrap(
                spacing: 8,
                children: _seatPrefs.map((pref) {
                  final selected = _selectedSeatPref == pref;
                  return ChoiceChip(
                    label: Text(pref),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedSeatPref = pref),
                    selectedColor: AppTheme.purpleLight.withValues(alpha: 0.3),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    labelStyle: TextStyle(color: selected ? AppTheme.purpleLight : Colors.white60),
                    side: BorderSide(color: selected ? AppTheme.purpleLight : Colors.white12),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Companions
              _sectionLabel('Companions'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppTheme.glassCard(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Additional passengers', style: TextStyle(color: Colors.white70)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.purpleLight),
                          onPressed: _companions > 0 ? () => setState(() => _companions--) : null,
                        ),
                        Text('$_companions', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppTheme.purpleLight),
                          onPressed: _companions < 5 ? () => setState(() => _companions++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitBooking,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSubmitting ? 'Booking...' : 'Confirm Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.purpleLight,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
