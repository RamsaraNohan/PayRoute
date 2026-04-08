import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RegistrationStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String description;
  final Widget content;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final bool isLoading;
  final String continueLabel;

  const RegistrationStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.description,
    required this.content,
    required this.onContinue,
    required this.onBack,
    this.isLoading = false,
    this.continueLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBack,
                    ),
                    const Spacer(),
                    // Step progress dots
                    Row(
                      children: List.generate(totalSteps, (index) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < currentStep
                                ? AppTheme.purpleLight
                                : (index == currentStep
                                    ? Colors.white
                                    : Colors.white24),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Step ${currentStep + 1} of $totalSteps',
                        style: const TextStyle(color: AppTheme.purpleLight, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      content,
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom bar
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ElevatedButton(
                        onPressed: onContinue,
                        style: AppTheme.primaryButton(),
                        child: Text(continueLabel, style: const TextStyle(fontSize: 18)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
