import 'dart:convert';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, required this.adSize});
  final AdSize adSize;

  @override
  _BannerAdWidgetState createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      String adSettings = prefs.getString('ad_settings') ?? '';
      if (adSettings.isNotEmpty) {
        var bannerAdunit = jsonDecode(adSettings)['banner_adUnit'];
        _loadBannerAd(bannerAdunit);
      }
    });
  }

  void _loadBannerAd(String adUnitId) {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            isLoaded = true;
          });
        },
        onAdFailedToLoad: (_, error) {
          debugPrint(
              'Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoaded
        ? SizedBox(
            key: UniqueKey(),
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(
              key: UniqueKey(),
              ad: _bannerAd!,
            ),
          )
        : Container();
  }
}
