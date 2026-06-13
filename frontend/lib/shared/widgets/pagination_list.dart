import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

// ---------------------------------------------------------------------------
// Brand colours (inline)
// ---------------------------------------------------------------------------
class _C {
  static const Color primary = Color(0xFF1B4F72);
  static const Color textLight = Color(0xFF6C757D);
  static const Color textDark = Color(0xFF212529);
  static const Color error = Color(0xFFDC3545);
  static const Color divider = Color(0xFFDEE2E6);
  static const Color background = Color(0xFFF8F9FA);
}

// ---------------------------------------------------------------------------
// PaginationList<T>
// ---------------------------------------------------------------------------
/// An infinite-scroll list built on [PagedListView] from the
/// `infinite_scroll_pagination` package.
///
/// Usage:
/// ```dart
/// PaginationList<MyItem>(
///   pagingController: _pagingController,
///   itemBuilder: (context, item, index) => MyItemTile(item: item),
/// )
/// ```
class PaginationList<T> extends StatelessWidget {
  const PaginationList({
    super.key,
    required this.pagingController,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.emptyIcon,
    this.emptyTitle = 'Nothing here yet',
    this.emptySubtitle,
    this.loadingItemCount = 3,
    this.loadingPlaceholder,
    this.scrollController,
  });

  /// The paging controller driving this list.
  final PagingController<int, T> pagingController;

  /// Builds each item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Optional separator between items.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// Icon for the empty-state view.
  final IconData? emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;

  /// Number of shimmer/skeleton placeholders shown while first page loads.
  final int loadingItemCount;

  /// Custom loading placeholder widget shown for each skeleton item.
  final Widget? loadingPlaceholder;

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final builderDelegate = PagedChildBuilderDelegate<T>(
      itemBuilder: itemBuilder,
      firstPageProgressIndicatorBuilder: (_) =>
          _FirstPageLoader(count: loadingItemCount, placeholder: loadingPlaceholder),
      newPageProgressIndicatorBuilder: (_) => const _NewPageLoader(),
      firstPageErrorIndicatorBuilder: (ctx) => _FirstPageError(
        pagingController: pagingController,
      ),
      newPageErrorIndicatorBuilder: (ctx) => _NewPageError(
        pagingController: pagingController,
      ),
      noItemsFoundIndicatorBuilder: (_) => _EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      ),
      noMoreItemsIndicatorBuilder: (_) => const _NoMoreItems(),
    );

    if (separatorBuilder != null) {
      return PagedListView<int, T>.separated(
        pagingController: pagingController,
        scrollController: scrollController,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        builderDelegate: builderDelegate,
        separatorBuilder: separatorBuilder!,
      );
    }

    return PagedListView<int, T>(
      pagingController: pagingController,
      scrollController: scrollController,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      builderDelegate: builderDelegate,
    );
  }
}

// ---------------------------------------------------------------------------
// PaginationGrid<T>
// ---------------------------------------------------------------------------
class PaginationGrid<T> extends StatelessWidget {
  const PaginationGrid({
    super.key,
    required this.pagingController,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.emptyIcon,
    this.emptyTitle = 'Nothing here yet',
    this.emptySubtitle,
    this.scrollController,
  });

  final PagingController<int, T> pagingController;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final IconData? emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return PagedGridView<int, T>(
      pagingController: pagingController,
      scrollController: scrollController,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      builderDelegate: PagedChildBuilderDelegate<T>(
        itemBuilder: itemBuilder,
        firstPageProgressIndicatorBuilder: (_) =>
            _FirstPageLoader(count: crossAxisCount * 2),
        newPageProgressIndicatorBuilder: (_) => const _NewPageLoader(),
        firstPageErrorIndicatorBuilder: (_) => _FirstPageError(
          pagingController: pagingController,
        ),
        newPageErrorIndicatorBuilder: (_) => _NewPageError(
          pagingController: pagingController,
        ),
        noItemsFoundIndicatorBuilder: (_) => _EmptyState(
          icon: emptyIcon,
          title: emptyTitle,
          subtitle: emptySubtitle,
        ),
        noMoreItemsIndicatorBuilder: (_) => const _NoMoreItems(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _FirstPageLoader extends StatelessWidget {
  const _FirstPageLoader({this.count = 3, this.placeholder});
  final int count;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (_) => placeholder ?? const _SkeletonTile(),
      ),
    );
  }
}

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile();

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _C.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _C.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: _C.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
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
}

class _NewPageLoader extends StatelessWidget {
  const _NewPageLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(_C.primary),
          ),
        ),
      ),
    );
  }
}

class _FirstPageError extends StatelessWidget {
  const _FirstPageError({required this.pagingController});
  final PagingController pagingController;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _C.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 40, color: _C.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textDark,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pagingController.error?.toString() ?? 'Please try again.',
              style: const TextStyle(
                fontSize: 13,
                color: _C.textLight,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: pagingController.retryLastFailedRequest,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPageError extends StatelessWidget {
  const _NewPageError({required this.pagingController});
  final PagingController pagingController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: _C.error, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Failed to load more',
            style: TextStyle(
              color: _C.textLight,
              fontSize: 13,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: pagingController.retryLastFailedRequest,
            style: TextButton.styleFrom(
              foregroundColor: _C.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.icon, required this.title, this.subtitle});
  final IconData? icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.divider.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: 48,
                color: _C.textLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _C.textDark,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: _C.textLight,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoMoreItems extends StatelessWidget {
  const _NoMoreItems();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '— End of list —',
          style: TextStyle(
            color: _C.textLight,
            fontSize: 12,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}
