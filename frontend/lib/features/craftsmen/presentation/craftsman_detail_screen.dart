import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/craftsmen_provider.dart';
import '../data/craftsman_model.dart';
import '../../favorites/providers/favorites_provider.dart';

class CraftsmanDetailScreen extends ConsumerWidget {
  final String craftsmanId;

  const CraftsmanDetailScreen({super.key, required this.craftsmanId});

  Future<void> _launchWhatsApp(String number) async {
    final cleaned = number.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final craftsmanAsync = ref.watch(craftsmanDetailProvider(craftsmanId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: craftsmanAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4F72))),
          error: (error, _) => Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1B4F72),
              foregroundColor: Colors.white,
              title: const Text('خطأ',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Color(0xFFE74C3C)),
                    const SizedBox(height: 16),
                    Text(error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Cairo', fontSize: 15)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(craftsmanDetailProvider(craftsmanId)),
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
          ),
          data: (craftsman) => _CraftsmanDetailBody(
            craftsman: craftsman,
            onWhatsApp: craftsman.whatsappNumber != null
                ? () => _launchWhatsApp(craftsman.whatsappNumber!)
                : null,
            onCall: craftsman.user.phone != null
                ? () => _launchPhone(craftsman.user.phone!)
                : null,
          ),
        ),
      ),
    );
  }
}

class _CraftsmanDetailBody extends ConsumerWidget {
  final CraftsmanModel craftsman;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;

  const _CraftsmanDetailBody({
    required this.craftsman,
    this.onWhatsApp,
    this.onCall,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(isCraftsmanFavoritedProvider(craftsman.id));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF1B4F72),
          foregroundColor: Colors.white,
          pinned: true,
          title: Text(
            craftsman.fullName,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
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
                    .toggleFavorite(craftsmanId: craftsman.id)
                    .then((_) =>
                        ref.invalidate(isCraftsmanFavoritedProvider(craftsman.id))),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          const Color(0xFF1B4F72).withOpacity(0.12),
                      backgroundImage: craftsman.user.avatarUrl != null
                          ? NetworkImage(craftsman.user.avatarUrl!)
                          : null,
                      child: craftsman.user.avatarUrl == null
                          ? Text(
                              craftsman.fullName.isNotEmpty
                                  ? craftsman.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B4F72),
                                fontFamily: 'Cairo',
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            craftsman.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          if (craftsman.specialty != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              craftsman.specialty!.nameAr,
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Color(0xFF6C757D),
                                  fontSize: 14),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 18, color: Color(0xFFF39C12)),
                              const SizedBox(width: 4),
                              Text(
                                '${craftsman.avgRating.toStringAsFixed(1)} (${craftsman.totalReviews})',
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: craftsman.city),
                    _InfoChip(
                        icon: Icons.work_outline,
                        label: '${craftsman.yearsExperience} سنوات خبرة'),
                    _InfoChip(
                        icon: Icons.circle,
                        label: craftsman.isAvailable ? 'متاح' : 'مشغول',
                        color: craftsman.isAvailable
                            ? const Color(0xFF27AE60)
                            : const Color(0xFFE74C3C)),
                  ],
                ),
                if (craftsman.bio != null && craftsman.bio!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'نبذة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    craftsman.bio!,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: Color(0xFF6C757D),
                        height: 1.6),
                  ),
                ],
                const SizedBox(height: 20),
                // Contact buttons
                Row(
                  children: [
                    if (onWhatsApp != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onWhatsApp,
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('واتساب',
                              style: TextStyle(fontFamily: 'Cairo')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    if (onWhatsApp != null && onCall != null)
                      const SizedBox(width: 12),
                    if (onCall != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.phone_outlined),
                          label: const Text('اتصال',
                              style: TextStyle(fontFamily: 'Cairo')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F72),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                  ],
                ),
                // Portfolio
                if (craftsman.portfolio.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'معرض الأعمال',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: craftsman.portfolio.length,
                    itemBuilder: (context, index) {
                      final item = craftsman.portfolio[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFDEE2E6),
                                child: const Icon(Icons.image_not_supported,
                                    color: Color(0xFF6C757D)),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                // Add review button
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                      '/reviews/add?craftsmanId=${craftsman.id}'),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF1B4F72)).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? const Color(0xFF1B4F72)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: color ?? const Color(0xFF1B4F72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
