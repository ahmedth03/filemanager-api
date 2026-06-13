import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../craftsmen/presentation/widgets/craftsman_filters.dart'
    show kAlgerianWilayas;
import '../widgets/listing_filters.dart' show kPropertyTypes;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const _kAmenities = [
  {'key': 'furnished', 'label': 'مفروشة', 'icon': Icons.chair_outlined},
  {'key': 'parking', 'label': 'موقف سيارات', 'icon': Icons.local_parking_outlined},
  {'key': 'elevator', 'label': 'مصعد', 'icon': Icons.elevator_outlined},
  {'key': 'balcony', 'label': 'شرفة', 'icon': Icons.deck_outlined},
  {'key': 'garden', 'label': 'حديقة', 'icon': Icons.yard_outlined},
  {'key': 'pool', 'label': 'مسبح', 'icon': Icons.pool_outlined},
  {'key': 'security', 'label': 'حراسة', 'icon': Icons.security_outlined},
  {'key': 'generator', 'label': 'مولد كهربائي', 'icon': Icons.power_outlined},
];

const _kPriceUnits = [
  {'key': 'perMonth', 'label': 'شهرياً'},
  {'key': 'perYear', 'label': 'سنوياً'},
  {'key': 'total', 'label': 'إجمالي'},
];

const _kTransactionTypes = [
  {'key': 'rent', 'label': 'للإيجار'},
  {'key': 'sale', 'label': 'للبيع'},
];

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key, this.editId});
  final String? editId;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  int _step = 0;
  final int _totalSteps = 7;
  bool _isSubmitting = false;

  // Step 1
  final _titleController = TextEditingController();
  String? _selectedType;
  String? _selectedTransactionType;

  // Step 2
  String? _selectedWilaya;
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Step 3
  final _roomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();

  // Step 4
  final _priceController = TextEditingController();
  String _priceUnit = 'perMonth';

  // Step 5
  final Set<String> _selectedAmenities = {};

  // Step 6
  final _descriptionController = TextEditingController();

  // Step 7
  final List<File> _images = [];
  int _coverIndex = 0;

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
        return _titleController.text.trim().isNotEmpty &&
            _selectedType != null &&
            _selectedTransactionType != null;
      case 1:
        return _selectedWilaya != null &&
            _cityController.text.trim().isNotEmpty;
      case 2:
        return _areaController.text.trim().isNotEmpty;
      case 3:
        return _priceController.text.trim().isNotEmpty;
      case 4:
        return true;
      case 5:
        return _descriptionController.text.trim().isNotEmpty;
      case 6:
        return true;
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85, maxWidth: 1200);
    if (picked.isNotEmpty) {
      setState(() {
        for (final img in picked) {
          if (_images.length < 15) {
            _images.add(File(img.path));
          }
        }
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);

      // Build payload
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'transactionType': _selectedTransactionType?.toUpperCase(),
        'wilaya': _selectedWilaya,
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'priceUnit': _priceUnit,
        'description': _descriptionController.text.trim(),
        'amenities': _selectedAmenities.toList(),
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

      final response = await dio.post('/v1/listings', data: payload);
      final listingId = response.data['data']?['_id']?.toString() ??
          response.data['data']?['id']?.toString() ?? '';

      // Upload images if any
      if (_images.isNotEmpty && listingId.isNotEmpty) {
        for (int i = 0; i < _images.length; i++) {
          try {
            final bytes = await _images[i].readAsBytes();
            // In production, use FormData with MultipartFile
            await dio.post('/v1/listings/$listingId/images', data: {
              'isCover': i == _coverIndex,
              'order': i,
            });
          } catch (_) {
            // Skip failed uploads
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم نشر الإعلان بنجاح!',
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            widget.editId != null ? 'تعديل الإعلان' : 'إضافة إعلان جديد',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          leading: _step > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white),
                  onPressed: _back,
                )
              : IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
        ),
        body: Column(
          children: [
            _ProgressBar(current: _step, total: _totalSteps),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
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
                              _step < _totalSteps - 1
                                  ? 'التالي'
                                  : 'نشر الإعلان',
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
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      case 5:
        return _buildStep6();
      case 6:
        return _buildStep7();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Title + type
  Widget _buildStep1() {
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
        const SizedBox(height: 20),
        _label('نوع العملية *'),
        const SizedBox(height: 12),
        Row(
          children: _kTransactionTypes.map((t) {
            final isSelected = _selectedTransactionType == t['key'];
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedTransactionType = t['key']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                    ),
                  ),
                  child: Text(
                    t['label']!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? Colors.white : AppColors.textPrimary,
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

  // Step 2: Location
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('الولاية *'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedWilaya,
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

  // Step 3: Rooms + area + floor
  Widget _buildStep3() {
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

  // Step 4: Price
  Widget _buildStep4() {
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
        _label('وحدة السعر'),
        const SizedBox(height: 12),
        Row(
          children: _kPriceUnits.map((u) {
            final isSelected = _priceUnit == u['key'];
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: GestureDetector(
                onTap: () => setState(() => _priceUnit = u['key']!),
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
                      color:
                          isSelected ? Colors.white : AppColors.textPrimary,
                    ),
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
                      '${_priceController.text} دج / ${_kPriceUnits.firstWhere((u) => u['key'] == _priceUnit)['label']}',
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

  // Step 5: Amenities
  Widget _buildStep5() {
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
        ..._kAmenities.map((a) {
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
                        color:
                            isSelected ? AppColors.primary : Colors.white,
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

  // Step 6: Description
  Widget _buildStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اكتب وصفاً تفصيلياً للعقار',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          textDirection: TextDirection.rtl,
          maxLines: 8,
          maxLength: 1000,
          decoration: _inputDeco(
              hint:
                  'اذكر مميزات العقار، القرب من الخدمات، حالة العقار، وأي معلومات مهمة أخرى...'),
          style: const TextStyle(fontFamily: 'Cairo', height: 1.6),
        ),
      ],
    );
  }

  // Step 7: Images
  Widget _buildStep7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أضف صور العقار (اختياري، حتى 15 صورة)',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'اضغط على صورة لتعيينها كصورة غلاف',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (_images.isNotEmpty) ...[
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
            itemCount: _images.length,
            itemBuilder: (_, i) {
              final isCover = i == _coverIndex;
              return GestureDetector(
                onTap: () => setState(() => _coverIndex = i),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_images[i], fit: BoxFit.cover),
                    ),
                    if (isCover)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.accent, width: 3),
                        ),
                      ),
                    if (isCover)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'غلاف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: isCover ? 28 : 4,
                      left: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _images.removeAt(i);
                            if (_coverIndex >= _images.length) {
                              _coverIndex = 0;
                            }
                          });
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        if (_images.length < 15)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
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
                    _images.isEmpty ? 'إضافة صور' : 'إضافة المزيد',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${_images.length}/15 صور',
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      'معلومات أساسية',
      'الموقع',
      'تفاصيل العقار',
      'السعر',
      'المميزات',
      'الوصف',
      'الصور',
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
