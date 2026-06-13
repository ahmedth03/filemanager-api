import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../craftsmen/presentation/widgets/craftsman_filters.dart'
    show kAlgerianWilayas;
import '../widgets/listing_filters.dart' show kPropertyTypes;
import '../providers/listings_provider.dart';

// ---------------------------------------------------------------------------
// Constants (mirrored from create_listing_screen.dart)
// ---------------------------------------------------------------------------
const _kAmenitiesEdit = [
  {'key': 'furnished', 'label': 'مفروشة', 'icon': Icons.chair_outlined},
  {'key': 'parking', 'label': 'موقف سيارات', 'icon': Icons.local_parking_outlined},
  {'key': 'elevator', 'label': 'مصعد', 'icon': Icons.elevator_outlined},
  {'key': 'balcony', 'label': 'شرفة', 'icon': Icons.deck_outlined},
  {'key': 'garden', 'label': 'حديقة', 'icon': Icons.yard_outlined},
  {'key': 'pool', 'label': 'مسبح', 'icon': Icons.pool_outlined},
  {'key': 'security', 'label': 'حراسة', 'icon': Icons.security_outlined},
  {'key': 'generator', 'label': 'مولد كهربائي', 'icon': Icons.power_outlined},
];

const _kPricePeriodsEdit = [
  {'key': 'monthly', 'label': 'شهرياً'},
  {'key': 'weekly', 'label': 'أسبوعياً'},
  {'key': 'daily', 'label': 'يومياً'},
  {'key': 'sale', 'label': 'إجمالي'},
];

