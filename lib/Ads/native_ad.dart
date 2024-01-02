import 'dart:convert';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});
  @override
  _NativeAdWidgetState createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      String adSettings = prefs.getString('ad_settings') ?? '';
      if (adSettings.isNotEmpty) {
        var ads = jsonDecode(adSettings);
        if (ads['nativeAdmob'] && ads['ad_active']) {
          loadNativeAd(ads['native_adUnit']);
        }
      }
    });
  }

  void loadNativeAd(String adUnitId) {
    setState(() {
      _nativeAd = NativeAd(
        adUnitId: adUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('$NativeAd loaded.');
            setState(() {
              _nativeAdIsLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            // Dispose the ad here to free resources.
            debugPrint('$NativeAd failed to load: $error');
            ad.dispose();
          },
        ),
        request: const AdRequest(),
        // Styling
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
        ),
      )..load();
    });
  }

  @override
  void dispose() {
    _nativeAd!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _nativeAdIsLoaded
        ? ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 320, // minimum recommended width
              minHeight: 50, // minimum recommended height
              maxWidth: 400,
              maxHeight: 200,
            ),
            child: AdWidget(ad: _nativeAd!),
          )
        : Container();
  }
}
