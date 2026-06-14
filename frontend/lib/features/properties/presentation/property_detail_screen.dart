import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/properties_provider.dart';
import '../data/property_model.dart';
import '../../favorites/providers/favorites_provider.dart';

class PropertyDetailScreen extends ConsumerWidget {
  final String listingId;

  const PropertyDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyDetailProvider(listingId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: propertyAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(
              backgroundColor: const Color(0xFF1B4F72),
              foregroundColor: Colors.white),
          body: const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF1B4F72))),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B4F72),
            foregroundColor: Colors.white,
            title: const Text('خطأ',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: Color(0xFFE74C3C)),
                const SizedBox(height: 16),
                Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Cairo')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(propertyDetailProvider(listingId)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F72),
                      foregroundColor: Colors.white),
                  child: const Text('إعادة المحاولة',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),
        ),
        data: (property) => _PropertyDetailBody(property: property),
      ),
    );
  }
}

class _PropertyDetailBody extends ConsumerStatefulWidget {
  final PropertyModel property;

  const _PropertyDetailBody({required this.property});

  @override
  ConsumerState<_PropertyDetailBody> createState() =>
      _PropertyDetailBodyState();
}

class _PropertyDetailBodyState
    extends ConsumerState<_PropertyDetailBody> {
  int _imageIndex = 0;

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون دج';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ألف دج';
    }
    return '${price.toStringAsFixed(0)} دج';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'APARTMENT':
        return 'شقة';
      case 'HOUSE':
        return 'بيت';
      case 'STUDIO':
        return 'استوديو';
      case 'VILLA':
        return 'فيلا';
      case 'COMMERCIAL':
        return 'تجاري';
      default:
        return type;
    }
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'monthly':
        return '/شهر';
      case 'yearly':
        return '/سنة';
      case 'daily':
        return '/يوم';
      default:
        return '';
    }
  }

  Future<void> _callOwner(String? phone) async {
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final favAsync =
        ref.watch(isListingFavoritedProvider(property.id));
    final images = property.images;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF1B4F72),
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: images.isNotEmpty ? 260 : 0,
            title: Text(
              property.title,
              style: const TextStyle(
                  fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              favAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (isFav) => IconButton(
                  icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white),
                  onPressed: () => ref
                      .read(favoritesRepositoryProvider)
                      .toggleFavorite(listingId: property.id)
                      .then((_) => ref.invalidate(
                          isListingFavoritedProvider(property.id))),
                ),
              ),
            ],
            flexibleSpace: images.isNotEmpty
                ? FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (i) =>
                              setState(() => _imageIndex = i),
                          itemBuilder: (_, i) => Image.network(
                            images[i].url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFDEE2E6),
                              child: const Icon(Icons.apartment_rounded,
                                  size: 60, color: Color(0xFF6C757D)),
                            ),
                          ),
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (i) => AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: i == _imageIndex ? 18 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    color: i == _imageIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and type
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFF39C12).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _typeLabel(property.type),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFFF39C12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Text(
                    '${_formatPrice(property.price)}${_periodLabel(property.pricePeriod)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: Color(0xFF1B4F72),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Color(0xFF6C757D)),
                      const SizedBox(width: 4),
                      Text(
                        '${property.city}، ${property.wilaya}',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFF6C757D),
                            fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Specs chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (property.rooms > 0)
                        _SpecChip(
                            icon: Icons.bed_outlined,
                            label: '${property.rooms} غرف'),
                      if (property.bathrooms > 0)
                        _SpecChip(
                            icon: Icons.bathtub_outlined,
                            label: '${property.bathrooms} حمامات'),
                      if (property.area != null)
                        _SpecChip(
                            icon: Icons.square_foot_outlined,
                            label: '${property.area!.toStringAsFixed(0)} م²'),
                      if (property.isFurnished)
                        _SpecChip(
                            icon: Icons.chair_outlined,
                            label: 'مفروش'),
                      if (property.hasParking)
                        _SpecChip(
                            icon: Icons.local_parking_outlined,
                            label: 'موقف'),
                      if (property.hasElevator)
                        _SpecChip(
                            icon: Icons.elevator_outlined,
                            label: 'مصعد'),
                      if (property.hasBalcony)
                        _SpecChip(
                            icon: Icons.balcony_outlined,
                            label: 'شرفة'),
                    ],
                  ),
                  if (property.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'الوصف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      property.description,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Color(0xFF6C757D),
                          height: 1.6),
                    ),
                  ],
                  if (property.owner != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'المالك',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              const Color(0xFF1B4F72).withOpacity(0.12),
                          backgroundImage:
                              property.owner!.avatarUrl != null
                                  ? NetworkImage(property.owner!.avatarUrl!)
                                  : null,
                          child: property.owner!.avatarUrl == null
                              ? Text(
                                  property.owner!.fullName.isNotEmpty
                                      ? property.owner!.fullName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Color(0xFF1B4F72),
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          property.owner!.fullName,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _callOwner(property.owner?.avatarUrl),
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: const Text('اتصال',
                              style: TextStyle(fontFamily: 'Cairo')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F72),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .push('/reviews/add?listingId=${property.id}'),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('إضافة تقييم',
                        style: TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B4F72),
                      side: const BorderSide(color: Color(0xFF1B4F72)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4F72).withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1B4F72)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Color(0xFF1B4F72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
