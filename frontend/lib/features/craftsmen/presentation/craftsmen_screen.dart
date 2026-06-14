import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/craftsmen_provider.dart';
import '../data/craftsman_model.dart';

class CraftsmenScreen extends ConsumerStatefulWidget {
  const CraftsmenScreen({super.key});

  @override
  ConsumerState<CraftsmenScreen> createState() => _CraftsmenScreenState();
}

class _CraftsmenScreenState extends ConsumerState<CraftsmenScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final craftsmenAsync = ref.watch(craftsmenProvider);
    final filter = ref.watch(craftsmanFilterProvider);
    final specialtiesAsync = ref.watch(specialtiesProvider);

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
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onSubmitted: (val) {
                  ref.read(craftsmanFilterProvider.notifier).state = filter
                      .copyWith(search: val.trim().isEmpty ? null : val.trim());
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن حرفي...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1B4F72)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(craftsmanFilterProvider.notifier)
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
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Available only chip
                  FilterChip(
                    label: const Text('متاح فقط',
                        style: TextStyle(fontFamily: 'Cairo')),
                    selected: filter.isAvailable == true,
                    onSelected: (val) {
                      ref.read(craftsmanFilterProvider.notifier).state = val
                          ? filter.copyWith(isAvailable: true)
                          : filter.copyWith(clearIsAvailable: true);
                    },
                    selectedColor:
                        const Color(0xFF1B4F72).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF1B4F72),
                    labelStyle: TextStyle(
                      color: filter.isAvailable == true
                          ? const Color(0xFF1B4F72)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Specialty chips
                  specialtiesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (specialties) => Row(
                      children: specialties
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChip(
                                label: Text(s.nameAr,
                                    style:
                                        const TextStyle(fontFamily: 'Cairo')),
                                selected: filter.specialtyId == s.id,
                                onSelected: (val) {
                                  ref
                                      .read(craftsmanFilterProvider.notifier)
                                      .state = val
                                      ? filter.copyWith(specialtyId: s.id)
                                      : filter.copyWith(
                                          clearSpecialtyId: true);
                                },
                                selectedColor: const Color(0xFF1B4F72)
                                    .withOpacity(0.15),
                                checkmarkColor: const Color(0xFF1B4F72),
                                labelStyle: TextStyle(
                                  color: filter.specialtyId == s.id
                                      ? const Color(0xFF1B4F72)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: craftsmenAsync.when(
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
                              ref.invalidate(craftsmenProvider),
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
                        'لا يوجد حرفيون متاحون حالياً',
                        style:
                            TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(craftsmenProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: result.data.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => _CraftsmanCard(
                        craftsman: result.data[index],
                        onTap: () => context.push(
                            '/craftsmen/${result.data[index].id}'),
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

class _CraftsmanCard extends StatelessWidget {
  final CraftsmanModel craftsman;
  final VoidCallback onTap;

  const _CraftsmanCard({required this.craftsman, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    const Color(0xFF1B4F72).withOpacity(0.12),
                backgroundImage: craftsman.user.avatarUrl != null
                    ? NetworkImage(craftsman.user.avatarUrl!)
                    : null,
                child: craftsman.user.avatarUrl == null
                    ? Text(
                        craftsman.fullName.isNotEmpty
                            ? craftsman.fullName[0].toUpperCase()
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
                            craftsman.fullName,
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
                      craftsman.specialty?.nameAr ?? '',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Color(0xFF6C757D),
                          fontSize: 13),
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
                              color: Color(0xFF6C757D)),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded,
                            size: 16, color: Color(0xFFF39C12)),
                        const SizedBox(width: 2),
                        Text(
                          craftsman.avgRating.toStringAsFixed(1),
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
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: Color(0xFF6C757D)),
            ],
          ),
        ),
      ),
    );
  }
}
