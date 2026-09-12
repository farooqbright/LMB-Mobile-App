import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../controllers/splash_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/splash_slide.dart';
import '../../services/session_store.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplashController(onFinished: _goToLogin);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.preloadAndStart(context);
    });
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    final session = await SessionStore.instance.restore();
    if (!mounted) return;
    if (session != null) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.dashboardFor(session),
        arguments: session,
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (!_controller.imagesReady) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller.pageController,
                onPageChanged: _controller.onPageChanged,
                itemCount: _controller.slides.length,
                itemBuilder: (context, index) {
                  final slide = _controller.slides[index];
                  return Image.asset(
                    slide.imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  );
                },
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x660F1D4A),
                      Color(0x000F1D4A),
                      Color(0xCC0F1D4A),
                      Color(0xF20F1D4A),
                    ],
                    stops: [0, 0.32, 0.68, 1],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              AppStrings.appName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _controller.skip,
                            child: const Text(
                              AppStrings.skip,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: _SlideCopy(
                          key: ValueKey(_controller.currentIndex),
                          slide: _controller.slides[_controller.currentIndex],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _PageDots(
                        count: _controller.slides.length,
                        index: _controller.currentIndex,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SlideCopy extends StatelessWidget {
  const _SlideCopy({super.key, required this.slide});

  final SplashSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slide.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          slide.subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.86),
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.only(right: 8),
          height: 8,
          width: selected ? 28 : 8,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white38,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
