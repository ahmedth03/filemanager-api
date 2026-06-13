import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../craftsmen/presentation/widgets/craftsman_filters.dart'
    show kAlgerianWilayas;

const List<Map<String, String>> kPropertyTypes = [
  {'key': 'apartment', 'label': 'شقة'},
  {'key': 'house', 'label': 'منزل'},
  {'key': 'villa', 'label': 'فيلا'},
  {'key': 'studio', 'label': 'استوديو'},
  {'key': 'shop', 'label': 'محل تجاري'},
  {'key': 'land', 'label': 'أرض'},
];

const List<Map<String, String>> kTransactionTypes = [
  {'key': 'rent', 'label': 'للإيجار'},
  {'key': 'sale', 'label': 'للبيع'},
];

class ListingFiltersSheet extends StatefulWidget {
  const ListingFiltersSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  final Map<String, dynamic> initialFilters;
  final void Function(Map<String, dynamic>) onApply;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> initialFilters,
    required void Function(Map<String, dynamic>) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ListingFiltersSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ListingFiltersSheet> createState() => _ListingFiltersSheetState();
}

class _ListingFiltersSheetState extends State<ListingFiltersSheet> {
  String? _selectedType;
  String? _selectedTransactionType;
  String? _selectedWilaya;
  RangeValues _priceRange = const RangeValues(0, 500000);
  int _minRooms = 0;
  bool _furnished = false;
  bool _parking = false;
  bool _elevator = false;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters;
    _selectedType = f['type'] as String?;
    _selectedTransactionType = f['transactionType'] as String?;
    _selectedWilaya = f['wilaya'] as String?;
    final minP = (f['minPrice'] as num?)?.toDouble() ?? 0;
    final maxP = (f['maxPrice'] as num?)?.toDouble() ?? 500000;
    _priceRange = RangeValues(minP, maxP);
    _minRooms = (f['minRooms'] as int?) ?? 0;
    _furnished = f['furnished'] as bool? ?? false;
    _parking = f['parking'] as bool? ?? false;
    _elevator = f['elevator'] as bool? ?? false;
  }

  void _reset() {
    setState(() {
      _selectedType = null;
      _selectedTransactionType = null;
      _selectedWilaya = null;
      _priceRange = const RangeValues(0, 500000);
      _minRooms = 0;
      _furnished = false;
      _parking = false;
      _elevator = false;
    });
  }

  void _apply() {
    final filters = <String, dynamic>{};
    if (_selectedType != null) filters['type'] = _selectedType;
    if (_selectedTransactionType != null)
      filters['transactionType'] = _selectedTransactionType;
    if (_selectedWilaya != null) filters['wilaya'] = _selectedWilaya;
    if (_priceRange.start > 0) filters['minPrice'] = _priceRange.start;
    if (_priceRange.end < 500000) filters['maxPrice'] = _priceRange.end;
    if (_minRooms > 0) filters['minRooms'] = _minRooms;
    if (_furnished) filters['furnished'] = true;
    if (_parking) filters['parking'] = true;
    if (_elevator) filters['elevator'] = true;
    widget.onApply(filters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                      'تصفية العقارات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _reset,
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
                    // Transaction type
                    _sectionTitle('نوع العملية'),
                    const SizedBox(height: 10),
                    Row(
                      children: kTransactionTypes.map((t) {
                        final isSelected =
                            _selectedTransactionType == t['key'];
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _SelectChip(
                            label: t['label']!,
                            selected: isSelected,
                            onTap: () => setState(() {
                              _selectedTransactionType =
                                  isSelected ? null : t['key'];
                            }),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Property type
                    _sectionTitle('نوع العقار'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kPropertyTypes.map((t) {
                        final isSelected = _selectedType == t['key'];
                        return _SelectChip(
                          label: t['label']!,
                          selected: isSelected,
                          onTap: () => setState(() {
                            _selectedType =
                                isSelected ? null : t['key'];
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Wilaya
                    _sectionTitle('الولاية'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedWilaya,
                      decoration: _dropdownDecoration('اختر الولاية'),
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
                      onChanged: (v) =>
                          setState(() => _selectedWilaya = v),
                    ),
                    const SizedBox(height: 20),

                    // Price range
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('نطاق السعر (دج)'),
                        Text(
                          '${_formatNum(_priceRange.start.toInt())} - ${_priceRange.end >= 500000 ? 'أكثر' : _formatNum(_priceRange.end.toInt())}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accent,
                        thumbColor: AppColors.accent,
                        inactiveTrackColor: AppColors.border,
                        rangeThumbShape:
                            const RoundRangeSliderThumbShape(
                                enabledThumbRadius: 8),
                        overlayColor: AppColors.accent.withOpacity(0.1),
                      ),
                      child: RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 500000,
                        divisions: 50,
                        onChanged: (v) =>
                            setState(() => _priceRange = v),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rooms
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('عدد الغرف (الحد الأدنى)'),
                        Text(
                          _minRooms == 0 ? 'الكل' : '$_minRooms+',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [0, 1, 2, 3, 4, 5, 6].map((n) {
                        final isSelected = _minRooms == n;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _minRooms = n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                n == 0 ? 'الكل' : n == 6 ? '6+' : '$n',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: n == 0 ? 9 : 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Amenities toggles
                    _sectionTitle('مميزات إضافية'),
                    const SizedBox(height: 10),
                    _ToggleRow(
                      label: 'مفروشة',
                      icon: Icons.chair_outlined,
                      value: _furnished,
                      onChanged: (v) =>
                          setState(() => _furnished = v),
                    ),
                    const SizedBox(height: 8),
                    _ToggleRow(
                      label: 'موقف سيارات',
                      icon: Icons.local_parking_outlined,
                      value: _parking,
                      onChanged: (v) =>
                          setState(() => _parking = v),
                    ),
                    const SizedBox(height: 8),
                    _ToggleRow(
                      label: 'مصعد',
                      icon: Icons.elevator_outlined,
                      value: _elevator,
                      onChanged: (v) =>
                          setState(() => _elevator = v),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Apply button
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
                  onPressed: _apply,
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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Cairo'),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}ك';
    return n.toString();
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? AppColors.primary : AppColors.border),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: value ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: value ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  value ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