const _kTransactionTypesEdit = [
  {'key': 'RENT', 'label': 'للإيجار'},
  {'key': 'SALE', 'label': 'للبيع'},
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({
    super.key,
    required this.listingId,
    required this.listing,
  });

  final String listingId;
  final Map<String, dynamic> listing;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  int _step = 0;
  final int _totalSteps = 7;
  bool _isSubmitting = false;

  // Step 1 – Transaction type
  String? _selectedTransactionType;

  // Step 2 – Property type + title
  String? _selectedType;
  final _titleController = TextEditingController();

  // Step 3 – Location
  String? _selectedWilaya;
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Step 4 – Details
  final _roomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();

  // Step 5 – Price
  final _priceController = TextEditingController();
  String _pricePeriod = 'monthly';

  // Step 6 – Amenities
  final Set<String> _selectedAmenities = {};

  // Step 7 – Description (review + submit)
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final l = widget.listing;

    // Transaction type – backend stores 'RENT'/'SALE'; fall back gracefully
    final rawTxType = (l['transactionType'] as String? ?? 'RENT').toUpperCase();
    _selectedTransactionType =
        rawTxType == 'SALE' ? 'SALE' : 'RENT';

    // Property type – backend stores 'APARTMENT', 'HOUSE', etc.
    // kPropertyTypes keys are lowercase (e.g. 'apartment')
    final rawType = (l['type'] as String? ?? '').toLowerCase();
    _selectedType = kPropertyTypes.any((t) => t['key'] == rawType)
        ? rawType
        : null;

    _titleController.text = l['title'] as String? ?? '';
    _descriptionController.text = l['description'] as String? ?? '';

    // Location – wilaya is stored as 'W01' etc in backend
    _selectedWilaya = l['wilaya'] as String?;
    _cityController.text = l['city'] as String? ?? '';
    _addressController.text = l['address'] as String? ?? '';

    // Details
    final rooms = l['rooms'];
    _roomsController.text = rooms != null ? rooms.toString() : '';
    final bathrooms = l['bathrooms'];
    _bathroomsController.text = bathrooms != null ? bathrooms.toString() : '';
    final area = l['area'];
    _areaController.text = area != null ? area.toString() : '';
    final floor = l['floor'];
    _floorController.text = floor != null ? floor.toString() : '';
    final totalFloors = l['totalFloors'];
    _totalFloorsController.text =
        totalFloors != null ? totalFloors.toString() : '';

    // Price
    final price = l['price'];
    _priceController.text = price != null ? price.toString() : '';
    _pricePeriod = l['pricePeriod'] as String? ?? 'monthly';

    // Amenities – derive from boolean fields
    if (l['isFurnished'] == true) _selectedAmenities.add('furnished');
    if (l['hasParking'] == true) _selectedAmenities.add('parking');
    if (l['hasElevator'] == true) _selectedAmenities.add('elevator');
    if (l['hasBalcony'] == true) _selectedAmenities.add('balcony');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _roomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _floorController.dispose();
    _totalFloorsController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_step) {
      case 0:
        return _selectedTransactionType != null;
      case 1:
        return _selectedType != null && _titleController.text.trim().isNotEmpty;
      case 2:
        return _selectedWilaya != null && _cityController.text.trim().isNotEmpty;
      case 3:
        return _areaController.text.trim().isNotEmpty;
      case 4:
        return _priceController.text.trim().isNotEmpty;
      case 5:
        return true; // amenities optional
      case 6:
        return _descriptionController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _next() {
    if (!_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى ملء جميع الحقول المطلوبة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType?.toUpperCase(),
        'transactionType': _selectedTransactionType,
        'wilaya': _selectedWilaya,
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'pricePeriod': _pricePeriod,
        'hasParking': _selectedAmenities.contains('parking'),
        'hasElevator': _selectedAmenities.contains('elevator'),
        'hasBalcony': _selectedAmenities.contains('balcony'),
        'isFurnished': _selectedAmenities.contains('furnished'),
      };

      if (_roomsController.text.isNotEmpty) {
        payload['rooms'] = int.tryParse(_roomsController.text);
      }
      if (_bathroomsController.text.isNotEmpty) {
        payload['bathrooms'] = int.tryParse(_bathroomsController.text);
      }
      if (_areaController.text.isNotEmpty) {
        payload['area'] = double.tryParse(_areaController.text);
      }
      if (_floorController.text.isNotEmpty) {
        payload['floor'] = int.tryParse(_floorController.text);
      }
      if (_totalFloorsController.text.isNotEmpty) {
        payload['totalFloors'] = int.tryParse(_totalFloorsController.text);
      }

      await dio.put('/v1/listings/${widget.listingId}', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تحديث الإعلان بنجاح!',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            'تعديل الإعلان',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          leading: _step > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: _back,
                )
              : IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
        ),
        body: Column(
          children: [
            _EditProgressBar(current: _step, total: _totalSteps),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_step + 1}',
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
                    _stepTitle(_step),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStep(_step),
              ),
            ),
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
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
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
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _next,
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
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _step < _totalSteps - 1 ? 'التالي' : 'حفظ التعديلات',
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

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildStep1TransactionType();
      case 1:
        return _buildStep2PropertyType();
      case 2:
        return _buildStep3Location();
      case 3:
        return _buildStep4Details();
      case 4:
        return _buildStep5Price();
      case 5:
        return _buildStep6Amenities();
      case 6:
        return _buildStep7Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Transaction type
  Widget _buildStep1TransactionType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر نوع العملية',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: _kTransactionTypesEdit.map((t) {
            final isSelected = _selectedTransactionType == t['key'];
            return Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedTransactionType = t['key']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    t['label']!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 2: Property type + title
  Widget _buildStep2PropertyType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('عنوان الإعلان *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          textDirection: TextDirection.rtl,
          maxLength: 100,
          decoration: _inputDeco(hint: 'مثال: شقة للإيجار في حيد الوجه'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 20),
        _label('نوع العقار *'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: kPropertyTypes.length,
          itemBuilder: (_, i) {
            final t = kPropertyTypes[i];
            final key = t['key']!;
            final label = t['label']!;
            final isSelected = _selectedType == key;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Step 3: Location
  Widget _buildStep3Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('الولاية *'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: kAlgerianWilayas.contains(_selectedWilaya)
              ? _selectedWilaya
              : null,
          decoration: _inputDeco(hint: 'اختر الولاية'),
          style: const TextStyle(
              fontFamily: 'Cairo', color: AppColors.textPrimary, fontSize: 14),
          items: kAlgerianWilayas
              .map((w) => DropdownMenuItem(
                    value: w,
                    child: Text(w, style: const TextStyle(fontFamily: 'Cairo')),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedWilaya = v),
        ),
        const SizedBox(height: 16),
        _label('البلدية *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cityController,
          textDirection: TextDirection.rtl,
          decoration: _inputDeco(hint: 'مثال: العاشور'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 16),
        _label('العنوان التفصيلي'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          decoration: _inputDeco(hint: 'الشارع، الحي، رقم البناية...'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  // Step 4: Details
  Widget _buildStep4Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('عدد الغرف'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _roomsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDeco(hint: '3'),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('عدد الحمامات'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bathroomsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDeco(hint: '1'),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('المساحة (م²) *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _areaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
          ],
          decoration: _inputDeco(hint: '85'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('الطابق'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _floorController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDeco(hint: '3'),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('عدد الطوابق'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _totalFloorsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDeco(hint: '5'),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 5: Price
  Widget _buildStep5Price() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('السعر (دج) *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDeco(hint: '25000'),
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
        ),
        const SizedBox(height: 20),
        _label('فترة السعر'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _kPricePeriodsEdit.map((u) {
            final isSelected = _pricePeriod == u['key'];
            return GestureDetector(
              onTap: () => setState(() => _pricePeriod = u['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  u['label']!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        if (_priceController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.price_check, color: AppColors.accent),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'السعر المحدد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_priceController.text} دج / ${_kPricePeriodsEdit.firstWhere((u) => u['key'] == _pricePeriod)['label']}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Step 6: Amenities
  Widget _buildStep6Amenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حدد المميزات المتوفرة في العقار',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ..._kAmenitiesEdit.map((a) {
          final key = a['key'] as String;
          final label = a['label'] as String;
          final icon = a['icon'] as IconData;
          final isSelected = _selectedAmenities.contains(key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAmenities.remove(key);
                  } else {
                    _selectedAmenities.add(key);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Step 7: Review + description + submit
  Widget _buildStep7Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ملخص التعديلات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Divider(height: 20),
              _summaryRow('نوع العملية',
                  _selectedTransactionType == 'SALE' ? 'للبيع' : 'للإيجار'),
              _summaryRow('العنوان', _titleController.text),
              _summaryRow('الولاية', _selectedWilaya ?? '-'),
              _summaryRow('المدينة', _cityController.text),
              _summaryRow('المساحة',
                  _areaController.text.isNotEmpty ? '${_areaController.text} م²' : '-'),
              _summaryRow('السعر',
                  '${_priceController.text} دج'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _label('الوصف *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          textDirection: TextDirection.rtl,
          maxLines: 6,
          maxLength: 1000,
          decoration: _inputDeco(
              hint:
                  'اذكر مميزات العقار، القرب من الخدمات، حالة العقار، وأي معلومات مهمة أخرى...'),
          style: const TextStyle(fontFamily: 'Cairo', height: 1.6),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({String? hint}) {
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _label(String text) {
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
      'نوع العملية',
      'نوع العقار',
      'الموقع',
      'تفاصيل العقار',
      'السعر',
      'المميزات',
      'المراجعة والوصف',
    ];
    return step < titles.length ? titles[step] : '';
  }
}

// ---------------------------------------------------------------------------
// Progress bar widget (local copy to keep file self-contained)
// ---------------------------------------------------------------------------
class _EditProgressBar extends StatelessWidget {
  const _EditProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          Row(
            children: List.generate(total, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= current
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'الخطوة ${current + 1} من $total',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
