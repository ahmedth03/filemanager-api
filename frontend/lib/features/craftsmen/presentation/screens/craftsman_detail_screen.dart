import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/craftsmen_provider.dart';
import '../widgets/contact_sheet.dart';

class CraftsmanDetailScreen extends ConsumerWidget {
  const CraftsmanDetailScreen({super.key, required this.craftsmanId});

  final String craftsmanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(craftsmanDetailProvider(craftsmanId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: detailAsync.when(
          loading: () => const _DetailShimmer(),
          error: (e, __) => _ErrorBody(message: e.toString()),
          data: (craftsman) => _DetailBody(craftsman: craftsman),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail body
// ---------------------------------------------------------------------------
class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.craftsman});
  final Map<String, dynamic> craftsman;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  bool _isFavorite = false;

  // ── Computed getters ────────────────────────────────────────────────────────

  String get _id =>
      (widget.craftsman['_id'] ?? widget.craftsman['id'] ?? '').toString();
  String get _name =>
      (widget.craftsman['name'] ?? widget.craftsman['businessName'] ?? '')
          .toString();
  String get _specialty =>
      _specialtyLabel(widget.craftsman['specialty']?.toString() ?? '');
  double get _rating =>
      (widget.craftsman['rating'] as num?)?.toDouble() ?? 0.0;
  int get _reviewCount => (widget.craftsman['reviewCount'] as int?) ?? 0;
  String get _wilaya => (widget.craftsman['wilaya'] ?? '').toString();
  String get _city => (widget.craftsman['city'] ?? '').toString();
  bool get _isAvailable => widget.craftsman['isAvailable'] as bool? ?? false;
  bool get _isVerified => widget.craftsman['isVerified'] as bool? ?? false;
  String get _bio => (widget.craftsman['bio'] ?? '').toString();
  int get _experience => (widget.craftsman['experience'] as int?) ?? 0;
  int get _totalJobs => (widget.craftsman['totalJobs'] as int?) ?? 0;
  String? get _avatar => widget.craftsman['avatar']?.toString();
  String? get _phone => widget.craftsman['phone']?.toString();
  String? get _whatsapp => widget.craftsman['whatsapp']?.toString();
  List<dynamic> get _portfolio =>
      (widget.craftsman['portfolio'] as List<dynamic>?) ?? [];
  List<dynamic> get _reviews =>
      (widget.craftsman['reviews'] as List<dynamic>?) ?? [];

  void _toggleFavorite() => setState(() => _isFavorite = !_isFavorite);

  void _openContact() {
    ContactSheet.show(
      context,
      craftsmanId: _id,
      craftsmanName: _name,
      phone: _phone,
      whatsapp: _whatsapp,
    );
  }

  void _openPortfolio(int index) {
    final urls = _portfolio
        .map((p) => (p['imageUrl'] ?? p['url'] ?? '').toString())
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PortfolioGallery(urls: urls, initialIndex: index),
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

  Widget _avatarFallback(String name, double height) {
    return Container(
      height: height,
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── App bar ────────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _avatar != null
                        ? CachedNetworkImage(
                            imageUrl: _avatar!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                            errorWidget: (_, __, ___) =>
                                _avatarFallback(_name, double.infinity),
                          )
                        : _avatarFallback(_name, double.infinity),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xBB1B4F72)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _name,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (_isVerified) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified,
                                    color: AppColors.accent, size: 20),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _SpecialtyBadge(label: _specialty),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _isAvailable
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _isAvailable ? 'متاح' : 'غير متاح',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
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
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Rating + location ────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: _rating,
                              itemBuilder: (_, __) => const Icon(
                                Icons.star_rounded,
                                color: AppColors.starFilled,
                              ),
                              itemCount: 5,
                              itemSize: 20,
                              unratedColor: AppColors.starEmpty,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_rating.toStringAsFixed(1)} ($_reviewCount تقييم)',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              _city.isNotEmpty
                                  ? '$_city، $_wilaya'
                                  : _wilaya,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Stats row ────────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        _StatItem(
                          label: 'سنوات الخبرة',
                          value: '$_experience سنة',
                          icon: Icons.workspace_premium_outlined,
                        ),
                        _verticalDivider(),
                        _StatItem(
                          label: 'التقييمات',
                          value: _reviewCount.toString(),
                          icon: Icons.star_border_rounded,
                        ),
                        _verticalDivider(),
                        _StatItem(
                          label: 'الأعمال',
                          value: _totalJobs.toString(),
                          icon: Icons.handyman_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Bio ──────────────────────────────────────────────────
                  if (_bio.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'نبذة تعريفية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _bio,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Portfolio ────────────────────────────────────────────
                  if (_portfolio.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'معرض الأعمال',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${_portfolio.length} صورة',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              childAspectRatio: 1,
                            ),
                            itemCount: _portfolio.length > 9
                                ? 9
                                : _portfolio.length,
                            itemBuilder: (context, i) {
                              final item =
                                  _portfolio[i] as Map<String, dynamic>;
                              final url =
                                  (item['imageUrl'] ?? item['url'] ?? '')
                                      .toString();
                              final isLast =
                                  i == 8 && _portfolio.length > 9;
                              return GestureDetector(
                                onTap: () => _openPortfolio(i),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            Container(
                                          color: AppColors.shimmerBase,
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            Container(
                                          color: AppColors.border,
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color:
                                                AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      if (isLast)
                                        Container(
                                          color: Colors.black
                                              .withOpacity(0.55),
                                          child: Center(
                                            child: Text(
                                              '+${_portfolio.length - 9}',
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Reviews ──────────────────────────────────────────────
                  if (_reviews.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'التقييمات',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '$_reviewCount تقييم',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _RatingDistribution(reviews: _reviews),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          ..._reviews
                              .take(5)
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

        // ── Floating contact bar ────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openContact,
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: const Text(
                      'تواصل',
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
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleFavorite,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isFavorite
                          ? Colors.red.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            _isFavorite ? Colors.red : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite
                          ? Colors.red
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 40, width: 1, color: AppColors.divider);
  }
}

// ---------------------------------------------------------------------------
// Specialty badge
// ---------------------------------------------------------------------------
class _SpecialtyBadge extends StatelessWidget {
  const _SpecialtyBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat item
// ---------------------------------------------------------------------------
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rating distribution chart
// ---------------------------------------------------------------------------
class _RatingDistribution extends StatelessWidget {
  const _RatingDistribution({required this.reviews});
  final List<dynamic> reviews;

  Map<int, int> get _counts {
    final c = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      if (r is Map<String, dynamic>) {
        final star = ((r['rating'] as num?)?.round()) ?? 0;
        if (c.containsKey(star)) c[star] = c[star]! + 1;
      }
    }
    return c;
  }

  double get _average {
    if (reviews.isEmpty) return 0;
    double sum = 0;
    for (final r in reviews) {
      if (r is Map<String, dynamic>) {
        sum += (r['rating'] as num?)?.toDouble() ?? 0;
      }
    }
    return sum / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final total = reviews.length;
    final avg = _average;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              avg.toStringAsFixed(1),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            RatingBarIndicator(
              rating: avg,
              itemBuilder: (_, __) => const Icon(
                Icons.star_rounded,
                color: AppColors.starFilled,
              ),
              itemCount: 5,
              itemSize: 16,
              unratedColor: AppColors.starEmpty,
            ),
            const SizedBox(height: 4),
            Text(
              '$total تقييم',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final count = counts[star] ?? 0;
              final fraction = total > 0 ? count / total : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded,
                        size: 12, color: AppColors.starFilled),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: AppColors.starEmpty,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.starFilled),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Review item
// ---------------------------------------------------------------------------
class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.review});
  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final reviewer = review['reviewer'] as Map<String, dynamic>? ?? {};
    final name = (reviewer['name'] ?? 'مجهول').toString();
    final avatar = reviewer['avatar']?.toString();
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = (review['comment'] ?? '').toString();
    final createdAt = review['createdAt']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? CachedNetworkImageProvider(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ---------------------------------------------------------------------------
// Portfolio gallery viewer
// ---------------------------------------------------------------------------
class _PortfolioGallery extends StatefulWidget {
  const _PortfolioGallery({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_PortfolioGallery> createState() => _PortfolioGalleryState();
}

class _PortfolioGalleryState extends State<_PortfolioGallery> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_current + 1} / ${widget.urls.length}',
          style:
              const TextStyle(fontFamily: 'Cairo', color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.urls.length,
        pageController: PageController(initialPage: widget.initialIndex),
        onPageChanged: (i) => setState(() => _current = i),
        builder: (_, index) => PhotoViewGalleryPageOptions(
          imageProvider:
              CachedNetworkImageProvider(widget.urls[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
        backgroundDecoration:
            const BoxDecoration(color: Colors.black),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading skeleton
// ---------------------------------------------------------------------------
class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        children: [
          Container(height: 260, color: Colors.white),
          const SizedBox(height: 8),
          _block(16, 120),
          _block(16, 90),
          _block(16, 200),
        ],
      ),
    );
  }

  Widget _block(double margin, double height) {
    return Container(
      margin: EdgeInsets.fromLTRB(margin, 0, margin, 8),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
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
              'تعذّر تحميل بيانات الحرفي',
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
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('رجوع',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }
}
