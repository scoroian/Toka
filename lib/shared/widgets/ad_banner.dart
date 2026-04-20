import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_banner_config_provider.dart';

// Test unit IDs oficiales de Google. Nunca generan revenue y son seguros
// de usar en dev. En producción se sobreescriben por el unitId del dashboard.
const String _kTestBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
const String _kTestBanneriOS = 'ca-app-pub-3940256099942544/2934735716';

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  // Altura del contenedor visual del banner (ad 320x50 + padding vertical mínimo).
  // Usada por MainShellV2 para reservar espacio en el Scaffold cuando el
  // banner está visible, y por los FABs para levantarse por encima.
  static const double kBannerHeight = 58;

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _failed = false;
  String? _loadedUnitId;
  Timer? _refreshTimer;

  // Refresh cada 60s cumple la política de Google AdMob
  // (https://support.google.com/admob/answer/3408659): mínimo 60s.
  static const Duration _kRefreshInterval = Duration(seconds: 60);

  String _effectiveUnitId(String fromServer) {
    if (kDebugMode) {
      return Platform.isIOS ? _kTestBanneriOS : _kTestBannerAndroid;
    }
    if (fromServer.isEmpty) {
      return Platform.isIOS ? _kTestBanneriOS : _kTestBannerAndroid;
    }
    return fromServer;
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _loaded = false;
    _loadedUnitId = null;
  }

  void _loadBanner(String unitId) {
    _disposeBanner();
    _failed = false;
    _loadedUnitId = unitId;
    _banner = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _banner = null;
            _loaded = false;
            _failed = true;
          });
        },
      ),
    )..load();
  }

  void _scheduleRefresh(String unitId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_kRefreshInterval, (_) {
      if (!mounted) return;
      // Sólo refresca si el banner anterior cargó correctamente; si falló,
      // no quememos inventario reintentando en bucle.
      if (_failed) return;
      _loadBanner(unitId);
    });
  }

  void _syncWithConfig(AdBannerConfig config) {
    if (!config.show || config.unitId.isEmpty) {
      _refreshTimer?.cancel();
      if (_banner != null || _loaded) {
        setState(_disposeBanner);
      }
      return;
    }
    final effective = _effectiveUnitId(config.unitId);
    if (_failed) return;
    if (_banner != null && _loadedUnitId == effective) return;
    _loadBanner(effective);
    _scheduleRefresh(effective);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AdBannerConfig>(adBannerConfigProvider, (prev, next) {
      _syncWithConfig(next);
    });

    final config = ref.watch(adBannerConfigProvider);
    // Inicializar el banner en el primer build si procede.
    if (_banner == null && !_failed && config.show && config.unitId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncWithConfig(config);
      });
    }

    if (!config.show || config.unitId.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_failed) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_loaded || _banner == null) {
      return const SizedBox(height: AdBanner.kBannerHeight);
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF14141E).withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            width: _banner!.size.width.toDouble(),
            height: _banner!.size.height.toDouble(),
            child: AdWidget(ad: _banner!),
          ),
        ),
      ),
    );
  }
}
