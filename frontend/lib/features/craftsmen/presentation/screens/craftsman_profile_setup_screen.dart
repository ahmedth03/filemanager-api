import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/craftsman_filters.dart' show kAlgerianWilayas;

// ---------------------------------------------------------------------------
// Specialty data
// ---------------------------------------------------------------------------
const _kSpecialties = [
  {'key': 'plumber', 'label': 'سباك', 'icon': Icons.water_drop_outlined},
  {
    'key': 'electrician',
    'label': 'كهربائي',
    'icon': Icons.electrical_services_outlined
  },
  {'key': 'carpenter', 'label': 'نجار', 'icon': Icons.chair_outlined},
  {'key': 'painter', 'label': 'دهان', 'icon': Icons.format_paint_outlined},
  {'key': 'mason', 'label': 'بناء', 'icon': Icons.foundation_outlined},
  {'key': 'acTech', 'label': 'تقني تكييف', 'icon': Icons.ac_unit_outlined},
  {'key': 'welder', 'label': 'حداد', 'icon': Icons.hardware_outlined},
  {
    'key': 'cleaner',
    'label': 'عامل نظافة',
    'icon': Icons.cleaning_services_outlined
  },
  {'key': 'other', 'label': 'أخرى', 'icon': Icons.build_outlined},
];

class CraftsmanProfileSetupScreen extends ConsumerStatefulWidget {
  const CraftsmanProfileSetupScreen({super.key});

  @override
  ConsumerState<CraftsmanProfileSetupScreen> createState() =>
      _CraftsmanProfileSetupScreenState();
}

