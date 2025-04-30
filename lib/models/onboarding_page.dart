class OnboardingPage {
  final String title;
  final String description;
  final String animationAsset;
  final bool isVectorAnimation;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.animationAsset,
    this.isVectorAnimation = true,
  });
}