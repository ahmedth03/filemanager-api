import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/app_colors.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 280,
    this.enableFullScreen = true,
  });

  final List<String> imageUrls;
  final double height;
  final bool enableFullScreen;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _EmptyCarousel(height: widget.height);
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: widget.imageUrls.length,
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: 1.0,
            enableInfiniteScroll: widget.imageUrls.length > 1,
            autoPlay: false,
            enlargeCenterPage: false,
            onPageChanged: (index, _) =>
                setState(() => _currentIndex = index),
          ),
          itemBuilder: (context, index, _) {
            final url = widget.imageUrls[index];
            return GestureDetector(
              onTap: widget.enableFullScreen
                  ? () => _openGallery(index)
                  : null,
              child: CachedNetworkImage(
                imageUrl: url,
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.primary.withOpacity(0.08),
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.border,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text(
                        'تعذّر تحميل الصورة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Page indicator
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 12,
            child: AnimatedSmoothIndicator(
              activeIndex: _currentIndex,
              count: widget.imageUrls.length,
              effect: const WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: Colors.white,
                dotColor: Colors.white38,
                strokeWidth: 0,
              ),
              onDotClicked: (index) {
                _controller.animateToPage(index);
              },
            ),
          ),

        // Image count badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library_outlined,
                    size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${_currentIndex + 1}/${widget.imageUrls.length}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Left/Right arrows
        if (widget.imageUrls.length > 1) ...[
          Positioned(
            right: 8,
            top: widget.height / 2 - 20,
            child: _ArrowButton(
              icon: Icons.chevron_right,
              onTap: () => _controller.nextPage(),
            ),
          ),
          Positioned(
            left: 8,
            top: widget.height / 2 - 20,
            child: _ArrowButton(
              icon: Icons.chevron_left,
              onTap: () => _controller.previousPage(),
            ),
          ),
        ],
      ],
    );
  }

  void _openGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(
          urls: widget.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _EmptyCarousel extends StatelessWidget {
  const _EmptyCarousel({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.primary.withOpacity(0.07),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined,
              size: 56, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'لا توجد صور',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({
    required this.urls,
    required this.initialIndex,
  });
  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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
          '${_currentIndex + 1} / ${widget.urls.length}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.urls.length,
        pageController: PageController(initialPage: widget.initialIndex),
        onPageChanged: (i) => setState(() => _currentIndex = i),
        builder: (_, index) => PhotoViewGalleryPageOptions(
          imageProvider:
              CachedNetworkImageProvider(widget.urls[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          heroAttributes: PhotoViewHeroAttributes(
              tag: 'listing_image_${widget.urls[index]}'),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
    );
  }
}
