import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/listings_provider.dart';
import '../widgets/image_carousel.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/rating_bar_widget.dart';
import '../../../../shared/widgets/network_image_widget.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../reviews/presentation/providers/reviews_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));
    final auth = ref.watch(authStateProvider);

    return listingAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('خطأ في تحميل الإعلان: $e')),
      ),
      data: (listing) {
        final images = (listing['images'] as List?) ?? [];
        final owner = listing['owner'] as Map<String, dynamic>? ?? {};
        final price = double.tryParse(listing['price']?.toString() ?? '0') ?? 0;

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primary,
                actions: [
                  IconButton(
                    icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                    onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: images.isNotEmpty
                      ? ImageCarousel(images: images.map((i) => i['url'] as String).toList())
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.apartment, size: 80, color: AppColors.onSurfaceVariant),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${AppFormatters.formatPrice(price)} / ${listing['pricePeriod'] ?? 'شهري'}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          _TypeBadge(type: listing['type'] ?? ''),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        listing['title'] ?? '',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.accent, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${listing['city'] ?? ''}, ${listing['wilaya'] ?? ''}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stats Row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outline.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(icon: Icons.bed, label: '${listing['rooms']} غرف'),
                            _StatItem(icon: Icons.bathroom, label: '${listing['bathrooms']} حمام'),
                            if (listing['area'] != null)
                              _StatItem(icon: Icons.square_foot, label: '${listing['area']} م²'),
                            if (listing['floor'] != null)
                              _StatItem(icon: Icons.layers, label: 'ط. ${listing['floor']}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Features
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (listing['isFurnished'] == true) _FeatureChip(label: 'مفروش', icon: Icons.chair),
                          if (listing['hasParking'] == true) _FeatureChip(label: 'مواقف', icon: Icons.local_parking),
                          if (listing['hasElevator'] == true) _FeatureChip(label: 'مصعد', icon: Icons.elevator),
                          if (listing['hasBalcony'] == true) _FeatureChip(label: 'شرفة', icon: Icons.balcony),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (listing['description'] != null && listing['description'].isNotEmpty) ...[
                        const Text('الوصف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          listing['description'],
                          style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Owner Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outline.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: owner['avatarUrl'] != null
                                  ? NetworkImage(owner['avatarUrl']) : null,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: owner['avatarUrl'] == null
                                  ? Text(
                                      '${owner['firstName']?[0] ?? '؟'}',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Text('مالك العقار', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (auth.isAuthenticated && auth.user?.id != owner['id'])
                              TextButton.icon(
                                onPressed: () => context.push('/chats/new?recipientId=${owner['id']}&listingId=${widget.listingId}'),
                                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                label: const Text('دردشة'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reviews Section
                      const Text('التقييمات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Consumer(builder: (ctx, ref, _) {
                        final reviewsAsync = ref.watch(listingReviewsProvider(widget.listingId));
                        return reviewsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox(),
                          data: (data) {
                            final reviews = (data['reviews'] as List?) ?? [];
                            if (reviews.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('لا توجد تقييمات بعد', style: TextStyle(color: AppColors.textSecondary)),
                              );
                            }
                            return Column(
                              children: reviews
                                  .take(3)
                                  .map((r) => ReviewCard(review: r))
                                  .toList(),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: auth.isAuthenticated && auth.user?.id != owner['id']
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'اتصال',
                          variant: AppButtonVariant.outline,
                          icon: Icons.phone,
                          onPressed: () async {
                            final phone = owner['phone'];
                            if (phone != null) await launchUrl(Uri.parse('tel:$phone'));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'دردشة',
                          icon: Icons.chat_bubble_outline,
                          onPressed: () => context.push('/chats/new?recipientId=${owner['id']}&listingId=${widget.listingId}'),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ],
  );
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FeatureChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label, style: const TextStyle(fontSize: 12)),
    avatar: Icon(icon, size: 16, color: AppColors.primary),
    backgroundColor: AppColors.primary.withOpacity(0.08),
    side: BorderSide.none,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  String _typeLabel(String t) {
    const map = {
      'APARTMENT': 'شقة', 'HOUSE': 'منزل', 'STUDIO': 'استوديو',
      'VILLA': 'فيلا', 'COMMERCIAL': 'تجاري',
    };
    return map[t] ?? t;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: Text(_typeLabel(type), style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}
