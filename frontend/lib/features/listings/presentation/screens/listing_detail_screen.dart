import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../providers/listings_provider.dart';
import '../widgets/image_carousel.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(listingDetailProvider(listingId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: detailAsync.when(
          loading: () => const _LoadingBody(),
          error: (e, __) => _ErrorBody(message: e.toString()),
          data: (listing) => _ListingBody(listing: listing),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main body
// ---------------------------------------------------------------------------
class _ListingBody extends StatefulWidget {
  const _ListingBody({required this.listing});
  final Map<String, dynamic> listing;

  @override
  State<_ListingBody> createState() => _ListingBodyState();
}

class _ListingBodyState extends State<_ListingBody> {
  bool _isFavorite = false;

  String get _id =>
      (widget.listing['_id'] ?? widget.listing['id'] ?? '').toString();
  String get _title => (widget.listing['title'] ?? '').toString();
  String get _description =>
      (widget.listing['description'] ?? '').toString();
  double get _price =>
      (widget.listing['price'] as num?)?.toDouble() ?? 0;
  String get _priceUnit =>
      _priceUnitLabel(widget.listing['priceUnit']?.toString() ?? 'perMonth');
  String get _type =>
      _typeLabel(widget.listing['type']?.toString() ?? '');
  String get _transactionType => _transactionLabel(
      widget.listing['transactionType']?.toString() ?? 'rent');
  String get _wilaya => (widget.listing['wilaya'] ?? '').toString();
  String get _city => (widget.listing['city'] ?? '').toString();
  String get _address => (widget.listing['address'] ?? '').toString();
  int? get _rooms => widget.listing['rooms'] as int?;
  int? get _bathrooms => widget.listing['bathrooms'] as int?;
  double? get _area => (widget.listing['area'] as num?)?.toDouble();
  int? get _floor => widget.listing['floor'] as int?;
  int? get _totalFloors => widget.listing['totalFloors'] as int?;
  List<dynamic> get _amenities =>
      (widget.listing['amenities'] as List<dynamic>?) ?? [];
  List<dynamic> get _images =>
      (widget.listing['images'] as List<dynamic>?) ?? [];
  Map<String, dynamic> get _owner =>
      (widget.listing['owner'] as Map<String, dynamic>?) ??
      (widget.listing['user'] as Map<String, dynamic>?) ??
      {};
  String? get _contactPhone =>
      (widget.listing['contactPhone'] ?? _owner['phone'])?.toString();
  List<dynamic> get _reviews =>
      (widget.listing['reviews'] as List<dynamic>?) ?? [];

  List<String> get _imageUrls {
    return _images
        .map((img) {
          if (img is Map<String, dynamic>) {
            return (img['url'] ?? img['imageUrl'] ?? '').toString();
          }
          return img.toString();
        })
        .where((u) => u.isNotEmpty)
        .toList();
  }

  void _toggleFavorite() => setState(() => _isFavorite = !_isFavorite);

