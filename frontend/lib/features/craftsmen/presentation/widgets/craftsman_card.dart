import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

class CraftsmanCard extends StatelessWidget {
  const CraftsmanCard({super.key, required this.craftsman});

  final Map<String, dynamic> craftsman;

  @override
  Widget build(BuildContext context) {
    final String id =
        (craftsman['_id'] ?? craftsman['id'] ?? '').toString();
    final String name =
        (craftsman['name'] ?? craftsman['businessName'] ?? '').toString();
    final String specialty =
        _specialtyLabel(craftsman['specialty']?.toString() ?? '');
    final double rating =
        (craftsman['rating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount = (craftsman['reviewCount'] as int?) ?? 0;
    final String wilaya = (craftsman['wilaya'] ?? '').toString();
    final String city = (craftsman['city'] ?? '').toString();
    final bool isAvailable = craftsman['isAvailable'] as bool? ?? false;
    final bool isVerified = craftsman['isVerified'] as bool? ?? false;
    final String? avatar = craftsman['avatar']?.toString();
    final String? portfolioThumb =
        (craftsman['portfolio'] as List?)?.isNotEmpty == true
            ? ((craftsman['portfolio'][0]?['imageUrl'] ?? avatar)
                    ?.toString())
            : avatar;

    return GestureDetector(
      onTap: () => context.push('${RouteNames.pathCraftsmenList}/$id'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: portfolioThumb != null
                      ? CachedNetworkImage(
                          imageUrl: portfolioThumb,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _avatarFallback(name, 120),
                          errorWidget: (_, __, ___) =>
                              _avatarFallback(name, 120),
                        )
                      : _avatarFallback(name, 120),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _AvailabilityBadge(isAvailable: isAvailable),
                ),
                if (isVerified)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified,
                          color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    specialty,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: rating,
                        itemBuilder: (_, __) => const Icon(
                          Icons.star_rounded,
                          color: AppColors.starFilled,
                        ),
                        itemCount: 5,
                        itemSize: 14,
                        unratedColor: AppColors.starEmpty,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewCount)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          city.isNotEmpty ? '$city، $wilaya' : wilaya,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name, double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.08),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  String _specialtyLabel(String key) {
    const map = {
      'plumber': 'سباك',
      'electrician': 'كهربائي',
      'carpenter': 'نجار',
      'painter': 'دهان',
      'mason': 'بناء',
      'acTech': 'تقني تكييف',
      'welder': 'حداد',
      'cleaner': 'عامل نظافة',
      'other': 'أخرى',
    };
    return map[key] ?? key;
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.isAvailable});
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.success : AppColors.textSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'متاح' : 'غير متاح',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
