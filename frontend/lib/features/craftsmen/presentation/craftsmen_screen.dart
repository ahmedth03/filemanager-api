import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/craftsmen_provider.dart';
import '../data/craftsman_model.dart';

class CraftsmenScreen extends ConsumerWidget {
  const CraftsmenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final craftsmenAsync = ref.watch(craftsmenProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B4F72),
          foregroundColor: Colors.white,
          title: const Text(
            'الحرفيون',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: craftsmenAsync.when(
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
                    'تعذر تحميل الحرفيين. تحقق من الاتصال.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(craftsmenProvider),
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
          data: (craftsmen) {
            if (craftsmen.isEmpty) {
              return const Center(
                child: Text(
                  'لا يوجد حرفيون متاحون حالياً',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: craftsmen.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _CraftsmanCard(craftsman: craftsmen[index]),
            );
          },
        ),
      ),
    );
  }
}

class _CraftsmanCard extends StatelessWidget {
  final CraftsmanModel craftsman;

  const _CraftsmanCard({required this.craftsman});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1B4F72).withOpacity(0.12),
              backgroundImage: craftsman.avatar != null
                  ? NetworkImage(craftsman.avatar!)
                  : null,
              child: craftsman.avatar == null
                  ? Text(
                      craftsman.name.isNotEmpty
                          ? craftsman.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4F72),
                        fontFamily: 'Cairo',
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          craftsman.name,
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
                          color: craftsman.isAvailable
                              ? const Color(0xFFD5F5E3)
                              : const Color(0xFFFDEDEC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          craftsman.isAvailable ? 'متاح' : 'مشغول',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Cairo',
                            color: craftsman.isAvailable
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFE74C3C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    craftsman.specialty,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFF6C757D),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Color(0xFF6C757D)),
                      const SizedBox(width: 4),
                      Text(
                        craftsman.city,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFF39C12)),
                      const SizedBox(width: 2),
                      Text(
                        craftsman.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
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
