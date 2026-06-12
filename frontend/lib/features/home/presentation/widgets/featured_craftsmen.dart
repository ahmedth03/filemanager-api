import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../providers/home_provider.dart';
import '../../../craftsmen/domain/entities/craftsman.dart';

class FeaturedCraftsmen extends ConsumerWidget {
  const FeaturedCraftsmen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final craftsmenAsync = ref.watch(featuredCraftsmenProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الحرفيون المميزون',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.pathCraftsmenList),
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: craftsmenAsync.when(
            loading: () => _buildShimmerList(),
            error: (e, _) => _buildError(context, ref),
            data: (craftsmen) => craftsmen.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: craftsmen.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _CraftsmanCard(craftsman: craftsmen[index]),
                      );
                    },
                  ),
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
        child: _ShimmerCard(),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => ref.refresh(featuredCraftsmenProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'لا يوجد حرفيون مميزون حالياً',
        style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo'),
      ),
    );
  }
}

class _CraftsmanCard extends StatelessWidget {
  const _CraftsmanCard({required this.craftsman});
  final Craftsman craftsman;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('${RouteNames.pathCraftsmenList}/${craftsman.id}');
      },
      child: Container(
        width: 155,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                if (craftsman.isVerified)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                craftsman.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              craftsman.specialty.labelAr,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 6),
            RatingBar.builder(
              initialRating: craftsman.rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 14,
              ignoreGestures: true,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: AppColors.starFilled),
              onRatingUpdate: (_) {},
            ),
            const SizedBox(height: 4),
            Text(
              craftsman.wilaya,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: craftsman.isAvailable
                    ? AppColors.successLight
                    : AppColors.errorLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                craftsman.isAvailable ? 'متاح' : 'غير متاح',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: craftsman.isAvailable
                      ? AppColors.success
                      : AppColors.error,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      height: 210,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
