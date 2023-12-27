import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class NativeAdWidget extends StatefulWidget {
  @override
  _NativeAdWidgetState createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  final _nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  @override
  void initState() {
    super.initState();
    loadNativeAd();
  }

  void loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
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
        // Required: Choose a template.
        templateType: TemplateType.small,
        // Optional: Customize the ad's style.
        // mainBackgroundColor: Colors.purple,
        // cornerRadius: 10.0,
        // callToActionTextStyle: NativeTemplateTextStyle(
        //     textColor: Colors.cyan,
        //     backgroundColor: Colors.red,
        //     style: NativeTemplateFontStyle.monospace,
        //     size: 16.0),
        // primaryTextStyle: NativeTemplateTextStyle(
        //     textColor: Colors.red,
        //     backgroundColor: Colors.cyan,
        //     style: NativeTemplateFontStyle.italic,
        //     size: 16.0),
        // secondaryTextStyle: NativeTemplateTextStyle(
        //     textColor: Colors.green,
        //     backgroundColor: Colors.black,
        //     style: NativeTemplateFontStyle.bold,
        //     size: 16.0),
        // tertiaryTextStyle: NativeTemplateTextStyle(
        //     textColor: Colors.brown,
        //     backgroundColor: Colors.amber,
        //     style: NativeTemplateFontStyle.normal,
        //     size: 16.0),
      ),
    )..load();
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
              minHeight: 90, // minimum recommended height
              maxWidth: 400,
              maxHeight: 200,
            ),
            child: AdWidget(key: UniqueKey(), ad: _nativeAd!),
          )
        : Container();
  }
}
