import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Helper iklan AdMob.
///
/// CATATAN: semua ID di bawah adalah **ID TEST resmi Google**. Aman dipakai saat
/// pengembangan. Ganti dengan ID asli (dari akun AdMob) sebelum rilis ke store —
/// memakai ID asli saat menguji melanggar kebijakan AdMob.
class Ads {
  static bool _ready = false;

  // ---- Ad unit: Interstitial (iklan layar penuh sesudah konversi) ----
  static String get interstitialUnit => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  // ---- Ad unit: Banner (bawah layar) ----
  static String get bannerUnit => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  static Future<void> init() async {
    if (_ready) return;
    await MobileAds.instance.initialize();
    _ready = true;
    _loadInterstitial();
  }

  // --- Interstitial: dipreload lalu ditampilkan saat momen natural (sesudah hasil) ---
  static InterstitialAd? _interstitial;
  static bool _loadingInterstitial = false;

  static void _loadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          _loadingInterstitial = false;
          if (kDebugMode) debugPrint('Interstitial gagal: $err');
        },
      ),
    );
  }

  /// Tampilkan interstitial bila siap; selalu preload yang berikutnya.
  /// Tidak memblokir alur — kalau iklan belum siap, langsung lewat.
  static void maybeShowInterstitial() {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
    );
    ad.show();
    _interstitial = null;
  }
}
