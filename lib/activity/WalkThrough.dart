import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterapp/activity/DashboardActivity.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:flutterapp/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

class AppWalkThrough extends StatefulWidget {
  static var tag = "/AppWalkThrough";

  @override
  AppWalkThroughState createState() => AppWalkThroughState();
}

class AppWalkThroughState extends State<AppWalkThrough> {
  int currentIndexPage = 0;

  PageController _controller = new PageController();

  @override
  void initState() {
    super.initState();
    currentIndexPage = 0;
  }

  // ignore: missing_return
  Future onPrev() async {
    setState(() {
      if (currentIndexPage >= 1) {
        currentIndexPage = currentIndexPage - 1;
        _controller.jumpToPage(currentIndexPage);
      }
    });
  }

  // ignore: missing_return
  Future onNext() async {
    if (currentIndexPage < 3) {
      currentIndexPage = currentIndexPage + 1;
      _controller.jumpToPage(currentIndexPage);
    } else {
      setValue(IS_FIRST_TIME, false);
      DashboardActivity().launch(context, isNewTask: true);
    }
  }

  Future<void> onSkip() async {
    setValue(IS_FIRST_TIME, false);
    DashboardActivity().launch(context, isNewTask: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          PageView(
            controller: _controller,
            children: <Widget>[
              WalkThrough(
                textContent: keyString(context, 'lbl_welcome'),
                walkImg: ic_walk1,
                desc: keyString(context, 'newest_books_desc'),
              ),
              WalkThrough(
                textContent: keyString(context, 'lbl_purchase_online'),
                walkImg: ic_walk2,
                desc: keyString(context, 'newest_books_desc'),
              ),
              WalkThrough(
                textContent: keyString(context, 'lbl_push_notification'),
                walkImg: ic_walk3,
                desc: keyString(context, 'newest_books_desc'),
              ),
              WalkThrough(
                textContent: keyString(context, 'lbl_enjoy_offline_support'),
                walkImg: ic_walk4,
                desc: keyString(context, 'newest_books_desc'),
              ),
            ],
            onPageChanged: (value) {
              setState(() => currentIndexPage = value);
            },
          ),
          Container(
            height: 85,
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Align(
                  child: currentIndexPage == 0
                      ? SizedBox()
                      : Button(
                          textContent: keyString(context, 'lbl_prev'),
                          onPressed: onPrev),
                ),
                DotsIndicator(
                  dotsCount: 4,
                  position: currentIndexPage.toDouble(),
                  decorator: DotsDecorator(
                    color: Color(0XFFDADADA),
                    activeColor: primaryColor,
                  ),
                ),
                Button(
                    textContent: keyString(context, 'lbl_next'),
                    onPressed: onNext,
                    isStroked: true),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 24,
            child: TextButton(
              onPressed: () { onSkip();},
              child: Text(
                keyString(context, 'lbl_skip')!,
                style: primaryTextStyle(color: primaryColor),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class WalkThrough extends StatelessWidget {
  final String? textContent;
  final String? walkImg;
  final String? desc;

  WalkThrough({Key? key, this.textContent, this.walkImg, this.desc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: context.height() * 0.05),
          height: context.height() * 0.5,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Image.asset(walkImg!,
                  width: context.width() * 0.8, height: context.height() * 0.4)
            ],
          ),
        ),
        SizedBox(
          height: context.height() * 0.08,
        ),
        Text(
          textContent!,
          style: boldTextStyle(size: 20),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28.0, right: 28.0),
          child: Text(
            desc!,
            maxLines: 3,
            textAlign: TextAlign.center,
            style: primaryTextStyle(size: 16),
          ),
        )
      ],
    );
  }
}
