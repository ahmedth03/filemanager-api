import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/properties_provider.dart';
import '../data/property_model.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

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
        body: propertiesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B4F72)),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: Color(0xFF6C757D),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تعذر تحميل العقارات. تحقق من الاتصال.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(propertiesProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F72),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (properties) {
            if (properties.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد عقارات متاحة حالياً',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _PropertyCard(property: properties[index]),
            );
          },
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;

  const _PropertyCard({required this.property});

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} م ر.س';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ألف ر.س';
    }
    return '${price.toStringAsFixed(0)} ر.س';
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return 'متاح';
      case 'RENTED':
        return 'مؤجّر';
      case 'SOLD':
        return 'مُباع';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return const Color(0xFF27AE60);
      case 'RENTED':
      case 'SOLD':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF6C757D);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return const Color(0xFFD5F5E3);
      case 'RENTED':
      case 'SOLD':
        return const Color(0xFFFDEDEC);
      default:
        return const Color(0xFFF8F9FA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (property.image != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                property.image!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDEE2E6),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 60,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFDEE2E6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              width: double.infinity,
              child: const Icon(
                Icons.apartment_rounded,
                size: 50,
                color: Color(0xFF6C757D),
              ),
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
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusBgColor(property.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(property.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          color: _statusColor(property.status),
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
                        color: Color(0xFF6C757D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.category_outlined,
                        size: 14, color: Color(0xFF6C757D)),
                    const SizedBox(width: 4),
                    Text(
                      property.type,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: Color(0xFF6C757D),
                      ),
                    ),
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
    );
  }
}
