import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      title: 'Private Talent Intelligence',
      headline: 'Search CVs locally with on-device AI',
      subtitle:
          'Import resumes, search in plain English, and analyse candidate fit — 100% offline with zero data leaving your phone.',
      icon: Icons.shield_outlined,
      illustrationAsset: 'assets/logos/edgetal.png',
    ),
    _SlideData(
      title: 'About EdgeTal — Speed',
      headline: 'Screen CVs in minutes',
      subtitle:
          'Sub-millisecond semantic search engine powered by local vector embeddings. No waiting on slow cloud servers.',
      icon: Icons.bolt_outlined,
      illustrationAsset: 'assets/logos/Icon Only.png',
    ),
    _SlideData(
      title: 'About EdgeTal — Simplicity',
      headline: 'One app. Minimal setup.',
      subtitle:
          'Built to fit into your workflow. Seed sample candidates, import CSVs, and organize hiring pipelines effortlessly.',
      icon: Icons.auto_awesome_outlined,
      illustrationAsset: 'assets/logos/For Light Bgs.png',
    ),
    _SlideData(
      title: 'About EdgeTal — Privacy',
      headline: 'Nothing ever leaves your phone',
      subtitle:
          'GDPR by design. Candidate profiles, resumes, and AI match evaluations stay encrypted on your device.',
      icon: Icons.verified_user_outlined,
      illustrationAsset: 'assets/logos/Icon Only.png',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/candidates');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Link
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logos/Icon Only.png',
                          width: 28,
                          height: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EdgeTal',
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: context.text.labelLarge?.copyWith(
                        color: context.colors.brand,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration Container
                        Container(
                          height: 220,
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppPalette.darkSurfaceElevated
                                : AppPalette.softIceBlue.withAlpha(100),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: context.colors.border,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.colors.brand.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    slide.icon,
                                    size: 48,
                                    color: context.colors.brand,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  slide.title,
                                  style: context.text.labelMedium?.copyWith(
                                    color: context.colors.brand,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        // Headline
                        Text(
                          slide.headline,
                          textAlign: TextAlign.center,
                          style: context.text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Subtitle
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Controls (Dots + Primary CTA)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  // Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppPalette.midnightNavy
                              : AppPalette.softIceBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Primary CTA Button ("Get Started" or "Next")
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.midnightNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.icon,
    required this.illustrationAsset,
  });

  final String title;
  final String headline;
  final String subtitle;
  final IconData icon;
  final String illustrationAsset;
}
