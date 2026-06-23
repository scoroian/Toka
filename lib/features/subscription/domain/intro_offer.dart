/// Oferta introductoria (prueba gratuita) asociada a un producto IAP, tal como
/// la reporta la store. La fuente de verdad es la propia store: si Google Play /
/// App Store no devuelven una fase de trial, [hasFreeTrial] es false y el
/// paywall NO promete una prueba que el usuario no recibiría (Hallazgo #14).
class IntroOffer {
  const IntroOffer({this.freeTrialDays = 0});

  /// Días de prueba gratuita ofrecidos (0 si no hay trial).
  final int freeTrialDays;

  bool get hasFreeTrial => freeTrialDays > 0;

  /// Sin oferta introductoria.
  static const IntroOffer none = IntroOffer();

  @override
  bool operator ==(Object other) =>
      other is IntroOffer && other.freeTrialDays == freeTrialDays;

  @override
  int get hashCode => freeTrialDays.hashCode;

  @override
  String toString() => 'IntroOffer(freeTrialDays: $freeTrialDays)';
}
