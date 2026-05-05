/// Get a deterministic placeholder asset path for an artisan
String getArtisanPlaceholder(String seed) {
  const count = 8;
  final sum = seed.codeUnits.fold<int>(0, (a, b) => a + b);
  final index = (sum % count) + 1;
  final two = index.toString().padLeft(2, '0');
  return 'assets/images/placeholders/artisan_$two.png';
}
