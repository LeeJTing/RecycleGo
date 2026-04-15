import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/utils/async_task_runner.dart';
import 'package:recycle_go/services/otp_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const OtpScreen({
    super.key,
    required this.email,
    required this.onVerified
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpCtrl = TextEditingController();
  final OtpService _otpService = OtpService();
  
  Timer? _timer;
  int _start = 120; // 2 minutes in seconds
  bool _isResendDisabled = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _start = 120;
    _isResendDisabled = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _isResendDisabled = false;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  String get _timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpCtrl.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    final res = await TaskRunner.run<bool>(
      context: context,
      loadingMessage: "Verifying OTP...",
      successMessage: "Email verified successfully!",
      task: () async {
        bool isValid = await _otpService.verifyOtp(widget.email, otpCtrl.text);
        if (!isValid) throw 'Invalid or expired OTP code';
        return true;
      },
    );

    if (res == true) {
      widget.onVerified();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_read_outlined, size: 70, color: theme.primary),
              ),
              const SizedBox(height: 32),
              Text('Verification Code', style: TextDesign.headingOne()),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextDesign.normalText(color: theme.onHint),
                  children: [
                    const TextSpan(text: 'We have sent a 6-digit code to\n'),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Code expires in: $_timerText',
                style: TextStyle(
                  color: _start < 30 ? Colors.red : theme.onHint,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "000000",
                  hintStyle: TextStyle(color: theme.onHint.withOpacity(0.2)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border, width: 2)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primary, width: 3)),
                ),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _start > 0 ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: Text('Verify & Register', style: TextDesign.buttonText(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 30),
              TextButton(
                onPressed: _isResendDisabled 
                  ? null 
                  : () async {
                      await TaskRunner.run<bool>(
                        context: context,
                        loadingMessage: "Resending OTP...",
                        successMessage: "New code sent to ${widget.email}",
                        task: () async {
                          bool sent = await _otpService.sendOtp(widget.email);
                          if (!sent) throw 'Failed to resend code';
                          _startTimer(); // Restart timer on success
                          return true;
                        },
                      );
                    },
                child: Text(
                  _isResendDisabled 
                    ? "Resend code in $_start s" 
                    : "Didn't receive code? Resend",
                  style: TextDesign.smallText(
                    color: _isResendDisabled ? theme.onHint : theme.primary
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
