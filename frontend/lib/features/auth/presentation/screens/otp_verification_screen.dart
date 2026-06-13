import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';

// ---------------------------------------------------------------------------
// OtpVerificationScreen
// ---------------------------------------------------------------------------

/// Screen that receives a [phone] number and prompts the user to enter the
/// 6-digit OTP code sent to that number.
///
/// On success it navigates to /login/reset-password?token=<token>.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 6;
  static const int _resendCooldown = 60; // seconds

  // One controller + focus node per digit box
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  // Countdown timer state
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Countdown ─────────────────────────────────────────────────────────────

  void _startCountdown() {
    _secondsLeft = _resendCooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // ── OTP helpers ───────────────────────────────────────────────────────────

  String get _currentOtp =>
      _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _currentOtp.length == _otpLength;

  void _onDigitChanged(int index, String value) {
    // Accept only single digit
    if (value.isEmpty) {
      // Backspace — move focus to previous box
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    // Accept only the last character typed (in case of paste)
    final digit = value.characters.last;
    _controllers[index].text = digit;
    _controllers[index].selection = TextSelection.fromPosition(
      TextPosition(offset: _controllers[index].text.length),
    );

    if (index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      // Auto-submit when all 6 digits are entered
      if (_isOtpComplete) _submit();
    }

    // Clear error as the user types
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_isOtpComplete) {
      setState(() => _errorMessage = 'يرجى إدخال الرمز المكوّن من 6 أرقام');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('/api/v1/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': widget.phone,
              'otp': _currentOtp,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        final token = data?['token'] as String? ?? '';
        context.go('/login/reset-password?token=$token');
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final message =
            body['message'] as String? ?? 'رمز التحقق غير صحيح';
        setState(() => _errorMessage = message);
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _errorMessage = 'انتهت مهلة الاتصال، يرجى المحاولة مجدداً');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'حدث خطأ، يرجى المحاولة مجدداً');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Resend ────────────────────────────────────────────────────────────────

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;

    setState(() => _errorMessage = null);

    try {
      await http
          .post(
            Uri.parse('/api/v1/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': widget.phone}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Non-critical — the user can still try again later
    }

    if (!mounted) return;
    _startCountdown();

    // Clear existing inputs
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم إعادة إرسال رمز التحقق',
          style: TextStyle(fontFamily: 'Cairo'),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // ── Icon ────────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Title ────────────────────────────────────────────────────
                const Text(
                  'أدخل رمز التحقق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // ── Subtitle with phone ──────────────────────────────────────
                Text(
                  'تم إرسال رمز التحقق إلى ${widget.phone}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // ── OTP Input Row ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    _otpLength,
                    (index) => _OtpBox(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      onChanged: (v) => _onDigitChanged(index, v),
                      onKeyEvent: (e) => _onKeyEvent(index, e),
                    ),
                  ),
                ),

                // ── Error message ─────────────────────────────────────────────
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Submit button ─────────────────────────────────────────────
                AppButton(
                  label: 'تأكيد الرمز',
                  onPressed: (_isLoading || !_isOtpComplete) ? null : _submit,
                  isLoading: _isLoading,
                  size: AppButtonSize.large,
                ),

                const SizedBox(height: 24),

                // ── Resend section ────────────────────────────────────────────
                Center(
                  child: _secondsLeft > 0
                      ? RichText(
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'إعادة الإرسال بعد '),
                              TextSpan(
                                text: '$_secondsLeft ث',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: _resendOtp,
                          child: const Text(
                            'إعادة إرسال الرمز',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _OtpBox — Single digit input widget
// ---------------------------------------------------------------------------

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: 48,
        height: 58,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 2, // allow 2 so we can detect replacement
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
