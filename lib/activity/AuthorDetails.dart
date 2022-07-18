import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutterapp/adapterView/BookList.dart';
import 'package:flutterapp/model/AuthorListResponse.dart';
import 'package:flutterapp/model/DashboardResponse.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/admob_utils.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:flutterapp/utils/images.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_localizations.dart';
import '../main.dart';
import 'BookDetails.dart';
import 'ErrorView.dart';
import 'NoInternetConnection.dart';

// ignore: must_be_immutable
class AuthorDetails extends StatefulWidget {
  final AuthorListResponse? authorDetails;
  final AuthorResponse? authorDetails1;
  final bool? isDetail;
  String? url;
  String? fullName;

  AuthorDetails(this.url, this.fullName, {this.authorDetails, this.authorDetails1, this.isDetail = false});

  @override
  _AuthorDetailsState createState() => _AuthorDetailsState();
}

class _AuthorDetailsState extends State<AuthorDetails> {
  bool mIsLoading = false;
  List<DashboardBookInfo>? mAuthorBookList;

  @override
  void initState() {
    super.initState();
    getAuthorList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future getAuthorList() async {
    mIsLoading = true;
    await isNetworkAvailable().then((bool) async {
      if (bool) {
        await getAuthorBookListRestApi(widget.isDetail == true ? widget.authorDetails1!.id : widget.authorDetails!.id).then(
          (res) async {
            mIsLoading = false;
            Iterable mCategory = res;
            mAuthorBookList = mCategory.map((model) => DashboardBookInfo.fromJson(model)).toList();
            setState(() {});
          },
        ).catchError(
          (onError) {
            setState(() {
              mIsLoading = false;
            });
            ErrorView(
              message: onError.toString(),
            ).launch(context);
          },
        );
      } else {
        setState(() {
          mIsLoading = false;
        });
        NoInternetConnection().launch(context);
      }
    });
  }

  void mAuthorDetail() {
    log(widget.authorDetails1);
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext bc) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: boxDecorationWithRoundedCorners(borderRadius: radius(12), backgroundColor: appStore.editTextBackColor!),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  32.height,
                  Row(
                    children: [
                      CachedNetworkImage(
                        height: 50,
                        width: 50,
                        placeholder: (context, url) => Center(
                          child: bookLoaderWidget,
                        ),
                        imageUrl: widget.url.validate(),
                        fit: BoxFit.fill,
                      ).cornerRadiusWithClipRRect(25),
                      16.width,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.fullName!, style: boldTextStyle()).visible(widget.fullName!.isNotEmpty),
                          8.height,
                          Container(
                            width: 80,
                            height: 13.31399917602539,
                            child: RatingBar.builder(
                              allowHalfRating: true,
                              initialRating: (widget.authorDetails!.rating!.rating.validate() == "") ? 00.00 : double.parse(widget.authorDetails!.rating!.rating.validate()),
                              minRating: 1,
                              itemSize: 15.0,
                              direction: Axis.horizontal,
                              itemCount: 5,
                              itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                              onRatingUpdate: (double value) {},
                            ),
                          ).visible(widget.authorDetails!.rating!.rating.validate().isNotEmpty),
                        ],
                      )
                    ],
                  ),
                  16.height,
                  createRichText(list: [
                    TextSpan(text: keyString(context, 'lbl_store_name')!+': ', style: boldTextStyle()),
                    TextSpan(
                      text: widget.authorDetails!.storeName.validate(),
                      style: primaryTextStyle(),
                    ),
                  ]).visible(widget.authorDetails!.storeName!.isNotEmpty),
                  8.height,
                  createRichText(list: [
                    TextSpan(text: keyString(context, 'lbl_shop')!+': ', style: boldTextStyle()),
                    TextSpan(
                      text: widget.authorDetails!.shopUrl.validate(),
                      style: primaryTextStyle(color: blueColor),
                      recognizer: TapGestureRecognizer()..onTap = () async => await launch(widget.authorDetails!.shopUrl.validate()),
                    ),
                  ]).visible(widget.authorDetails!.shopUrl!.isNotEmpty),
                  8.height,
                  createRichText(list: [
                    TextSpan(text: keyString(context, 'lbl_description')! + ' ', style: boldTextStyle()),
                    TextSpan(
                      text: widget.authorDetails!.description!,
                      style: primaryTextStyle(),
                    ),
                  ]).visible(widget.authorDetails!.description!.isNotEmpty),
                  // Text(keyString(context, "lbl_no_data_found")!, style: boldTextStyle()).center().visible(widget.authorDetails!.description!.isEmpty),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: appStore.iconColor,
                  size: 24,
                ),
                onPressed: () => {Navigator.of(context).pop()},
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget blankView = Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(spacing_standard_30),
            child: Image.asset(ic_book_logo, width: 150),
          ),
          Text(keyString(context, 'lbl_book_not_available')!, style: boldTextStyle(size: 20)),
          10.height,
        ],
      ),
    );
    return Scaffold(
      backgroundColor: appStore.scaffoldBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: appStore.appBarColor,
        elevation: 0,
        leading: backIcons(context),
        actions: [
          IconButton(
                  onPressed: () {
                    mAuthorDetail();
                  },
                  icon: Icon(Icons.info_outline))
              .visible(widget.isDetail == false)
        ],
        title: Row(
          children: [
            Container(
              width: authorImageSize - 20,
              height: authorImageSize - 20,
              decoration: new BoxDecoration(
                shape: BoxShape.circle,
                image: new DecorationImage(
                  fit: BoxFit.fill,
                  image: new NetworkImage(widget.url!),
                ),
              ),
            ),
            10.width,
            Text(
              widget.fullName!,
              style: boldTextStyle(size: fontSizeLarge.toInt()),
            ),
          ],
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          (mAuthorBookList != null)
              ? mAuthorBookList!.isEmpty
                  ? blankView
                  : GridView.builder(
                      itemCount: mAuthorBookList!.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(top: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio: getChildAspectRatio(),
                        crossAxisCount: getCrossAxisCount(),
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          child: BookItem(mAuthorBookList![index]),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetails(
                                mAuthorBookList![index].id.toString(),
                              ),
                            ),
                          ),
                        );
                      })
              : appLoaderWidget.center().visible(mIsLoading),
        ],
      ),
      bottomNavigationBar: Container(
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
    );
  }
}
