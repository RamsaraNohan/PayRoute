import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import 'role_router.dart';

class OTPEntryScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPEntryScreen({super.key, required this.verificationId, required this.phoneNumber});

  @override
  ConsumerState<OTPEntryScreen> createState() => _OTPEntryScreenState();
}

class _OTPEntryScreenState extends ConsumerState<OTPEntryScreen> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    startTimer();
  }

  void startTimer() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _verifyOTP() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithOTP(_verificationId, otp);

      ref.read(onboardingStateProvider.notifier).complete();
      setState(() => _isLoading = false);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => RoleRouter()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
    }
  }

  Widget _buildDigitBox(int index) {
    return Container(
      width: 45,
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: AppTheme.glassCard(),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else if (value.isNotEmpty && index == 5) {
              _focusNodes[index].unfocus();
              _verifyOTP(); // auto submit
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientBackground(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Enter the 6-digit code', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Sent to +94 ${widget.phoneNumber}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) => _buildDigitBox(index)),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
                    onPressed: _verifyOTP,
                    style: AppTheme.primaryButton(),
                    child: const Text('Verify', style: TextStyle(fontSize: 18)),
                  ),
            const SizedBox(height: 24),
            _countdown > 0
                ? Text('Resend in 0:${_countdown.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white54))
                : TextButton(
                    onPressed: _isLoading ? null : () async {
                      startTimer();
                      setState(() => _isLoading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _authService.verifyPhoneNumber(
                          phoneNumber: '+94${widget.phoneNumber}',
                          codeSent: (newVerificationId, resendToken) {
                            if (mounted) {
                              setState(() {
                                _verificationId = newVerificationId;
                                _isLoading = false;
                              });
                              messenger.showSnackBar(
                                const SnackBar(content: Text('OTP resent successfully')),
                              );
                            }
                          },
                          verificationFailed: (e) {
                            if (mounted) {
                              setState(() => _isLoading = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Resend failed: ${e.message}')),
                              );
                            }
                          },
                        );
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLoading = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Resend error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Resend OTP', style: TextStyle(color: AppTheme.purpleLight)),
                  )
          ],
        ),
      ),
    );
  }
}
