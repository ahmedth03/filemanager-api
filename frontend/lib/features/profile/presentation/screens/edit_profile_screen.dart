import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String? _nameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController =
        TextEditingController(text: user?.formattedPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        final emailRegex =
            RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
        if (!emailRegex.hasMatch(email)) {
          _emailError = 'البريد الإلكتروني غير صحيح';
          valid = false;
        } else {
          _emailError = null;
        }
      } else {
        _emailError = null;
      }
    });
    return valid;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final success = await ref.read(profileNotifierProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم تحديث الملف الشخصي بنجاح',
            style: TextStyle(fontFamily: 'Cairo'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.pop();
    } else {
      final profileState = ref.read(profileNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profileState.errorMessage ?? 'حدث خطأ ما',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final isUpdating = profileState.isUpdating;
    final user = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'تعديل الملف الشخصي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : _save,
              child: Text(
                'حفظ',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  color:
                      isUpdating ? AppColors.textSecondary : AppColors.primary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar section
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'رفع الصورة قادم قريباً',
                          style: TextStyle(fontFamily: 'Cairo'),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: user?.avatar != null
                            ? NetworkImage(user!.avatar!)
                            : null,
                        child: user?.avatar == null
                            ? Text(
                                user?.initials ?? 'أ',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFamily: 'Cairo',
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'اضغط لتغيير الصورة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
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

                // Email field
                AppTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني (اختياري)',
                  hint: 'example@email.com',
                  prefixIcon: Icons.email_outlined,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                ),

                const SizedBox(height: 16),

                // Phone field (read-only — changing phone requires verification)
                AppTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  prefixIcon: Icons.phone_outlined,
                  readOnly: true,
                  enabled: false,
                  helperText: 'لتغيير رقم الهاتف يرجى التواصل مع الدعم',
                ),

                const SizedBox(height: 32),

                // Save button
                AppButton(
                  label: 'حفظ التغييرات',
                  onPressed: isUpdating ? null : _save,
                  isLoading: isUpdating,
                  size: AppButtonSize.large,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
