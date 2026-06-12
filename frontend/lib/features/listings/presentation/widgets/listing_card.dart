import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.showStatus = false,
  });

  final Map<String, dynamic> listing;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final String id =
        (listing['_id'] ?? listing['id'] ?? '').toString();
    final String title = (listing['title'] ?? '').toString();
    final double price = (listing['price'] as num?)?.toDouble() ?? 0;
    final String priceUnit = _priceUnitLabel(
        listing['priceUnit']?.toString() ?? 'perMonth');
    final String wilaya = (listing['wilaya'] ?? '').toString();
    final String city = (listing['city'] ?? '').toString();
    final int? rooms = listing['rooms'] as int?;
    final double? area = (listing['area'] as num?)?.toDouble();
    final String type =
        _typeLabel(listing['type']?.toString() ?? '');
    final String transactionType =
        _transactionLabel(listing['transactionType']?.toString() ?? 'rent');
    final String? status = listing['status']?.toString();
    final bool isActive = listing['isActive'] as bool? ?? true;

    // Get cover image
    final images = (listing['images'] as List<dynamic>?) ?? [];
    String? coverUrl;
    if (images.isNotEmpty) {
      // Find cover image or use first
      final cover = images.firstWhere(
        (img) => (img as Map<String, dynamic>?)?['isCover'] == true,
        orElse: () => images.first,
      );
      coverUrl =
          (cover as Map<String, dynamic>?)?['url']?.toString() ??
              cover?.toString();
    }

    return GestureDetector(
      onTap: () => context.push('${RouteNames.pathListingsList}/$id'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with price badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imagePlaceholder(type),
                          errorWidget: (_, __, ___) =>
                              _imagePlaceholder(type),
                        )
                      : _imagePlaceholder(type),
                ),
                // Price badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_formatPrice(price)} دج / $priceUnit',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Transaction type badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: transactionType == 'للإيجار'
                          ? AppColors.primary
                          : AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      transactionType,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Status badge if showStatus
                if (showStatus && status != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: _StatusBadge(status: status, isActive: isActive),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Details row
                  Row(
                    children: [
                      if (rooms != null) ...[
                        const Icon(Icons.bed_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '$rooms غرف',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (area != null) ...[
                        const Icon(Icons.square_foot,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${area.toStringAsFixed(0)} م²',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          city.isNotEmpty ? '$city، $wilaya' : wilaya,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(String type) {
    return Container(
      height: 140,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.07),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apartment_outlined,
              size: 40, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            type,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}م';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}ألف';
    return price.toStringAsFixed(0);
  }

  String _typeLabel(String key) {
    const map = {
      'apartment': 'شقة',
      'house': 'منزل',
      'villa': 'فيلا',
      'studio': 'استوديو',
      'shop': 'محل تجاري',
      'land': 'أرض',
    };
    return map[key] ?? key;
  }

  String _transactionLabel(String key) {
    return key == 'sale' ? 'للبيع' : 'للإيجار';
  }

  String _priceUnitLabel(String key) {
    const map = {
      'perMonth': 'شهر',
      'perYear': 'سنة',
      'total': 'إجمالي',
    };
    return map[key] ?? key;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isActive});
  final String status;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppColors.success;
        label = 'نشط';
        break;
      case 'rented':
      case 'sold':
        color = AppColors.info;
        label = status == 'sold' ? 'مُباع' : 'مُؤجَّر';
        break;
      case 'draft':
        color = AppColors.textSecondary;
        label = 'مسودة';
        break;
      default:
        color = isActive ? AppColors.success : AppColors.textSecondary;
        label = isActive ? 'نشط' : 'غير نشط';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
