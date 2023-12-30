import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

AppOpenAd? appOpenAd;

void loadOpenAppAd({String adUnitId = "ca-app-pub-3940256099942544/9257395921"}) {
  AppOpenAd.load(
    adUnitId: adUnitId,
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
