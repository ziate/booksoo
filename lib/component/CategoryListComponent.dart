import 'package:flutter/material.dart';
import 'package:flutterapp/activity/ViewAllBooks.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:nb_utils/nb_utils.dart';

import '../app_localizations.dart';
import '../main.dart';

class CategoryListComponent extends StatefulWidget {
  var bookDetailsData;

  CategoryListComponent(this.bookDetailsData);

  @override
  CategoryListComponentState createState() => CategoryListComponentState();
}

class CategoryListComponentState extends State<CategoryListComponent> {
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
          keyString(context, "lbl_categories")!,
          style: TextStyle(
            fontSize: fontSizeLarge,
            color: appStore.appTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ).visible(widget.bookDetailsData.categories!.length > 0),
        8.height,
        Wrap(
          spacing: 8.0, // gap between adjacent chips
          runSpacing: 0.5, // gap between lines
          children: widget.bookDetailsData.categories!
              .map(
                (item) => GestureDetector(
                  child: Chip(
                    backgroundColor: appStore.isDarkModeOn ? appStore.scaffoldBackground : Color(0xffF0F4FF),
                    label: DefaultTextStyle.merge(
                      style: TextStyle(color: primaryColor, fontSize: fontSizeSmall),
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        //children: [Text(item.name)],
                        children: [Text('${HtmlUnescape().convert(item.name!)}')],
                      ),
                    ),
                  ),
                  onTap: () {
                    ViewAllBooks(
                      isCategoryBook: true,
                      categoryId: item.id.toString(),
                      categoryName: item.name,
                    ).launch(context);
                  },
                ),
              )
              .toList()
              .cast<Widget>(),
        ),
      ],
    );
  }
}
