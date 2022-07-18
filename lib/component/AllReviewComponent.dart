import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutterapp/activity/ErrorView.dart';
import 'package:flutterapp/activity/NoInternetConnection.dart';
import 'package:flutterapp/activity/ReviewScreen.dart';
import 'package:flutterapp/activity/SignInScreen.dart';
import 'package:flutterapp/adapterView/Review.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/main.dart';
import 'package:flutterapp/model/DashboardResponse.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/utils.dart';
import 'package:nb_utils/nb_utils.dart';

class AllReviewComponent extends StatefulWidget {
  var mBookDetailsData;
  bool? mIsFreeBook;
  bool? isLoginIn;
  String bookId;
  Function? onUpdate;

  AllReviewComponent(this.mBookDetailsData, this.mIsFreeBook, this.isLoginIn, this.bookId, {this.onUpdate});

  @override
  AllReviewComponentState createState() => AllReviewComponentState();
}

class AllReviewComponentState extends State<AllReviewComponent> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  String getReviewCount() {
    if (widget.mBookDetailsData.reviews != null) {
    } else {
      return "0";
    }
    return widget.mBookDetailsData.reviews!.length.toString();
  }

  double getAvgReviewCount(List<Reviews> reviews) {
    double totalReview = 0.0;
    for (var i = 0; i < reviews.length; i++) {
      if (reviews[i].ratingNum != "") totalReview = totalReview + double.parse(reviews[i].ratingNum!);
    }
    if (totalReview == 0.0)
      return 0.0;
    else
      return double.parse((totalReview / reviews.length).toStringAsFixed(2));
  }

  Future showDialog1(BuildContext context) async {
    var ratings = 0.0;
    var reviewCont = TextEditingController();
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: appStore.scaffoldBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), //this right here
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  keyString(context, "lbl_how_much_do_you_love")!,
                  style: TextStyle(fontSize: mobile_font_size_large, color: appStore.appTextPrimaryColor, fontWeight: FontWeight.bold),
                ),
                8.height,
                Text(
                  keyString(context, "lbl_more_than_i_can_say")!,
                  style: TextStyle(
                    fontSize: fontSizeNormal,
                    color: appStore.textSecondaryColor,
                  ),
                ),
                8.height,
                RatingBar.builder(
                  allowHalfRating: true,
                  initialRating: 0,
                  minRating: 1,
                  itemSize: 30.0,
                  direction: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  unratedColor: Colors.amber.withOpacity(0.3),
                  onRatingUpdate: (double value) {
                    ratings = value;
                  },
                ),
                8.height,
                TextFormField(
                  style: TextStyle(
                    fontSize: 18,
                    color: appStore.appTextPrimaryColor,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(26, 18, 4, 18),
                    hintText: keyString(context, "lbl_write_review"),
                    filled: true,
                    hintStyle: secondaryTextStyle(color: appStore.textSecondaryColor),
                    fillColor: appStore.editTextBackColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: appStore.editTextBackColor!, width: 0.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: appStore.editTextBackColor!, width: 0.0),
                    ),
                  ),
                  controller: reviewCont,
                  maxLines: 3,
                  minLines: 3,
                ),
                16.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor, style: BorderStyle.solid),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        keyString(context, "lbl_cancel")!,
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                    20.width,
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () {
                        hideKeyboard(context);
                        Navigator.of(context).pop();
                        postReviewApi(reviewCont.text, ratings);
                      },
                      child: Text(
                        keyString(context, "lbl_submit")!,
                        style: TextStyle(color: whileColor),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Review API
  Future postReviewApi(review, rating) async {
    if (!await isLoggedIn()) {
      SignInScreen().launch(context);
      return;
    }
    String firstName = getStringAsync(FIRST_NAME) + " " + getStringAsync(LAST_NAME);
    int userId = getIntAsync(USER_ID);
    String emailId = getStringAsync(USER_EMAIL);
    var request = {'product_id': widget.bookId, 'reviewer': firstName, 'user_id': userId, 'reviewer_email': emailId, 'review': review, 'rating': rating};
    // mReviewIsLoading = true;
    await isNetworkAvailable().then((bool) async {
      if (bool) {
        await bookReviewRestApi(request).then((res) async {
          // mReviewIsLoading = false;
          // widget.onUpdate!.call();
        }).catchError((onError) {
          setState(() {
            // mReviewIsLoading = false;
          });
          ErrorView(
            message: onError.toString(),
          ).launch(context);
        });
      } else {
        setState(() {
          // mReviewIsLoading = false;
        });
        NoInternetConnection().launch(context);
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              keyString(context, "lbl_high_recommend")!,
              style: TextStyle(fontSize: fontSizeLarge, color: appStore.appTextPrimaryColor, fontWeight: FontWeight.bold),
            ),
            IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  ReviewScreen(widget.mBookDetailsData.id).launch(context);
                },
                icon: Icon(
                  Icons.chevron_right,
                  color: appStore.iconSecondaryColor,
                  size: 30.0,
                  textDirection: appStore.isRTL ? TextDirection.rtl : TextDirection.ltr,
                )),
          ],
        ).paddingOnly(left: 16, right: 8).visible(widget.mBookDetailsData.reviewsAllowed!),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(getAvgReviewCount(widget.mBookDetailsData.reviews!).toString(), style: primaryTextStyle(size: 36)),
                8.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingBar.builder(
                      initialRating: getAvgReviewCount(widget.mBookDetailsData.reviews!),
                      allowHalfRating: true,
                      minRating: 0,
                      itemSize: 15.0,
                      direction: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (double value) {},
                    ),
                    4.height,
                    Text("(" + getReviewCount() + " " + keyString(context, "lbl_reviews")! + ")", style: secondaryTextStyle()).visible(widget.mBookDetailsData != null),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () => {showDialog1(context)},
              child: Text(
                keyString(context, "lbl_add_review")!,
                style: TextStyle(color: whileColor),
              ),
            ).visible(widget.isLoginIn! && (widget.mBookDetailsData.isPurchased! || widget.mIsFreeBook!)),
          ],
        ).paddingSymmetric(horizontal: 16).visible(widget.mBookDetailsData.reviewsAllowed!),
        (widget.mBookDetailsData.reviewsAllowed!)
            ? Container(
                height: 185,
                child: ListView.builder(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return new GestureDetector(
                      child: Review(widget.mBookDetailsData.reviews![index]),
                    );
                  },
                  itemCount: widget.mBookDetailsData.reviews?.length,
                  shrinkWrap: true,
                ),
              ).visible(widget.mBookDetailsData.reviews!.length > 0)
            : Container(
                height: 100,
                child: Center(
                  child: Text(
                    keyString(context, "lbl_no_review_found")!,
                    style: TextStyle(
                      fontSize: fontSizeSmall,
                      color: appStore.textSecondaryColor,
                    ),
                  ),
                ),
              ).visible(widget.mBookDetailsData.reviewsAllowed!),
      ],
    );
  }
}
