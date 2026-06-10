import 'dart:async';
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

  // ===========================================================================
  //  KONFIGURASI IKLAN  —  baca CARA-PASANG-ADMOB.md
  // ===========================================================================
  //
  //  Saat [useTestAds] = true  -> semua iklan pakai ID TEST resmi Google
  //    (WAJIB selama testing; pakai ID asli untuk testing bisa kena banned).
  //
  //  Untuk RILIS ke store:
  //    1. Daftar AdMob, buat app + 3 ad unit (banner/interstitial/rewarded)
  //       untuk Android DAN iOS (total 6 unit + 2 App ID). Lihat panduan.
  //    2. Tempel ke-6 ID unit di bawah (yang berawalan GANTI_...).
  //    3. Tempel 2 App ID di:
  //         - android/app/src/main/AndroidManifest.xml  (APPLICATION_ID)
  //         - ios/Runner/Info.plist                      (GADApplicationIdentifier)
  //    4. Ubah baris ini menjadi:  static const bool useTestAds = false;
  // ===========================================================================
  static const bool useTestAds = false;

  // ---- ID ASLI dari akun AdMob (publisher ca-app-pub-1298950542115439) ----
  // Format unit: 'ca-app-pub-0000000000000000/1111111111'
  static const _androidBannerReal = 'ca-app-pub-1298950542115439/5604413564';
  static const _androidInterstitialReal = 'ca-app-pub-1298950542115439/3068376418';
  static const _androidRewardedReal = 'ca-app-pub-1298950542115439/3712747397';
  static const _iosBannerReal = 'ca-app-pub-1298950542115439/3069210568';
  static const _iosInterstitialReal = 'ca-app-pub-1298950542115439/2682197750';
  static const _iosRewardedReal = 'ca-app-pub-1298950542115439/3305014288';

  // ---- ID TEST resmi Google (jangan diubah) ----
  static const _androidBannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _androidInterstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const _androidRewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const _iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';
  static const _iosRewardedTest = 'ca-app-pub-3940256099942544/1712485313';

  // ---- Ad unit: Banner (bawah layar) ----
  static String get bannerUnit => useTestAds
      ? (Platform.isIOS ? _iosBannerTest : _androidBannerTest)
      : (Platform.isIOS ? _iosBannerReal : _androidBannerReal);

  // ---- Ad unit: Interstitial (iklan layar penuh sesudah konversi) ----
  static String get interstitialUnit => useTestAds
      ? (Platform.isIOS ? _iosInterstitialTest : _androidInterstitialTest)
      : (Platform.isIOS ? _iosInterstitialReal : _androidInterstitialReal);

  // ---- Ad unit: Rewarded (tonton untuk buka akses tanpa batas) ----
  static String get rewardedUnit => useTestAds
      ? (Platform.isIOS ? _iosRewardedTest : _androidRewardedTest)
      : (Platform.isIOS ? _iosRewardedReal : _androidRewardedReal);

  static Future<void> init() async {
    if (_ready) return;
    await MobileAds.instance.initialize();
    _ready = true;
    _loadInterstitial();
    _loadRewarded();
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

  // --- Rewarded: dipreload, ditampilkan saat pengguna mau buka akses tanpa batas ---
  static RewardedAd? _rewarded;
  static bool _loadingRewarded = false;

  static void _loadRewarded() {
    if (_loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (err) {
          _rewarded = null;
          _loadingRewarded = false;
          if (kDebugMode) debugPrint('Rewarded gagal: $err');
        },
      ),
    );
  }

  /// Apakah ada iklan berhadiah yang siap ditampilkan sekarang?
  static bool get rewardedReady => _rewarded != null;

  /// Tampilkan iklan berhadiah. Mengembalikan true bila pengguna menonton sampai
  /// mendapatkan hadiah; false bila iklan belum siap, gagal tampil, atau ditutup
  /// sebelum selesai. Selalu memuat iklan berikutnya setelah selesai.
  static Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    _rewarded = null;
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }
}
