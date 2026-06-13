import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// All 58 Algerian wilayas
// ---------------------------------------------------------------------------
const List<String> kAlgerianWilayas = [
  'أدرار', 'الشلف', 'الأغواط', 'أم البواقي', 'باتنة', 'بجاية', 'بسكرة',
  'بشار', 'البليدة', 'البويرة', 'تمنراست', 'تبسة', 'تلمسان', 'تيارت',
  'تيزي وزو', 'الجزائر', 'الجلفة', 'جيجل', 'سطيف', 'سعيدة', 'سكيكدة',
  'سيدي بلعباس', 'عنابة', 'قالمة', 'قسنطينة', 'المدية', 'مستغانم',
  'المسيلة', 'معسكر', 'ورقلة', 'وهران', 'البيض', 'إليزي', 'برج بوعريريج',
  'بومرداس', 'الطارف', 'تندوف', 'تيسمسيلت', 'الوادي', 'خنشلة',
  'سوق أهراس', 'تيبازة', 'ميلة', 'عين الدفلى', 'النعامة', 'عين تيموشنت',
  'غرداية', 'غليزان', 'تيميمون', 'برج باجي مختار', 'أولاد جلال',
  'بني عباس', 'عين صالح', 'عين قزام', 'توقرت', 'جانت', 'المغير',
  'المنيعة',
];

const List<Map<String, String>> kSpecialties = [
  {'key': 'plumber', 'label': 'سباك'},
  {'key': 'electrician', 'label': 'كهربائي'},
  {'key': 'carpenter', 'label': 'نجار'},
  {'key': 'painter', 'label': 'دهان'},
  {'key': 'mason', 'label': 'بناء'},
  {'key': 'acTech', 'label': 'تقني تكييف'},
  {'key': 'welder', 'label': 'حداد'},
  {'key': 'cleaner', 'label': 'عامل نظافة'},
  {'key': 'other', 'label': 'أخرى'},
];

class CraftsmanFiltersSheet extends StatefulWidget {
  const CraftsmanFiltersSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  final Map<String, dynamic> initialFilters;
  final void Function(Map<String, dynamic> filters) onApply;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> initialFilters,
    required void Function(Map<String, dynamic>) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CraftsmanFiltersSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<CraftsmanFiltersSheet> createState() => _CraftsmanFiltersSheetState();
}

class _CraftsmanFiltersSheetState extends State<CraftsmanFiltersSheet> {
  String? _selectedSpecialty;
  String? _selectedWilaya;
  double _minRating = 0;
  bool? _isAvailable;

  @override
  void initState() {
    super.initState();
    _selectedSpecialty =
        widget.initialFilters['specialty'] as String?;
    _selectedWilaya = widget.initialFilters['wilaya'] as String?;
    _minRating =
        (widget.initialFilters['minRating'] as num?)?.toDouble() ?? 0;
    _isAvailable = widget.initialFilters['isAvailable'] as bool?;
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};
    if (_selectedSpecialty != null) filters['specialty'] = _selectedSpecialty;
    if (_selectedWilaya != null) filters['wilaya'] = _selectedWilaya;
    if (_minRating > 0) filters['minRating'] = _minRating;
    if (_isAvailable != null) filters['isAvailable'] = _isAvailable;
    widget.onApply(filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedSpecialty = null;
      _selectedWilaya = null;
      _minRating = 0;
      _isAvailable = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'تصفية النتائج',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text(
                        'إعادة ضبط',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Specialty section
                    const Text(
                      'التخصص',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kSpecialties.map((s) {
                        final isSelected = _selectedSpecialty == s['key'];
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedSpecialty =
                                isSelected ? null : s['key'];
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              s['label']!,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Wilaya section
                    const Text(
                      'الولاية',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedWilaya,
                      decoration: InputDecoration(
                        hintText: 'اختر الولاية',
                        hintStyle: const TextStyle(fontFamily: 'Cairo'),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('كل الولايات',
                              style: TextStyle(fontFamily: 'Cairo')),
                        ),
                        ...kAlgerianWilayas.map(
                          (w) => DropdownMenuItem<String>(
                            value: w,
                            child: Text(w,
                                style:
                                    const TextStyle(fontFamily: 'Cairo')),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedWilaya = v),
                    ),
                    const SizedBox(height: 24),

                    // Min rating section
                    Row(
                      children: [
                        const Text(
                          'الحد الأدنى للتقييم',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _minRating == 0
                              ? 'الكل'
                              : '${_minRating.toStringAsFixed(1)} ★',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accent,
                        thumbColor: AppColors.accent,
                        inactiveTrackColor: AppColors.border,
                        overlayColor: AppColors.accent.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: _minRating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        onChanged: (v) => setState(() => _minRating = v),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Availability section
                    const Text(
                      'الحالة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _AvailabilityChip(
                          label: 'الكل',
                          selected: _isAvailable == null,
                          onTap: () =>
                              setState(() => _isAvailable = null),
                        ),
                        const SizedBox(width: 8),
                        _AvailabilityChip(
                          label: 'متاح الآن',
                          selected: _isAvailable == true,
                          color: AppColors.success,
                          onTap: () =>
                              setState(() => _isAvailable = true),
                        ),
                        const SizedBox(width: 8),
                        _AvailabilityChip(
                          label: 'غير متاح',
                          selected: _isAvailable == false,
                          color: AppColors.textSecondary,
                          onTap: () =>
                              setState(() => _isAvailable = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Bottom buttons
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
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'تطبيق التصفية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? activeColor : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
