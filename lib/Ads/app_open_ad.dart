import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

AppOpenAd? appOpenAd;

void loadOpenAppAd() {
  AppOpenAd.load(
    adUnitId: "ca-app-pub-3940256099942544/9257395921",
    orientation: AppOpenAd.orientationPortrait,
    request: const AdRequest(),
    adLoadCallback: AppOpenAdLoadCallback(
      onAdLoaded: (ad) {
        debugPrint("Ad Load");
        appOpenAd = ad;
        appOpenAd!.show();
      },
      onAdFailedToLoad: (error) {
        debugPrint('AppOpenAd failed to load: $error');
        // Handle the error.
      },
    ),
  );
}