  Future<void> _callPhone() async {
    if (_contactPhone == null) return;
    final raw = _contactPhone!.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$raw');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openChat() {
    final ownerId = (_owner['_id'] ?? _owner['id'] ?? '').toString();
    if (ownerId.isNotEmpty) {
      context.push('${RouteNames.pathChatList}/$ownerId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              snap: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ImageCarousel(imageUrls: _imageUrls, height: 280),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _TypeBadge(label: _type),
                                      const SizedBox(width: 8),
                                      _TransactionBadge(
                                        label: _transactionType,
                                        isRent: _transactionType == 'للإيجار',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _title,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatPrice(_price),
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                                Text(
                                  'دج / $_priceUnit',
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                [
                                  if (_address.isNotEmpty) _address,
                                  if (_city.isNotEmpty) _city,
                                  _wilaya,
                                ].join('، '),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_rooms != null ||
                      _bathrooms != null ||
                      _area != null ||
                      _floor != null) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفاصيل العقار',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              if (_rooms != null)
                                _DetailChip(
                                  icon: Icons.bed_outlined,
                                  label: '$_rooms غرفة',
                                ),
                              if (_bathrooms != null)
                                _DetailChip(
                                  icon: Icons.bathtub_outlined,
                                  label: '$_bathrooms حمام',
                                ),
                              if (_area != null)
                                _DetailChip(
                                  icon: Icons.square_foot,
                                  label: '${_area!.toStringAsFixed(0)} م²',
                                ),
                              if (_floor != null)
                                _DetailChip(
                                  icon: Icons.apartment_outlined,
                                  label: _totalFloors != null
                                      ? 'الطابق $_floor/$_totalFloors'
                                      : 'الطابق $_floor',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_amenities.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المميزات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _amenities.map((a) {
                              final key = a.toString();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.success.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_amenityIcon(key),
                                        size: 14, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      _amenityLabel(key),
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_description.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الوصف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ExpandableText(text: _description),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_owner.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'صاحب العقار',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                backgroundImage:
                                    (_owner['avatar'] != null &&
                                            (_owner['avatar'] as String)
                                                .isNotEmpty)
                                        ? CachedNetworkImageProvider(
                                            _owner['avatar'] as String)
                                        : null,
                                child: (_owner['avatar'] == null ||
                                        (_owner['avatar'] as String).isEmpty)
                                    ? Text(
                                        ((_owner['name'] as String?) ?? 'م')
                                                .isNotEmpty
                                            ? ((_owner['name'] as String))[0]
                                                .toUpperCase()
                                            : 'م',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (_owner['name'] ?? 'مجهول').toString(),
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text(
                                      'مالك العقار',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_reviews.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'التقييمات (${_reviews.length})',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._reviews
                              .take(3)
                              .map((r) => _ReviewItem(
                                  review: r as Map<String, dynamic>)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _ContactBar(
            onCall: _contactPhone != null ? _callPhone : null,
            onChat: _openChat,
            onFavorite: _toggleFavorite,
            isFavorite: _isFavorite,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(2)}م';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)},000';
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

  String _transactionLabel(String key) =>
      key == 'sale' ? 'للبيع' : 'للإيجار';

  String _priceUnitLabel(String key) {
    const map = {
      'perMonth': 'شهر',
      'perYear': 'سنة',
      'total': 'إجمالي',
    };
    return map[key] ?? key;
  }

  String _amenityLabel(String key) {
    const map = {
      'furnished': 'مفروشة',
      'parking': 'موقف سيارات',
      'elevator': 'مصعد',
      'balcony': 'شرفة',
      'garden': 'حديقة',
      'pool': 'مسبح',
      'security': 'حراسة',
      'generator': 'مولد كهربائي',
    };
    return map[key] ?? key;
  }

  IconData _amenityIcon(String key) {
    const map = {
      'furnished': Icons.chair_outlined,
      'parking': Icons.local_parking_outlined,
      'elevator': Icons.elevator_outlined,
      'balcony': Icons.deck_outlined,
      'garden': Icons.yard_outlined,
      'pool': Icons.pool_outlined,
      'security': Icons.security_outlined,
      'generator': Icons.power_outlined,
    };
    return map[key] ?? Icons.check_circle_outline;
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _TransactionBadge extends StatelessWidget {
  const _TransactionBadge({required this.label, required this.isRent});
  final String label;
  final bool isRent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isRent ? AppColors.accent : AppColors.success,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.7,
          ),
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (widget.text.length > 200)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _expanded ? 'اقرأ أقل' : 'اقرأ المزيد',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.review});
  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final reviewer = review['reviewer'] as Map<String, dynamic>? ?? {};
    final name = (reviewer['name'] ?? 'مجهول').toString();
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = (review['comment'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: AppColors.starFilled,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  const _ContactBar({
    required this.onChat,
    required this.onFavorite,
    required this.isFavorite,
    this.onCall,
  });
  final VoidCallback? onCall;
  final VoidCallback onChat;
  final VoidCallback onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onCall != null) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text(
                  'اتصل',
                  style: TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: onCall != null ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text(
                'دردشة',
                style: TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onFavorite,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isFavorite
                    ? Colors.red.withOpacity(0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isFavorite ? Colors.red : AppColors.border),
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading shimmer
// ---------------------------------------------------------------------------
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'جارٍ التحميل...',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'تعذّر تحميل بيانات العقار',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                child: const Text('رجوع',
                    style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
