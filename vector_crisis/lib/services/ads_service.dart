import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_pacing_policy.dart';

abstract final class AdUnitIds {
  static const _androidInterstitial = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: 'GecisId',
  );
  static const _iosInterstitial = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: 'GecisId',
  );
  static const _androidRewarded = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    defaultValue: 'OdulId',
  );
  static const _iosRewarded = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
    defaultValue: 'OdulId',
  );

  static String get interstitial {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-3940256099942544/1033173712';
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosInterstitial
        : _androidInterstitial;
  }

  static String get rewarded {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosRewarded
        : _androidRewarded;
  }

  static bool get interstitialConfigured => interstitial != 'GecisId';
  static bool get rewardedConfigured => rewarded != 'OdulId';
  static bool get isConfigured => interstitialConfigured || rewardedConfigured;
}

class AdsService {
  static const _retryDelay = Duration(seconds: 30);

  final AdPacingPolicy pacing;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  final ValueNotifier<bool> rewardedAvailability = ValueNotifier(false);
  Timer? _interstitialRetry;
  Timer? _rewardedRetry;
  bool _initializationStarted = false;
  bool _mobileAdsReady = false;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  bool _disposed = false;

  AdsService({AdPacingPolicy? pacing}) : pacing = pacing ?? AdPacingPolicy();

  bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> initialize() async {
    if (_initializationStarted || !_isSupported || !AdUnitIds.isConfigured) {
      return;
    }
    _initializationStarted = true;
    try {
      await _gatherConsent();
      await _startAdsIfAllowed();
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
    }
  }

  Future<void> _gatherConsent() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('Consent form error: $error');
        });
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        debugPrint('Consent information error: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  Future<bool> showPrivacyOptions() async {
    if (!_isSupported || !AdUnitIds.isConfigured) return false;
    FormError? formError;
    await ConsentForm.showPrivacyOptionsForm((error) => formError = error);
    if (formError != null) {
      debugPrint('Privacy options error: $formError');
      return false;
    }
    await _startAdsIfAllowed();
    return true;
  }

  Future<void> _startAdsIfAllowed() async {
    if (_disposed || _mobileAdsReady) return;
    if (!await ConsentInformation.instance.canRequestAds()) return;
    await MobileAds.instance.initialize();
    if (_disposed) return;
    _mobileAdsReady = true;
    _loadInterstitial();
    _loadRewarded();
  }

  void recordLevelCompleted() => pacing.recordLevelCompleted();

  void _loadInterstitial() {
    if (!_mobileAdsReady ||
        !AdUnitIds.interstitialConfigured ||
        _disposed ||
        _loadingInterstitial ||
        _interstitial != null) {
      return;
    }
    _interstitialRetry?.cancel();
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          if (_disposed) return;
          debugPrint('Interstitial failed to load: $error');
          _interstitialRetry = Timer(_retryDelay, _loadInterstitial);
        },
      ),
    );
  }

  void _loadRewarded() {
    if (!_mobileAdsReady ||
        !AdUnitIds.rewardedConfigured ||
        _disposed ||
        _loadingRewarded ||
        _rewarded != null) {
      return;
    }
    _rewardedRetry?.cancel();
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          _loadingRewarded = false;
          _rewarded = ad;
          rewardedAvailability.value = true;
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          if (_disposed) return;
          rewardedAvailability.value = false;
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedRetry = Timer(_retryDelay, _loadRewarded);
        },
      ),
    );
  }

  Future<bool> showInterstitialIfEligible({
    required int completedLevel,
    bool adsAllowed = true,
  }) async {
    if (!adsAllowed || !pacing.canShowInterstitialAfter(completedLevel)) {
      return false;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => pacing.recordInterstitialShown(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show();
    return completer.future;
  }

  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    rewardedAvailability.value = false;
    var earnedReward = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => pacing.recordRewardedShown(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, reward) => earnedReward = true);
    return completer.future;
  }

  void dispose() {
    _disposed = true;
    _interstitialRetry?.cancel();
    _rewardedRetry?.cancel();
    _interstitial?.dispose();
    _rewarded?.dispose();
    rewardedAvailability.dispose();
  }
}
