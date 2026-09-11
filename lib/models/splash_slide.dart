import '../core/constants/app_assets.dart';

class SplashSlide {
  const SplashSlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  final String imagePath;
  final String title;
  final String subtitle;

  static const List<SplashSlide> defaults = [
    SplashSlide(
      imagePath: AppAssets.splashLearn,
      title: 'Learn together',
      subtitle: 'A complete school LMS for classes, homework, and daily learning.',
    ),
    SplashSlide(
      imagePath: AppAssets.splashTeach,
      title: 'Teach with clarity',
      subtitle: 'Teachers and staff manage attendance, lessons, and results in one place.',
    ),
    SplashSlide(
      imagePath: AppAssets.splashConnect,
      title: 'Stay connected',
      subtitle: 'Parents and students stay close to school life, anywhere they are.',
    ),
  ];
}
