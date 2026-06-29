/// The animated states of the Mira mom mascot. Each maps to a WebP in
/// assets/mom/<name>.webp.
enum MomState {
  idle,
  celebrate,
  shh,
  diaper,
  surprised,
  pointing,
  calm,
  hug,
  tired,
}

extension MomStateAsset on MomState {
  String get asset => 'assets/mom/$name.webp';
}
