import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  String? _phoneError;
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _validate() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneError = 'رقم الهاتف مطلوب');
      return false;
    }
    final phoneClean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final localFormat = RegExp(r'^(05|06|07)\d{8}$');
    if (!localFormat.hasMatch(phoneClean)) {
      setState(() => _phoneError = 'أدخل رقم هاتف جزائري صحيح');
      return false;
    }
    setState(() => _phoneError = null);
    return true;
  }

  Future<void> _sendReset() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(authStateProvider.notifier)
        .forgotPassword(_phoneController.text.trim());

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _isSuccess = true);
    } else {
      final state = ref.read(authStateProvider);
      if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.message,
              style: const TextStyle(fontFamily: 'Cairo'),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ref.read(authStateProvider.notifier).clearError();
      }
    }
  }

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
            child: _isSuccess
                ? _SuccessView(
                    phone: _phoneController.text.trim(),
                    onBackToLogin: () => context.go(RouteNames.pathLogin),
                  )
                : _FormView(
                    phoneController: _phoneController,
                    phoneError: _phoneError,
                    isLoading: _isLoading,
                    onPhoneChanged: (_) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                    onSend: _sendReset,
                    onBackToLogin: () => context.go(RouteNames.pathLogin),
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form view
// ---------------------------------------------------------------------------

class _FormView extends StatelessWidget {
  const _FormView({
    required this.phoneController,
    required this.phoneError,
    required this.isLoading,
    required this.onPhoneChanged,
    required this.onSend,
    required this.onBackToLogin,
  });

  final TextEditingController phoneController;
  final String? phoneError;
  final bool isLoading;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onSend;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),

        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'نسيت كلمة المرور؟',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'أدخل رقم هاتفك وسنرسل لك رمز إعادة تعيين كلمة المرور.',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 32),

        AppTextField(
          controller: phoneController,
          label: 'رقم الهاتف',
          hint: '05 XX XX XX XX',
          isPhoneNumber: true,
          errorText: phoneError,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSend(),
          onChanged: onPhoneChanged,
        ),

        const SizedBox(height: 28),

        AppButton(
          label: 'إرسال رمز التحقق',
          onPressed: isLoading ? null : onSend,
          isLoading: isLoading,
          size: AppButtonSize.large,
        ),

        const SizedBox(height: 24),

        Center(
          child: GestureDetector(
            onTap: onBackToLogin,
            child: const Text(
              'العودة إلى تسجيل الدخول',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Success view
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.phone, required this.onBackToLogin});

  final String phone;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 48),

        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFFD5F5E3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 56,
            color: AppColors.success,
          ),
        ),

        const SizedBox(height: 32),

        const Text(
          'تم الإرسال بنجاح!',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          'تم إرسال رمز إعادة تعيين كلمة المرور إلى\n$phone',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تحقق من رسائل الهاتف للحصول على رمز التحقق. قد يستغرق الأمر بضع ثوانٍ.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.info,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'العودة إلى تسجيل الدخول',
            onPressed: onBackToLogin,
            size: AppButtonSize.large,
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
