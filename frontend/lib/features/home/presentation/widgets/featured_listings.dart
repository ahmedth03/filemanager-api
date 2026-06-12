import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../providers/home_provider.dart';
import '../../../listings/domain/entities/listing.dart';

class FeaturedListings extends ConsumerWidget {
  const FeaturedListings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(featuredListingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'عقارات للكراء',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.pathListingsList),
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: listingsAsync.when(
            loading: () => _buildShimmerList(),
            error: (e, _) => _buildError(context, ref),
            data: (listings) {
              // Show only rent listings in this section
              final rentListings = listings
                  .where((l) => l.transactionType == TransactionType.rent)
                  .toList();
              final displayList =
                  rentListings.isEmpty ? listings : rentListings;
              return displayList.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _ListingCard(listing: displayList[index]),
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Container(
          width: 200,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => ref.refresh(featuredListingsProvider),
        icon: const Icon(Icons.refresh),
        label: const Text(
          'إعادة المحاولة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'لا توجد عقارات مميزة حالياً',
        style: TextStyle(
            color: AppColors.textSecondary, fontFamily: 'Cairo'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Listing card
// ---------------------------------------------------------------------------

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final String priceFormatted =
        '${listing.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} دج';

    return GestureDetector(
      onTap: () =>
          context.push('${RouteNames.pathListingsList}/${listing.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder / header
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: listing.images.isNotEmpty
                      ? Image.network(
                          listing.images.first.url,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(listing.type),
                        )
                      : _imagePlaceholder(listing.type),
                ),
                // Transaction type badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: listing.transactionType == TransactionType.rent
                          ? AppColors.primary
                          : AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      listing.transactionType.labelAr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${listing.city}، ${listing.wilaya}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Price
                  Text(
                    '$priceFormatted / ${listing.priceUnit.labelAr}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Details row
                  if (listing.rooms != null || listing.area != null)
                    Row(
                      children: [
                        if (listing.rooms != null) ...[
                          const Icon(Icons.bed_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${listing.rooms}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (listing.area != null) ...[
                          const Icon(Icons.square_foot_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${listing.area!.toInt()} م²',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
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

  Widget _imagePlaceholder(ListingType type) {
    IconData icon;
    Color color;
    switch (type) {
      case ListingType.apartment:
        icon = Icons.apartment;
        color = AppColors.primary;
        break;
      case ListingType.house:
        icon = Icons.house;
        color = AppColors.success;
        break;
      case ListingType.villa:
        icon = Icons.villa;
        color = AppColors.accent;
        break;
      case ListingType.studio:
        icon = Icons.studio;
        color = AppColors.info;
        break;
      case ListingType.shop:
        icon = Icons.store;
        color = AppColors.warning;
        break;
      case ListingType.land:
        icon = Icons.landscape;
        color = AppColors.textSecondary;
        break;
    }
    return Container(
      height: 120,
      width: double.infinity,
      color: color.withOpacity(0.1),
      child: Center(
        child: Icon(icon, size: 48, color: color.withOpacity(0.5)),
      ),
    );
  }
}
