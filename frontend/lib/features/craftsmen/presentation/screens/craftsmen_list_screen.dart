import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../providers/craftsmen_provider.dart';
import '../widgets/craftsman_card.dart';
import '../widgets/craftsman_filters.dart';

class CraftsmenListScreen extends ConsumerStatefulWidget {
  const CraftsmenListScreen({super.key});

  @override
  ConsumerState<CraftsmenListScreen> createState() =>
      _CraftsmenListScreenState();
}

class _CraftsmenListScreenState extends ConsumerState<CraftsmenListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic> _activeFilters = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(craftsmenProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    final filters = Map<String, dynamic>.from(_activeFilters);
    if (query.isNotEmpty) {
      filters['q'] = query;
    } else {
      filters.remove('q');
    }
    _activeFilters = filters;
    ref.read(craftsmenProvider.notifier).applyFilters(filters);
  }

  void _openFilters() {
    CraftsmanFiltersSheet.show(
      context,
      initialFilters: _activeFilters,
      onApply: (filters) {
        setState(() => _activeFilters = filters);
        // Preserve search query if any
        final query = _searchController.text.trim();
        if (query.isNotEmpty) filters['q'] = query;
        ref.read(craftsmenProvider.notifier).applyFilters(filters);
      },
    );
  }

  bool get _hasActiveFilters =>
      _activeFilters.entries
          .where((e) => e.key != 'q' && e.value != null)
          .isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(craftsmenProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'الحرفيون',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Search + Filter bar
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن حرفي...',
                          hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        onSubmitted: _onSearch,
                        onChanged: (v) {
                          if (v.isEmpty) _onSearch('');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openFilters,
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: _hasActiveFilters
                            ? AppColors.accent
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: _hasActiveFilters
                                ? Colors.white
                                : AppColors.primary,
                          ),
                          if (_hasActiveFilters)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active filters chips
            if (_hasActiveFilters)
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'تصفية نشطة:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _activeFilters.entries
                              .where((e) =>
                                  e.key != 'q' && e.value != null)
                              .map((e) => Padding(
                                    padding:
                                        const EdgeInsets.only(left: 6),
                                    child: Chip(
                                      label: Text(
                                        _filterLabel(e.key, e.value),
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      backgroundColor:
                                          AppColors.primary.withOpacity(0.1),
                                      side: const BorderSide(
                                          color: AppColors.primary,
                                          width: 0.5),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity:
                                          VisualDensity.compact,
                                      deleteIcon: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: AppColors.primary),
                                      onDeleted: () {
                                        setState(() {
                                          _activeFilters.remove(e.key);
                                        });
                                        ref
                                            .read(craftsmenProvider.notifier)
                                            .applyFilters(_activeFilters);
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _activeFilters = {});
                        ref
                            .read(craftsmenProvider.notifier)
                            .clearFilters();
                      },
                      style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8)),
                      child: const Text(
                        'مسح الكل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Results count
            if (!state.isLoading && state.craftsmen.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${state.total} حرفي متاح',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: state.isLoading
                  ? _buildShimmer()
                  : state.error != null && state.craftsmen.isEmpty
                      ? _buildError(state.error!)
                      : state.craftsmen.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.handyman_outlined,
                              title: 'لا يوجد حرفيون',
                              subtitle:
                                  'جرّب تغيير معايير البحث أو التصفية',
                              actionLabel: 'إعادة ضبط',
                              onAction: () {
                                setState(() => _activeFilters = {});
                                _searchController.clear();
                                ref
                                    .read(craftsmenProvider.notifier)
                                    .clearFilters();
                              },
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () => ref
                                  .read(craftsmenProvider.notifier)
                                  .loadCraftsmen(),
                              child: GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                    16, 8, 16, 32),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: state.craftsmen.length +
                                    (state.isLoadingMore ? 2 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= state.craftsmen.length) {
                                    return _shimmerCard();
                                  }
                                  return CraftsmanCard(
                                    craftsman: state.craftsmen[index]
                                        as Map<String, dynamic>,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ في تحميل البيانات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(craftsmenProvider.notifier).loadCraftsmen(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _shimmerCard(),
    );
  }

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14, width: 100, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 70, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 90, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(String key, dynamic value) {
    switch (key) {
      case 'specialty':
        const m = {
          'plumber': 'سباك',
          'electrician': 'كهربائي',
          'carpenter': 'نجار',
          'painter': 'دهان',
          'mason': 'بناء',
          'acTech': 'تكييف',
          'welder': 'حداد',
          'cleaner': 'نظافة',
          'other': 'أخرى',
        };
        return m[value] ?? value.toString();
      case 'wilaya':
        return value.toString();
      case 'minRating':
        return '★ ${value.toString()}+';
      case 'isAvailable':
        return value == true ? 'متاح' : 'غير متاح';
      default:
        return value.toString();
    }
  }
}
