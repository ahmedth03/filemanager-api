import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../providers/listings_provider.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_filters.dart';

class ListingsListScreen extends ConsumerStatefulWidget {
  const ListingsListScreen({super.key});

  @override
  ConsumerState<ListingsListScreen> createState() =>
      _ListingsListScreenState();
}

class _ListingsListScreenState extends ConsumerState<ListingsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic> _activeFilters = {};
  bool _isGridView = true;

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
      ref.read(listingsProvider.notifier).loadMore();
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
    ref.read(listingsProvider.notifier).applyFilters(filters);
  }

  void _openFilters() {
    ListingFiltersSheet.show(
      context,
      initialFilters: _activeFilters,
      onApply: (filters) {
        setState(() => _activeFilters = filters);
        final query = _searchController.text.trim();
        if (query.isNotEmpty) filters['q'] = query;
        ref.read(listingsProvider.notifier).applyFilters(filters);
      },
    );
  }

  bool get _hasActiveFilters =>
      _activeFilters.entries
          .where((e) => e.key != 'q' && e.value != null)
          .isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'العقارات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
                color: Colors.white,
              ),
              onPressed: () =>
                  setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'عرض قائمة' : 'عرض شبكي',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search + filter bar
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
                          hintText: 'ابحث عن عقار...',
                          hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
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

            // Active filters
            if (_hasActiveFilters)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
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
                                      visualDensity: VisualDensity.compact,
                                      deleteIcon: const Icon(Icons.close,
                                          size: 14, color: AppColors.primary),
                                      onDeleted: () {
                                        setState(() =>
                                            _activeFilters.remove(e.key));
                                        ref
                                            .read(listingsProvider.notifier)
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
                            .read(listingsProvider.notifier)
                            .clearFilters();
                      },
                      style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8)),
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
            if (!state.isLoading && state.listings.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${state.total} عقار متاح',
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
                  : state.error != null && state.listings.isEmpty
                      ? _buildError(state.error!)
                      : state.listings.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.apartment_outlined,
                              title: 'لا توجد عقارات',
                              subtitle: 'جرّب تغيير معايير البحث أو التصفية',
                              actionLabel: 'إعادة ضبط',
                              onAction: () {
                                setState(() => _activeFilters = {});
                                _searchController.clear();
                                ref
                                    .read(listingsProvider.notifier)
                                    .clearFilters();
                              },
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () => ref
                                  .read(listingsProvider.notifier)
                                  .loadListings(),
                              child: _isGridView
                                  ? _buildGrid(state)
                                  : _buildList(state),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(ListingsState state) {
    final totalItems = state.listings.length +
        (state.isLoadingMore ? 2 : 0);
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index >= state.listings.length) return _shimmerCard();
        return ListingCard(
          listing: state.listings[index] as Map<String, dynamic>,
        );
      },
    );
  }

  Widget _buildList(ListingsState state) {
    final totalItems = state.listings.length +
        (state.isLoadingMore ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index >= state.listings.length) {
          return _shimmerListItem();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ListingCard(
            listing: state.listings[index] as Map<String, dynamic>,
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
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
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 60, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 130, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 90, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 100, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerListItem() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              ),
            ),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(listingsProvider.notifier).loadListings(),
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

  String _filterLabel(String key, dynamic value) {
    switch (key) {
      case 'type':
        const m = {
          'apartment': 'شقة',
          'house': 'منزل',
          'villa': 'فيلا',
          'studio': 'استوديو',
          'shop': 'محل',
          'land': 'أرض',
        };
        return m[value] ?? value.toString();
      case 'transactionType':
        return value == 'sale' ? 'للبيع' : 'للإيجار';
      case 'wilaya':
        return value.toString();
      case 'minPrice':
        return 'من ${value}دج';
      case 'maxPrice':
        return 'إلى ${value}دج';
      case 'minRooms':
        return '${value}+ غرف';
      case 'furnished':
        return 'مفروشة';
      case 'parking':
        return 'موقف';
      case 'elevator':
        return 'مصعد';
      default:
        return value.toString();
    }
  }
}
