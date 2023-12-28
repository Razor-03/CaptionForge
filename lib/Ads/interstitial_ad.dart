import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

InterstitialAd? interstitialAd;
const _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

void loadInterstitialAd() {
  InterstitialAd.load(
    adUnitId: _interstitialAdUnitId,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      // Called when an ad is successfully received.
      onAdLoaded: (ad) {
        debugPrint('$ad loaded.');
        // Keep a reference to the ad so you can show it later.
        interstitialAd = ad;
        ad.show();
      },
      // Called when an ad request failed.
      onAdFailedToLoad: (LoadAdError error) {
        debugPrint('InterstitialAd failed to load: $error');
      },
    ),
  );
}
