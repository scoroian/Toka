// Test unit IDs oficiales de Google AdMob.
// Seguros de usar en desarrollo — no generan revenue ni infracciones.
// TODO producción: reemplazar con unit IDs reales por plataforma antes de release.
export const TEST_BANNER_UNIT_ID_ANDROID = "ca-app-pub-3940256099942544/6300978111";
export const TEST_BANNER_UNIT_ID_IOS = "ca-app-pub-3940256099942544/2934735716";

// Por ahora Firestore guarda un único bannerUnit; el cliente override por plataforma.
export const DEFAULT_BANNER_UNIT_ID = TEST_BANNER_UNIT_ID_ANDROID;
