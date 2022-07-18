import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/admob_utils.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:flutterapp/utils/images.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info/package_info.dart';

import '../main.dart';

class AboutUs extends StatefulWidget {
  static var tag = "/AboutUs";

  @override
  _AboutUsState createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
  String? copyrightText = '';

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  init() async {
    setState(() {
      if (getStringAsync(COPYRIGHT_TEXT).isNotEmpty) {
        copyrightText = getStringAsync(COPYRIGHT_TEXT);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appStore.scaffoldBackground,
        appBar: appBar(context, title: keyString(context, "lbl_about")) as PreferredSizeWidget?,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                alignment: Alignment.center,
                decoration: boxDecoration(radius: 10.0, showShadow: true, bgColor: appStore.editTextBackColor),
                child: Image.asset(ic_logo),
              ),
              16.height,
              FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (_, snap) {
                    if (snap.hasData) {
                      return Text('${snap.data!.appName.validate()}', style: boldTextStyle(color: primaryColor, size: 20));
                    }
                    return SizedBox();
                  }),
              FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (_, snap) {
                    if (snap.hasData) {
                      return Text('V ${snap.data!.version.validate()}', style: secondaryTextStyle());
                    }
                    return SizedBox();
                  }),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          width: context.width(),
          height: 170,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(keyString(context, 'llb_follow_us')!, style: boldTextStyle()).visible(getStringAsync(WHATSAPP).isNotEmpty),
              16.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  16.width,
                  InkWell(
                    onTap: () => redirectUrl('https://wa.me/${getStringAsync(WHATSAPP)}'),
                    child: Image.asset("ic_Whatsapp.png", height: 35, width: 35).paddingAll(10),
                  ).visible(getStringAsync(WHATSAPP).isNotEmpty),
                  InkWell(
                    onTap: () => redirectUrl(getStringAsync(INSTAGRAM)),
                    child: Image.asset("ic_Inst.png", height: 35, width: 35).paddingAll(10),
                  ).visible(getStringAsync(INSTAGRAM).isNotEmpty),
                  InkWell(
                    onTap: () => redirectUrl(getStringAsync(TWITTER)),
                    child: Image.asset("ic_Twitter.png", height: 35, width: 35).paddingAll(10),
                  ).visible(getStringAsync(TWITTER).isNotEmpty),
                  InkWell(
                    onTap: () => redirectUrl(getStringAsync(FACEBOOK)),
                    child: Image.asset("ic_Fb.png", height: 35, width: 35).paddingAll(10),
                  ).visible(getStringAsync(FACEBOOK).isNotEmpty),
                  InkWell(
                    onTap: () => redirectUrl('tel:${getStringAsync(CONTACT)}'),
                    child: Image.asset("ic_CallRing.png", height: 35, width: 35, color: primaryColor).paddingAll(10),
                  ).visible(getStringAsync(CONTACT).isNotEmpty),
                  16.width
                ],
              ),
              Text(copyrightText!, style: secondaryTextStyle()),
              4.height,
              Container(
                height: AdSize.banner.height.toDouble(),
                child: AdWidget(
                  ad: BannerAd(
                    adUnitId: getBannerAdUnitId()!,
                    size: AdSize.banner,
                    request: AdRequest(),
                    listener: BannerAdListener(),
                  )..load(),
                ).visible(isAdsLoading == true),
              ),
            ],
          ),
        ),);
  }
}
