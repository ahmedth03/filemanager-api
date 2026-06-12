import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../craftsmen/domain/entities/craftsman.dart';
import '../../../listings/domain/entities/listing.dart';
import '../providers/profile_provider.dart';

class MyFavoritesScreen extends ConsumerStatefulWidget {
  const MyFavoritesScreen({super.key});

  @override
  ConsumerState<MyFavoritesScreen> createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends ConsumerState<MyFavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Reload favorites when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider.notifier).loadFavorites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'المفضلة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                text:
                    'حرفيون (${profileState.favoriteCraftsmen.length})',
              ),
              Tab(
                text: 'عقارات (${profileState.favoriteListings.length})',
              ),
            ],
          ),
        ),
        body: profileState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  // Craftsmen tab
                  _CraftsmenFavoritesTab(
                    craftsmen: profileState.favoriteCraftsmen,
                    onRemove: (id) => ref
                        .read(profileNotifierProvider.notifier)
                        .removeFavoriteCraftsman(id),
                  ),
                  // Listings tab
                  _ListingsFavoritesTab(
                    listings: profileState.favoriteListings,
                    onRemove: (id) => ref
                        .read(profileNotifierProvider.notifier)
                        .removeFavoriteListing(id),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Craftsmen favorites tab
// ---------------------------------------------------------------------------

class _CraftsmenFavoritesTab extends StatelessWidget {
  const _CraftsmenFavoritesTab({
    required this.craftsmen,
    required this.onRemove,
  });

  final List<Craftsman> craftsmen;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (craftsmen.isEmpty) {
      return const _EmptyFavorites(
        icon: Icons.handyman_outlined,
        message: 'لا يوجد حرفيون في مفضلتك',
        subtitle: 'تصفح الحرفيين وأضف المفضلين منهم إلى هنا',
        actionLabel: 'تصفح الحرفيين',
        actionRoute: RouteNames.pathCraftsmenList,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: craftsmen.length,
        itemBuilder: (context, index) => _CraftsmanFavoriteCard(
          craftsman: craftsmen[index],
          onRemove: () => onRemove(craftsmen[index].id),
        ),
      ),
    );
  }
}

class _CraftsmanFavoriteCard extends StatelessWidget {
  const _CraftsmanFavoriteCard({
    required this.craftsman,
    required this.onRemove,
  });

  final Craftsman craftsman;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context
            .push('${RouteNames.pathCraftsmenList}/${craftsman.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: craftsman.avatar != null
                    ? CachedNetworkImageProvider(craftsman.avatar!)
                    : null,
                child: craftsman.avatar == null
                    ? Text(
                        craftsman.name.isNotEmpty
                            ? craftsman.name[0]
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontFamily: 'Cairo',
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          craftsman.name,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (craftsman.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 14, color: AppColors.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      craftsman.specialty.labelAr,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 12, color: AppColors.starFilled),
                        const SizedBox(width: 2),
                        Text(
                          craftsman.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          craftsman.wilaya,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                onPressed: () => _confirmRemove(context),
                icon: const Icon(Icons.favorite,
                    color: Colors.red, size: 22),
                tooltip: 'إزالة من المفضلة',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'إزالة من المفضلة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          content: Text(
            'هل تريد إزالة ${craftsman.name} من مفضلتك؟',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRemove();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              child: const Text('إزالة',
                  style: TextStyle(
                      fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Listings favorites tab
// ---------------------------------------------------------------------------

class _ListingsFavoritesTab extends StatelessWidget {
  const _ListingsFavoritesTab({
    required this.listings,
    required this.onRemove,
  });

  final List<Listing> listings;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const _EmptyFavorites(
        icon: Icons.apartment_outlined,
        message: 'لا يوجد عقارات في مفضلتك',
        subtitle: 'تصفح العقارات وأضف المفضلة منها إلى هنا',
        actionLabel: 'تصفح العقارات',
        actionRoute: RouteNames.pathListingsList,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        itemBuilder: (context, index) => _ListingFavoriteCard(
          listing: listings[index],
          onRemove: () => onRemove(listings[index].id),
        ),
      ),
    );
  }
}

class _ListingFavoriteCard extends StatelessWidget {
  const _ListingFavoriteCard({
    required this.listing,
    required this.onRemove,
  });

  final Listing listing;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final String priceText =
        '${listing.price.toInt()} دج/${listing.priceUnit.labelAr}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context
            .push('${RouteNames.pathListingsList}/${listing.id}'),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(14),
              ),
              child: listing.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: listing.images.first.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${listing.city}، ${listing.wilaya}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Remove button
            IconButton(
              onPressed: () => _confirmRemove(context),
              icon: const Icon(Icons.favorite,
                  color: Colors.red, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.primary.withOpacity(0.08),
      child: const Icon(Icons.apartment,
          size: 36, color: AppColors.primary),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'إزالة من المفضلة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'هل تريد إزالة هذا العقار من مفضلتك؟',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRemove();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              child: const Text('إزالة',
                  style: TextStyle(
                      fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty favorites state
// ---------------------------------------------------------------------------

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({
    required this.icon,
    required this.message,
    required this.subtitle,
    required this.actionLabel,
    required this.actionRoute,
  });

  final IconData icon;
  final String message;
  final String subtitle;
  final String actionLabel;
  final String actionRoute;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(actionRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
