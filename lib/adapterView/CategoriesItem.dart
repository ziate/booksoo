import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutterapp/model/CategoriesListResponse.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';

// ignore: must_be_immutable
class CategoriesItem extends StatefulWidget {
  CategoriesListResponse categoriesListResponse;

  CategoriesItem(this.categoriesListResponse);

  @override
  _CategoriesItemState createState() => _CategoriesItemState();
}

class _CategoriesItemState extends State<CategoriesItem> {
  @override
  Widget build(BuildContext context) {
    return Html(
      data: widget.categoriesListResponse.name,
      style: {
        "body": Style(
          fontSize: FontSize(fontSizeLarge),
          color: appStore.appTextPrimaryColor,
        ),
      },
    ).paddingBottom(8);
  }
}
