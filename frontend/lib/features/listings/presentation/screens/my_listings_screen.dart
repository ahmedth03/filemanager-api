import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../providers/listings_provider.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myListingsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            'إعلاناتي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/create-listing'),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'إعلان جديد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: state.isLoading
            ? _buildShimmer()
            : state.error != null && state.listings.isEmpty
                ? _buildError(context, ref, state.error!)
                : state.listings.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.apartment_outlined,
                        title: 'لا توجد إعلانات بعد',
                        subtitle: 'انشر إعلانك الأول الآن ليراه الجميع',
                        actionLabel: 'إضافة إعلان',
                        onAction: () => context.push('/create-listing'),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () =>
                            ref.read(myListingsProvider.notifier).load(),
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: state.listings.length,
                          itemBuilder: (context, i) {
                            return _MyListingItem(
                              listing: state.listings[i]
                                  as Map<String, dynamic>,
                              onDelete: () => _confirmDelete(
                                context,
                                ref,
                                state.listings[i] as Map<String, dynamic>,
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> listing,
  ) async {
    final id = (listing['_id'] ?? listing['id'] ?? '').toString();
    final title = (listing['title'] ?? 'الإعلان').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل أنت متأكد من حذف "$title"؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (confirmed == true) {
      final ok = await ref.read(myListingsProvider.notifier).delete(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'تم حذف الإعلان بنجاح' : 'فشل الحذف، حاول مجدداً',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor:
                ok ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildError(
      BuildContext context, WidgetRef ref, String error) {
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
              'تعذّر تحميل إعلاناتك',
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
                  ref.read(myListingsProvider.notifier).load(),
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
}

// ---------------------------------------------------------------------------
// My listing row item
// ---------------------------------------------------------------------------
class _MyListingItem extends StatelessWidget {
  const _MyListingItem({
    required this.listing,
    required this.onDelete,
  });

  final Map<String, dynamic> listing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final id = (listing['_id'] ?? listing['id'] ?? '').toString();
    final title = (listing['title'] ?? '').toString();
    final price = (listing['price'] as num?)?.toDouble() ?? 0;
    final priceUnit =
        _priceUnitLabel(listing['priceUnit']?.toString() ?? 'perMonth');
    final wilaya = (listing['wilaya'] ?? '').toString();
    final city = (listing['city'] ?? '').toString();
    final isActive = listing['isActive'] as bool? ?? true;
    final status = listing['status']?.toString();
    final type = _typeLabel(listing['type']?.toString() ?? '');
    final images = (listing['images'] as List<dynamic>?) ?? [];
    String? coverUrl;
    if (images.isNotEmpty) {
      final cover = images.firstWhere(
        (img) =>
            (img as Map<String, dynamic>?)?['isCover'] == true,
        orElse: () => images.first,
      );
      coverUrl =
          (cover as Map<String, dynamic>?)?['url']?.toString() ??
              cover?.toString();
    }

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
        onTap: () =>
            context.push('${RouteNames.pathListingsList}/$id'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _imagePlaceholder(),
                        errorWidget: (_, __, ___) =>
                            _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                            status: status, isActive: isActive),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$type • ${_formatPrice(price)} دج / $priceUnit',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          city.isNotEmpty
                              ? '$city، $wilaya'
                              : wilaya,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          label: 'تعديل',
                          color: AppColors.primary,
                          onTap: () => context
                              .push('/create-listing?editId=$id'),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.delete_outline,
                          label: 'حذف',
                          color: AppColors.error,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.primary.withOpacity(0.07),
      child: const Icon(Icons.apartment_outlined,
          size: 32, color: AppColors.primary),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}م';
    }
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}ك';
    return price.toStringAsFixed(0);
  }

  String _typeLabel(String key) {
    const map = {
      'apartment': 'شقة',
      'house': 'منزل',
      'villa': 'فيلا',
      'studio': 'استوديو',
      'shop': 'محل',
      'land': 'أرض',
    };
    return map[key] ?? key;
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
  final String? status;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        color = AppColors.success;
        label = 'نشط';
        break;
      case 'rented':
        color = AppColors.info;
        label = 'مُؤجَّر';
        break;
      case 'sold':
        color = AppColors.info;
        label = 'مُباع';
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
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
