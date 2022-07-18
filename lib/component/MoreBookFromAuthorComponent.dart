import 'package:flutter/material.dart';
import 'package:flutterapp/activity/BookDetails.dart';
import 'package:flutterapp/adapterView/UpsellBookList.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';

class MoreBookFromAuthorComponent extends StatefulWidget {
  var bookDetailsData;
  MoreBookFromAuthorComponent(this.bookDetailsData);

  @override
  MoreBookFromAuthorComponentState createState() => MoreBookFromAuthorComponentState();
}

class MoreBookFromAuthorComponentState extends State<MoreBookFromAuthorComponent> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          keyString(context, "lbl_more_books_from_author")!,
          style: TextStyle(fontSize: fontSizeLarge, color: appStore.appTextPrimaryColor, fontWeight: FontWeight.bold),
        ).paddingSymmetric(horizontal: 16),
        Container(
          height: bookViewHeight,
          margin: EdgeInsets.only(bottom: 40),
          child: ListView.builder(
            padding: EdgeInsets.only(right: 25),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return UpsellBookList(widget.bookDetailsData.upsellId![index]).onTap((){
                BookDetails(
                  widget.bookDetailsData.upsellId![index].id.toString()
                ).launch(context);
              });
            },
            itemCount: widget.bookDetailsData.upsellId!.length,
            shrinkWrap: true,
          ),
        )
      ],
    );
  }
}
