import 'dart:async';

import 'package:flutter/material.dart';

import '../models/splash_slide.dart';

class SplashController extends ChangeNotifier {
  SplashController({
    List<SplashSlide>? slides,
    this.slideDuration = const Duration(milliseconds: 2400),
    this.pageAnimationDuration = const Duration(milliseconds: 520),
    this.onFinished,
  }) : slides = slides ?? SplashSlide.defaults;

  final List<SplashSlide> slides;
  final Duration slideDuration;
  final Duration pageAnimationDuration;
  final VoidCallback? onFinished;

  final PageController pageController = PageController();

  int currentIndex = 0;
  bool imagesReady = false;
  bool _finished = false;
  Timer? _timer;

  Future<void> preloadAndStart(BuildContext context) async {
    imagesReady = true;
    notifyListeners();
    _scheduleAdvance();

    await Future.wait(
      slides.map(
        (slide) => precacheImage(AssetImage(slide.imagePath), context),
      ),
    );
  }

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
    _timer?.cancel();
    _scheduleAdvance();
  }

  void skip() => _complete();

  void _scheduleAdvance() {
    _timer?.cancel();
    _timer = Timer(slideDuration, _advance);
  }

  void _advance() {
    if (_finished) return;
    if (currentIndex < slides.length - 1) {
      pageController.nextPage(
        duration: pageAnimationDuration,
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    _complete();
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    onFinished?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    pageController.dispose();
    super.dispose();
  }
}
