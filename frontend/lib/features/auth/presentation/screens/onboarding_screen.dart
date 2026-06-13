import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/storage/preferences_storage.dart';
import '../../../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Data model for a single onboarding page
// ---------------------------------------------------------------------------

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}

const _pages = [
  _OnboardingPage(
    title: 'ابحث عن حرفيين محترفين',
    description:
        'تواصل مع أفضل الحرفيين في ولايتك. سباكون، كهربائيون، نجارون، دهانون وأكثر — كل ما تحتاجه في مكان واحد.',
    icon: Icons.handyman_rounded,
    iconColor: AppColors.primary,
    bgColor: Color(0xFFE8F4FD),
  ),
  _OnboardingPage(
    title: 'استأجر شقتك بسهولة',
    description:
        'تصفح آلاف إعلانات الشقق والمنازل والمحلات في جميع ولايات الجزائر. صور حقيقية، أسعار واضحة، تواصل مباشر مع المالك.',
    icon: Icons.apartment_rounded,
    iconColor: Color(0xFF27AE60),
    bgColor: Color(0xFFE8F8F0),
  ),
  _OnboardingPage(
    title: 'تواصل مباشرة',
    description:
        'راسل الحرفيين والملاك مباشرة عبر الدردشة أو الهاتف أو واتساب. لا وسيط، لا تعقيد — فقط تواصل سريع وفعال.',
    icon: Icons.chat_bubble_rounded,
    iconColor: AppColors.accent,
    bgColor: Color(0xFFFEF9E7),
  ),
];

// ---------------------------------------------------------------------------
// OnboardingScreen
// ---------------------------------------------------------------------------

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = ref.read(preferencesStorageProvider);
    await prefs.setOnboardingDone(true);
    if (!mounted) return;
    context.go(RouteNames.pathLogin);
  }

  void _next() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _pages.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Skip button row
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'تخطي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, index) =>
                      _PageContent(page: _pages[index]),
                ),
              ),

              // Dots indicator
              _DotsIndicator(count: _pages.length, activeIndex: _currentIndex),

              const SizedBox(height: 32),

              // Next / Done button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(isLast ? 'ابدأ الآن' : 'التالي'),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page content widget
// ---------------------------------------------------------------------------

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration circle
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: page.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 90, color: page.iconColor),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dots indicator
// ---------------------------------------------------------------------------

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.activeIndex});
  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