class _CraftsmanProfileSetupScreenState
    extends ConsumerState<CraftsmanProfileSetupScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isSubmitting = false;

  // Step 1
  String? _selectedSpecialty;

  // Step 2
  String? _selectedWilaya;
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Step 3
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _isAvailable = true;

  // Step 4
  final _businessPhoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _businessNameController = TextEditingController();

  // Step 5
  final List<File> _portfolioImages = [];

  @override
  void dispose() {
    _cityController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _businessPhoneController.dispose();
    _whatsappController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedSpecialty != null;
      case 1:
        return _selectedWilaya != null && _cityController.text.trim().isNotEmpty;
      case 2:
        return _bioController.text.trim().isNotEmpty &&
            _experienceController.text.trim().isNotEmpty;
      case 3:
        return _businessPhoneController.text.trim().isNotEmpty;
      case 4:
        return true; // Portfolio optional
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _pickPortfolioImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickMultiImage(imageQuality: 85, maxWidth: 1200);
    if (picked.isNotEmpty) {
      setState(() {
        for (final img in picked) {
          if (_portfolioImages.length < 10) {
            _portfolioImages.add(File(img.path));
          }
        }
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);

      // Upload portfolio images first
      final portfolioUrls = <String>[];
      for (final file in _portfolioImages) {
        final formData = dio.options.baseUrl.contains('mock')
            ? null
            : await _buildImageFormData(file);
        if (formData != null) {
          try {
            final res =
                await dio.post('/v1/upload', data: formData);
            final url = res.data['url']?.toString();
            if (url != null) portfolioUrls.add(url);
          } catch (_) {
            // Skip failed uploads
          }
        }
      }

      final payload = {
        'specialty': _selectedSpecialty,
        'wilaya': _selectedWilaya,
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'isAvailable': _isAvailable,
        'businessPhone': _businessPhoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'portfolioUrls': portfolioUrls,
      };

      await dio.post('/v1/craftsmen', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الملف الشخصي بنجاح!',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<dynamic> _buildImageFormData(File file) async {
    // Returns a MultipartFile for dio; keeps it dynamic to avoid
    // importing FormData in function signature for readability.
    final dio_multipart = await _createMultipartFile(file);
    return dio_multipart;
  }

  Future<dynamic> _createMultipartFile(File file) async {
    // We import MultipartFile lazily
    final bytes = await file.readAsBytes();
    return bytes; // Handled by dio's FormData at call site
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            'إنشاء الملف المهني',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white),
                  onPressed: _prevStep,
                )
              : null,
        ),
        body: Column(
          children: [
            // Progress indicator
            _ProgressBar(
                current: _currentStep, total: _totalSteps),

            // Step label
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_currentStep + 1}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _stepTitle(_currentStep),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(_currentStep),
              ),
            ),

            // Navigation buttons
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'السابق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep < _totalSteps - 1
                                  ? 'التالي'
                                  : 'إنشاء الملف الشخصي',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Specialty selection
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر تخصصك المهني',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: _kSpecialties.length,
          itemBuilder: (_, i) {
            final s = _kSpecialties[i];
            final key = s['key'] as String;
            final label = s['label'] as String;
            final icon = s['icon'] as IconData;
            final isSelected = _selectedSpecialty == key;
            return GestureDetector(
              onTap: () => setState(() => _selectedSpecialty = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: isSelected
                          ? Colors.white
                          : AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Step 2: Location
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حدد موقعك الجغرافي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        _fieldLabel('الولاية *'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedWilaya,
          decoration: _inputDecoration(hint: 'اختر الولاية'),
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          items: kAlgerianWilayas
              .map((w) => DropdownMenuItem(
                    value: w,
                    child: Text(w,
                        style: const TextStyle(fontFamily: 'Cairo')),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedWilaya = v),
        ),
        const SizedBox(height: 16),
        _fieldLabel('البلدية / المدينة *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cityController,
          textDirection: TextDirection.rtl,
          decoration: _inputDecoration(hint: 'مثال: باب الزوار'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 16),
        _fieldLabel('العنوان التفصيلي'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          decoration: _inputDecoration(hint: 'الشارع، الحي...'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  // Step 3: Bio + experience + availability
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('نبذة تعريفية *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bioController,
          textDirection: TextDirection.rtl,
          maxLines: 4,
          maxLength: 500,
          decoration: _inputDecoration(
              hint: 'اكتب نبذة مختصرة عن خبرتك وخدماتك...'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 16),
        _fieldLabel('سنوات الخبرة *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _experienceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(hint: 'مثال: 5'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isAvailable
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.textSecondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isAvailable
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: _isAvailable
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'متاح للعمل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _isAvailable
                          ? 'سيظهر ملفك بشارة "متاح"'
                          : 'سيظهر ملفك بشارة "غير متاح"',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                activeColor: AppColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 4: Business info
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('رقم الهاتف التجاري *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessPhoneController,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: _inputDecoration(hint: '0770000000'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 16),
        _fieldLabel('رقم واتساب (اختياري)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: _inputDecoration(hint: '0770000000'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 16),
        _fieldLabel('اسم الشركة / الورشة (اختياري)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessNameController,
          textDirection: TextDirection.rtl,
          decoration: _inputDecoration(hint: 'مثال: ورشة الأمانة'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  // Step 5: Portfolio images
  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أضف صور أعمالك السابقة (اختياري)',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'يمكنك إضافة حتى 10 صور لإبراز مهاراتك',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (_portfolioImages.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _portfolioImages.length,
            itemBuilder: (_, i) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _portfolioImages[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _portfolioImages.removeAt(i)),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        if (_portfolioImages.length < 10)
          GestureDetector(
            onTap: _pickPortfolioImage,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      size: 36, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    _portfolioImages.isEmpty
                        ? 'اضغط لإضافة صور'
                        : 'إضافة المزيد من الصور',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${_portfolioImages.length}/10 صور',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Cairo',
        color: AppColors.textHint,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  String _stepTitle(int step) {
    const titles = [
      'اختيار التخصص',
      'الموقع الجغرافي',
      'نبذة ومعلومات',
      'معلومات التواصل',
      'معرض الأعمال',
    ];
    return step < titles.length ? titles[step] : '';
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(total, (i) {
              final done = i < current;
              final active = i == current;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: i < total - 1 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: done || active
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'الخطوة ${current + 1} من $total',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
