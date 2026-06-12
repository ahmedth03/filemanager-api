import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/network_image_widget.dart';
import '../providers/listings_provider.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listingsProvider.notifier).loadMyListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعلاناتي'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.createListing),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة إعلان'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.myListings.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.apartment_outlined,
                  title: 'لا توجد إعلانات بعد',
                  subtitle: 'أضف إعلانك الأول الآن',
                  actionLabel: 'إضافة إعلان',
                  onAction: () => context.push(RouteNames.createListing),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(listingsProvider.notifier).loadMyListings(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.myListings.length,
                    itemBuilder: (_, i) => _MyListingCard(
                      listing: state.myListings[i],
                      onDelete: () => _confirmDelete(context, state.myListings[i]['id']),
                      onEdit: () => context.push('/listings/edit/${state.myListings[i]['id']}'),
                    ),
                  ),
                ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(listingsProvider.notifier).deleteListing(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الإعلان'), backgroundColor: Colors.green));
      }
    }
  }
}

class _MyListingCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MyListingCard({required this.listing, required this.onDelete, required this.onEdit});

  Color _statusColor(String status) => switch (status) {
    'ACTIVE' => Colors.green,
    'DRAFT' => Colors.orange,
    'RENTED' => Colors.blue,
    'ARCHIVED' => Colors.grey,
    _ => Colors.grey,
  };

  String _statusLabel(String status) => switch (status) {
    'ACTIVE' => 'نشط',
    'DRAFT' => 'مسودة',
    'RENTED' => 'مؤجر',
    'ARCHIVED' => 'مؤرشف',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    final images = (listing['images'] as List?) ?? [];
    final coverUrl = images.isNotEmpty ? images[0]['url'] as String? : null;
    final price = double.tryParse(listing['price']?.toString() ?? '0') ?? 0;
    final status = listing['status'] ?? 'DRAFT';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/listings/${listing['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverUrl != null
                    ? NetworkImageWidget(url: coverUrl, width: 80, height: 80, fit: BoxFit.cover)
                    : Container(
                        width: 80, height: 80,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.apartment, color: AppColors.onSurfaceVariant),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _statusColor(status).withOpacity(0.5)),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppFormatters.formatPrice(price)} / ${listing['pricePeriod'] ?? 'شهري'}',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text('${listing['city'] ?? ''}, ${listing['wilaya'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const Spacer(),
                        const Icon(Icons.bed_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text('${listing['rooms']} غرف', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: onEdit,
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
