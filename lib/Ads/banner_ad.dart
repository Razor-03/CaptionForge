import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class BannerAdWidget extends StatefulWidget {
  @override
  _BannerAdWidgetState createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            isLoaded = true;
          });
        },
        onAdFailedToLoad: (_, error) {
          debugPrint('Ad load failed (code=${error.code} message=${error.message})');
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
