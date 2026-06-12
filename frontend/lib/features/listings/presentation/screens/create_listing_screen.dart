import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../providers/listings_provider.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1
  String _selectedType = 'APARTMENT';
  final _titleController = TextEditingController();

  // Step 2
  String _selectedWilaya = 'W16';
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Step 3
  int _rooms = 2;
  int _bathrooms = 1;
  final _areaController = TextEditingController();
  int? _floor;

  // Step 4
  final _priceController = TextEditingController();
  String _pricePeriod = 'monthly';

  // Step 5 - Features
  bool _isFurnished = false;
  bool _hasParking = false;
  bool _hasElevator = false;
  bool _hasBalcony = false;

  // Step 6
  final _descriptionController = TextEditingController();

  // Step 7 - Images
  final List<XFile> _selectedImages = [];
  int _coverIndex = 0;

  final List<String> _propertyTypes = ['APARTMENT', 'HOUSE', 'STUDIO', 'VILLA', 'COMMERCIAL'];
  final Map<String, String> _typeLabels = {
    'APARTMENT': 'شقة', 'HOUSE': 'منزل', 'STUDIO': 'استوديو',
    'VILLA': 'فيلا', 'COMMERCIAL': 'تجاري',
  };

  final List<String> _periods = ['monthly', 'yearly', 'daily'];
  final Map<String, String> _periodLabels = {'monthly': 'شهري', 'yearly': 'سنوي', 'daily': 'يومي'};

  final List<Map<String, String>> _wilayas = [
    {'code': 'W01', 'name': 'أدرار'}, {'code': 'W02', 'name': 'الشلف'},
    {'code': 'W03', 'name': 'الأغواط'}, {'code': 'W04', 'name': 'أم البواقي'},
    {'code': 'W05', 'name': 'باتنة'}, {'code': 'W06', 'name': 'بجاية'},
    {'code': 'W07', 'name': 'بسكرة'}, {'code': 'W08', 'name': 'بشار'},
    {'code': 'W09', 'name': 'البليدة'}, {'code': 'W10', 'name': 'البويرة'},
    {'code': 'W11', 'name': 'تمنراست'}, {'code': 'W12', 'name': 'تبسة'},
    {'code': 'W13', 'name': 'تلمسان'}, {'code': 'W14', 'name': 'تيارت'},
    {'code': 'W15', 'name': 'تيزي وزو'}, {'code': 'W16', 'name': 'الجزائر'},
    {'code': 'W17', 'name': 'الجلفة'}, {'code': 'W18', 'name': 'جيجل'},
    {'code': 'W19', 'name': 'سطيف'}, {'code': 'W20', 'name': 'سعيدة'},
    {'code': 'W21', 'name': 'سكيكدة'}, {'code': 'W22', 'name': 'سيدي بلعباس'},
    {'code': 'W23', 'name': 'عنابة'}, {'code': 'W24', 'name': 'قالمة'},
    {'code': 'W25', 'name': 'قسنطينة'}, {'code': 'W26', 'name': 'المدية'},
    {'code': 'W27', 'name': 'مستغانم'}, {'code': 'W28', 'name': 'المسيلة'},
    {'code': 'W29', 'name': 'معسكر'}, {'code': 'W30', 'name': 'ورقلة'},
    {'code': 'W31', 'name': 'وهران'}, {'code': 'W32', 'name': 'البيض'},
    {'code': 'W33', 'name': 'إليزي'}, {'code': 'W34', 'name': 'برج بوعريريج'},
    {'code': 'W35', 'name': 'بومرداس'}, {'code': 'W36', 'name': 'الطارف'},
    {'code': 'W37', 'name': 'تندوف'}, {'code': 'W38', 'name': 'تيسمسيلت'},
    {'code': 'W39', 'name': 'الوادي'}, {'code': 'W40', 'name': 'خنشلة'},
    {'code': 'W41', 'name': 'سوق أهراس'}, {'code': 'W42', 'name': 'تيبازة'},
    {'code': 'W43', 'name': 'ميلة'}, {'code': 'W44', 'name': 'عين الدفلى'},
    {'code': 'W45', 'name': 'النعامة'}, {'code': 'W46', 'name': 'عين تيموشنت'},
    {'code': 'W47', 'name': 'غرداية'}, {'code': 'W48', 'name': 'غليزان'},
    {'code': 'W49', 'name': 'تيميمون'}, {'code': 'W50', 'name': 'برج باجي مختار'},
    {'code': 'W51', 'name': 'أولاد جلال'}, {'code': 'W52', 'name': 'بني عباس'},
    {'code': 'W53', 'name': 'عين صالح'}, {'code': 'W54', 'name': 'عين قزام'},
    {'code': 'W55', 'name': 'تقرت'}, {'code': 'W56', 'name': 'جانت'},
    {'code': 'W57', 'name': 'المغير'}, {'code': 'W58', 'name': 'المنيعة'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Step> get _steps => [
    Step(
      title: const Text('نوع العقار'),
      content: _buildStep1(),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
    ),
    Step(
      title: const Text('الموقع'),
      content: _buildStep2(),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
    ),
    Step(
      title: const Text('المواصفات'),
      content: _buildStep3(),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
    ),
    Step(
      title: const Text('السعر'),
      content: _buildStep4(),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
    ),
    Step(
      title: const Text('المميزات'),
      content: _buildStep5(),
      isActive: _currentStep >= 4,
      state: _currentStep > 4 ? StepState.complete : StepState.indexed,
    ),
    Step(
      title: const Text('الوصف'),
      content: _buildStep6(),
      isActive: _currentStep >= 5,
      state: _currentStep > 5 ? StepState.complete : StepState.indexed,
    ),
    Step(
      title: const Text('الصور'),
      content: _buildStep7(),
      isActive: _currentStep >= 6,
      state: _currentStep > 6 ? StepState.complete : StepState.indexed,
    ),
  ];

  Widget _buildStep1() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppTextField(
        controller: _titleController,
        label: 'عنوان الإعلان',
        hint: 'مثال: شقة 3 غرف بالقرب من الجامعة',
        validator: (v) => AppValidators.required(v, 'العنوان'),
      ),
      const SizedBox(height: 16),
      const Text('نوع العقار:', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _propertyTypes.map((type) => ChoiceChip(
          label: Text(_typeLabels[type]!),
          selected: _selectedType == type,
          onSelected: (_) => setState(() => _selectedType = type),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: _selectedType == type ? Colors.white : AppColors.textPrimary),
        )).toList(),
      ),
    ],
  );

  Widget _buildStep2() => Column(
    children: [
      DropdownButtonFormField<String>(
        value: _selectedWilaya,
        decoration: const InputDecoration(labelText: 'الولاية', border: OutlineInputBorder()),
        items: _wilayas.map((w) => DropdownMenuItem(value: w['code'], child: Text(w['name']!))).toList(),
        onChanged: (v) => setState(() => _selectedWilaya = v!),
      ),
      const SizedBox(height: 12),
      AppTextField(controller: _cityController, label: 'المدينة / البلدية', validator: (v) => AppValidators.required(v, 'المدينة')),
      const SizedBox(height: 12),
      AppTextField(controller: _addressController, label: 'العنوان (اختياري)', maxLines: 2),
    ],
  );

  Widget _buildStep3() => Column(
    children: [
      _CounterRow(label: 'عدد الغرف', value: _rooms, min: 1, max: 20, onChanged: (v) => setState(() => _rooms = v)),
      const SizedBox(height: 12),
      _CounterRow(label: 'عدد الحمامات', value: _bathrooms, min: 1, max: 10, onChanged: (v) => setState(() => _bathrooms = v)),
      const SizedBox(height: 12),
      AppTextField(controller: _areaController, label: 'المساحة (م²)', keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      DropdownButtonFormField<int?>(
        value: _floor,
        decoration: const InputDecoration(labelText: 'الطابق (اختياري)', border: OutlineInputBorder()),
        items: [
          const DropdownMenuItem(value: null, child: Text('غير محدد')),
          ...List.generate(20, (i) => DropdownMenuItem(value: i, child: Text(i == 0 ? 'الأرضي' : 'الطابق $i'))),
        ],
        onChanged: (v) => setState(() => _floor = v),
      ),
    ],
  );

  Widget _buildStep4() => Column(
    children: [
      AppTextField(
        controller: _priceController,
        label: 'السعر (دج)',
        keyboardType: TextInputType.number,
        validator: (v) => AppValidators.required(v, 'السعر'),
      ),
      const SizedBox(height: 12),
      const Text('فترة الإيجار:', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(
        children: _periods.map((p) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(_periodLabels[p]!),
              selected: _pricePeriod == p,
              onSelected: (_) => setState(() => _pricePeriod = p),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: _pricePeriod == p ? Colors.white : AppColors.textPrimary),
            ),
          ),
        )).toList(),
      ),
    ],
  );

  Widget _buildStep5() => Column(
    children: [
      _ToggleRow(label: 'مفروش', icon: Icons.chair, value: _isFurnished, onChanged: (v) => setState(() => _isFurnished = v)),
      _ToggleRow(label: 'مواقف السيارات', icon: Icons.local_parking, value: _hasParking, onChanged: (v) => setState(() => _hasParking = v)),
      _ToggleRow(label: 'مصعد', icon: Icons.elevator, value: _hasElevator, onChanged: (v) => setState(() => _hasElevator = v)),
      _ToggleRow(label: 'شرفة', icon: Icons.balcony, value: _hasBalcony, onChanged: (v) => setState(() => _hasBalcony = v)),
    ],
  );

  Widget _buildStep6() => AppTextField(
    controller: _descriptionController,
    label: 'وصف العقار',
    hint: 'اكتب وصفاً تفصيلياً للعقار...',
    maxLines: 5,
    validator: (v) => AppValidators.required(v, 'الوصف'),
  );

  Widget _buildStep7() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_selectedImages.isNotEmpty) ...[
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (_, i) => Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _coverIndex = i),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: i == _coverIndex ? AppColors.accent : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(File(_selectedImages[i].path), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                if (i == _coverIndex)
                  Positioned(
                    top: 4, left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.star, color: Colors.white, size: 14),
                    ),
                  ),
                Positioned(
                  top: 4, right: 12,
                  child: GestureDetector(
                    onTap: () => setState(() { _selectedImages.removeAt(i); if (_coverIndex >= _selectedImages.length) _coverIndex = 0; }),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('اضغط على صورة لتعيينها كغلاف', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
      ],
      AppButton(
        label: 'إضافة صور (${_selectedImages.length}/10)',
        variant: AppButtonVariant.outline,
        icon: Icons.add_photo_alternate_outlined,
        onPressed: _pickImages,
      ),
    ],
  );

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.take(10 - _selectedImages.length));
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(listingsProvider.notifier);
      await notifier.createListing(
        title: _titleController.text.trim(),
        type: _selectedType,
        wilaya: _selectedWilaya,
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        rooms: _rooms,
        bathrooms: _bathrooms,
        area: _areaController.text.isNotEmpty ? double.parse(_areaController.text) : null,
        floor: _floor,
        price: double.parse(_priceController.text),
        pricePeriod: _pricePeriod,
        isFurnished: _isFurnished,
        hasParking: _hasParking,
        hasElevator: _hasElevator,
        hasBalcony: _hasBalcony,
        description: _descriptionController.text.trim(),
        images: _selectedImages,
        coverIndex: _coverIndex,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الإعلان بنجاح!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة إعلان جديد'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          type: StepperType.vertical,
          onStepContinue: () {
            if (_currentStep < _steps.length - 1) {
              setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
            else Navigator.of(context).pop();
          },
          controlsBuilder: (ctx, details) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _currentStep == _steps.length - 1 ? 'نشر الإعلان' : 'التالي',
                    onPressed: details.onStepContinue,
                    isLoading: _isLoading && _currentStep == _steps.length - 1,
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'رجوع',
                      variant: AppButtonVariant.outline,
                      onPressed: details.onStepCancel,
                    ),
                  ),
                ],
              ],
            ),
          ),
          steps: _steps,
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterRow({required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
      IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: value > min ? () => onChanged(value - 1) : null,
        color: AppColors.primary,
      ),
      SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: value < max ? () => onChanged(value + 1) : null,
        color: AppColors.primary,
      ),
    ],
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.label, required this.icon, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(label),
    secondary: Icon(icon, color: AppColors.primary),
    value: value,
    onChanged: onChanged,
    activeColor: AppColors.primary,
    contentPadding: EdgeInsets.zero,
  );
}
