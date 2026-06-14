import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/properties_provider.dart';
import '../data/property_model.dart';

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  final _searchController = TextEditingController();

  static const _types = [
    ('APARTMENT', 'شقة'),
    ('HOUSE', 'بيت'),
    ('STUDIO', 'استوديو'),
    ('VILLA', 'فيلا'),
    ('COMMERCIAL', 'تجاري'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);
    final filter = ref.watch(propertyFilterProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B4F72),
          foregroundColor: Colors.white,
          title: const Text(
            'العقارات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onSubmitted: (val) {
                  ref.read(propertyFilterProvider.notifier).state =
                      filter.copyWith(
                          search: val.trim().isEmpty ? null : val.trim());
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن عقار...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1B4F72)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(propertyFilterProvider.notifier)
                                .state = filter.copyWith(clearSearch: true);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1B4F72), width: 2),
                  ),
                ),
              ),
            ),
            // Type filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: _types
                    .map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(t.$2,
                              style:
                                  const TextStyle(fontFamily: 'Cairo')),
                          selected: filter.type == t.$1,
                          onSelected: (val) {
                            ref
                                .read(propertyFilterProvider.notifier)
                                .state = val
                                ? filter.copyWith(type: t.$1)
                                : filter.copyWith(clearType: true);
                          },
                          selectedColor: const Color(0xFFF39C12)
                              .withOpacity(0.15),
                          checkmarkColor: const Color(0xFFF39C12),
                          labelStyle: TextStyle(
                            color: filter.type == t.$1
                                ? const Color(0xFFF39C12)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // List
            Expanded(
              child: propertiesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF1B4F72)),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 64, color: Color(0xFF6C757D)),
                        const SizedBox(height: 16),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              color: Color(0xFF6C757D)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ref.invalidate(propertiesProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة',
                              style: TextStyle(fontFamily: 'Cairo')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F72),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (result) {
                  if (result.data.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد عقارات متاحة حالياً',
                        style:
                            TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(propertiesProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: result.data.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => _PropertyCard(
                        property: result.data[index],
                        onTap: () => context.push(
                            '/listings/${result.data[index].id}'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;

  const _PropertyCard({required this.property, required this.onTap});

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون دج';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ألف دج';
    }
    return '${price.toStringAsFixed(0)} دج';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'APARTMENT':
        return 'شقة';
      case 'HOUSE':
        return 'بيت';
      case 'STUDIO':
        return 'استوديو';
      case 'VILLA':
        return 'فيلا';
      case 'COMMERCIAL':
        return 'تجاري';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = property.coverImageUrl;

    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: coverUrl != null
                  ? Image.network(
                      coverUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                    )
                  : _ImagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _typeLabel(property.type),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Cairo',
                            color: Color(0xFFF39C12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Color(0xFF6C757D)),
                      const SizedBox(width: 4),
                      Text(
                        property.city,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: Color(0xFF6C757D)),
                      ),
                      const SizedBox(width: 12),
                      if (property.rooms > 0) ...[
                        const Icon(Icons.bed_outlined,
                            size: 14, color: Color(0xFF6C757D)),
                        const SizedBox(width: 4),
                        Text(
                          '${property.rooms} غرف',
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: Color(0xFF6C757D)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatPrice(property.price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: Color(0xFF1B4F72),
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
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFDEE2E6),
      child: const Icon(Icons.apartment_rounded,
          size: 60, color: Color(0xFF6C757D)),
    );
  }
}
