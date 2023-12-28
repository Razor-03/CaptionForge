import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

RewardedAd? rewardedAd;
const _rewardAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

void loadRewardAd() {
  RewardedAd.load(
    adUnitId: _rewardAdUnitId,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      // Called when an ad is successfully received.
      onAdLoaded: (ad) {
        debugPrint('$ad loaded.');
        // Keep a reference to the ad so you can show it later.
        rewardedAd = ad;
        ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {  });
      },
      // Called when an ad request failed.
      onAdFailedToLoad: (LoadAdError error) {
        debugPrint('RewardedAd failed to load: $error');
      },
    ),
  );
}
