import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/register_usecase.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserType _selectedRole = UserType.client;

  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _nameError = 'الاسم مطلوب';
        valid = false;
      } else if (name.length < 2) {
        _nameError = 'الاسم قصير جداً';
        valid = false;
      } else {
        _nameError = null;
      }

      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        _phoneError = 'رقم الهاتف مطلوب';
        valid = false;
      } else {
        final phoneClean = phone.replaceAll(RegExp(r'[\s\-]'), '');
        final localFormat = RegExp(r'^(05|06|07)\d{8}$');
        if (!localFormat.hasMatch(phoneClean)) {
          _phoneError = 'أدخل رقم هاتف جزائري صحيح';
          valid = false;
        } else {
          _phoneError = null;
        }
      }

      final password = _passwordController.text;
      if (password.isEmpty) {
        _passwordError = 'كلمة المرور مطلوبة';
        valid = false;
      } else if (password.length < 8) {
        _passwordError = 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
        valid = false;
      } else {
        _passwordError = null;
      }

      final confirm = _confirmPasswordController.text;
      if (confirm.isEmpty) {
        _confirmPasswordError = 'تأكيد كلمة المرور مطلوب';
        valid = false;
      } else if (confirm != _passwordController.text) {
        _confirmPasswordError = 'كلمتا المرور غير متطابقتين';
        valid = false;
      } else {
        _confirmPasswordError = null;
      }
    });
    return valid;
  }

  Future<void> _register() async {
    if (!_validate()) return;

    await ref.read(authStateProvider.notifier).register(
          RegisterParams(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            userType: _selectedRole,
            acceptedTerms: true,
          ),
        );

    if (!mounted) return;

    final state = ref.read(authStateProvider);
    if (state is AuthAuthenticated) {
      if (_selectedRole == UserType.craftsman) {
        context.go(RouteNames.pathCraftsmanProfileSetup);
      } else {
        context.go(RouteNames.pathHome);
      }
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.message,
            style: const TextStyle(fontFamily: 'Cairo'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      ref.read(authStateProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState is AuthLoading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Header
                  const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'أدخل بياناتك للبدء',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Name field
                  AppTextField(
                    controller: _nameController,
                    label: 'الاسم الكامل',
                    hint: 'أدخل اسمك الكامل',
                    prefixIcon: Icons.person_outline,
                    errorText: _nameError,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone field
                  AppTextField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    hint: '05 XX XX XX XX',
                    isPhoneNumber: true,
                    errorText: _phoneError,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_phoneError != null) setState(() => _phoneError = null);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  AppTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    hint: '8 أحرف على الأقل',
                    isPassword: true,
                    errorText: _passwordError,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_passwordError != null) setState(() => _passwordError = null);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm password field
                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'تأكيد كلمة المرور',
                    hint: 'أعد إدخال كلمة المرور',
                    isPassword: true,
                    errorText: _confirmPasswordError,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _register(),
                    onChanged: (_) {
                      if (_confirmPasswordError != null) {
                        setState(() => _confirmPasswordError = null);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Role selection
                  const Text(
                    'نوع الحساب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _RoleButton(
                        label: 'مستخدم',
                        icon: Icons.person,
                        role: UserType.client,
                        selectedRole: _selectedRole,
                        onTap: () => setState(() => _selectedRole = UserType.client),
                      ),
                      const SizedBox(width: 10),
                      _RoleButton(
                        label: 'حرفي',
                        icon: Icons.handyman,
                        role: UserType.craftsman,
                        selectedRole: _selectedRole,
                        onTap: () => setState(() => _selectedRole = UserType.craftsman),
                      ),
                      const SizedBox(width: 10),
                      _RoleButton(
                        label: 'مالك عقار',
                        icon: Icons.home_work,
                        role: UserType.owner,
                        selectedRole: _selectedRole,
                        onTap: () => setState(() => _selectedRole = UserType.owner),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Register button
                  AppButton(
                    label: 'إنشاء الحساب',
                    onPressed: isLoading ? null : _register,
                    isLoading: isLoading,
                    size: AppButtonSize.large,
                  ),

                  const SizedBox(height: 24),

                  // Login link
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go(RouteNames.pathLogin),
                      child: RichText(
                        textDirection: TextDirection.rtl,
                        text: const TextSpan(
                          text: 'لديك حساب بالفعل؟ ',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: 'سجل الدخول',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role selector button
// ---------------------------------------------------------------------------

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.icon,
    required this.role,
    required this.selectedRole,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final UserType role;
  final UserType selectedRole;
  final VoidCallback onTap;

  bool get _isSelected => role == selectedRole;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            boxShadow: _isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: _isSelected ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
