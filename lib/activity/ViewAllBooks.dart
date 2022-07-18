import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutterapp/activity/BookDetails.dart';
import 'package:flutterapp/adapterView/BookList.dart';
import 'package:flutterapp/model/AllBookListResponse.dart';
import 'package:flutterapp/model/CategoryModel.dart';
import 'package:flutterapp/model/DashboardResponse.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/Strings.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:nb_utils/nb_utils.dart';
import '../app_localizations.dart';
import '../main.dart';
import 'ErrorView.dart';
import 'NoInternetConnection.dart';

// ignore: must_be_immutable
class ViewAllBooks extends StatefulWidget {
  bool newestBook;
  bool futureBook;
  bool youMayLikeBook;
  bool suggestionBook;
  bool isCategoryBook;
  String categoryId;
  String? categoryName;
  String? title;

  @override
  _ViewAllBooksState createState() => _ViewAllBooksState();

  ViewAllBooks({this.newestBook = false, this.futureBook = false, this.isCategoryBook = false, this.categoryId = "", this.categoryName = "", this.suggestionBook = false, this.youMayLikeBook = false, this.title = ""});
}

class _ViewAllBooksState extends State<ViewAllBooks> {
  bool mIsLoading = false;
  int pageNumber = 1;
  int? totalPages = 1;
  String? title = "";
  String description = "";
  var mBookList = <DashboardBookInfo>[];
  bool isLastPage = false;
  var scrollController = new ScrollController();
  List<CategoryModel> mCategoryModel = [];

  var newestBookRequest = {
    "newest": "newest",
    "product_per_page": books_per_page,
  };

  var youMayLikeBookRequest = {
    'special_product': 'you_may_like',
    'product_per_page': books_per_page,
  };

  var suggestionBookRequest = {
    'special_product': 'suggested_for_you',
    'product_per_page': books_per_page,
  };

  var futureBookRequest = {
    'featured': 'product_visibility',
    'product_per_page': books_per_page,
  };

  @override
  void initState() {
    super.initState();
    getViewAllBookData();
    scrollController.addListener(() {
      scrollHandler();
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  scrollHandler() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !isLastPage) {
      pageNumber++;
      getViewAllBookData();
    }
  }

  Future getViewAllBookData() async {
    setState(() {
      mIsLoading = true;
    });
    var request;
    if (widget.newestBook) {
      request = newestBookRequest;
      title = newest_books;
      description = newest_books_desc;
    } else if (widget.youMayLikeBook) {
      request = youMayLikeBookRequest;
      title = you_may_like;
      description = you_may_like_desc;
    } else if (widget.suggestionBook) {
      request = suggestionBookRequest;
      title = books_for_you;
      description = book_store_desc;
    } else if (widget.futureBook) {
      request = futureBookRequest;
      title = featured_books;
      description = featured_books_desc;
    } else if (widget.isCategoryBook) {
      var catBookRequest = {
        "category": [widget.categoryId],
        'product_per_page': books_per_page,
      };
      fetchSubCategoryData();
      request = catBookRequest;
      title = widget.categoryName;
      description = featured_books_desc;
    }

    request.addAll({"page": pageNumber});

    await isNetworkAvailable().then((bool) async {
      if (bool) {
        await getAllBookRestApi(request).then(
          (res) {
            AllBookListResponse response = AllBookListResponse.fromJson(res);
            if (response.data!.length > 0) {
              mBookList.addAll(response.data!);
              isLastPage = false;
              totalPages = response.numOfPages;
            } else {
              isLastPage = true;
            }
            setState(() {
              mIsLoading = false;
            });
          },
        ).catchError((onError) {
          setState(() {
            mIsLoading = false;
          });
          log(onError.toString());
          ErrorView(
            message: onError.toString(),
          ).launch(context);
        });
      } else {
        setState(() {
          mIsLoading = false;
        });
        NoInternetConnection().launch(context);
      }
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        isLastPage = true;
        setState(() {
          mIsLoading = false;
        });
      });
    });
  }

  Future fetchSubCategoryData() async {
    setState(() {
      mIsLoading = true;
    });
    await getSubCategories(widget.categoryId).then((res) {
      if (!mounted) return;
      setState(() {
        Iterable mCategory = res;
        mCategoryModel = mCategory.map((model) => CategoryModel.fromJson(model)).toList();
      });
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        mIsLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget mSubCategory() {
      return HorizontalList(
        itemCount: mCategoryModel.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: EdgeInsets.only(right: 8),
            decoration: boxDecorationWithRoundedCorners(borderRadius: radius(8)),
            padding: EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Html(
              data: mCategoryModel[index].name!,
              shrinkWrap: true,
              style: {
                "body": Style(
                  fontSize: FontSize(fontSizeMedium),
                  color: appStore.isDarkModeOn ? primaryColor : textPrimaryColorGlobal,
                ),
              },
            ),
          ).onTap(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewAllBooks(
                  isCategoryBook: true,
                  categoryId: mCategoryModel[index].id.toString(),
                  categoryName: mCategoryModel[index].name!,
                ),
              ),
            );
          }).paddingOnly(top: 8, bottom: 8);
        },
      );
    }

    Widget mainView = SingleChildScrollView(
      padding: EdgeInsets.only(right: 8, left: 8),
      controller: scrollController,
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          mSubCategory().visible(mCategoryModel.isNotEmpty && mCategoryModel.isNotEmpty),
          GridView.builder(
            itemCount: mBookList.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: getChildAspectRatio(),
              crossAxisCount: getCrossAxisCount(),
            ),
            itemBuilder: (BuildContext context, int index) {
              return BookItem(mBookList[index]).onTap(() {
                BookDetails(
                  mBookList[index].id.toString(),
                ).launch(context);
              });
            },
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: appStore.scaffoldBackground,
      appBar: appBar(
        context,
        title: widget.title == "" ? title : widget.title,
      ) as PreferredSizeWidget?,
      body: Stack(
        children: [
          mainView.visible(mBookList.isNotEmpty),
          Text(keyString(context, "lbl_no_data_found")!, style: boldTextStyle()).center().visible(mBookList.isEmpty && !mIsLoading),
          (mBookList.isNotEmpty) ? Align(alignment: Alignment.bottomCenter, child: viewMoreDataLoader.visible(mIsLoading)) : Center(child: appLoaderWidget.center().visible(mIsLoading))
        ],
      ),
    );
  }
}
