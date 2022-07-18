import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/activity/DashboardActivity.dart';
import 'package:flutterapp/activity/ErrorView.dart';
import 'package:flutterapp/activity/WebViewScreen.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/component/PaymentSheetComponent.dart';
import 'package:flutterapp/main.dart';
import 'package:flutterapp/model/LineItemModel.dart';
import 'package:flutterapp/model/MyCartResponse.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/utils/AppPermissionHandler.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/app_widget.dart';
import 'package:flutterapp/utils/flutterwave/core/navigation_controller.dart';
import 'package:flutterapp/utils/utils.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'BookDetails.dart';
import 'NoInternetConnection.dart';
import 'SignInScreen.dart';

class MyCart extends StatefulWidget {
  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  List<MyCartResponse> myCartList = [];
  bool mIsLoading = false;
  bool mWebViewPayment = false;
  List<String>? priceList = [];
  List<LineItemsRequest> lineItems = [];

  var total;

  late NavigationController controller;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    setState(() {
      mIsLoading = true;
    });
    getCartItem();
  }

  Future<void> getCartItem() async {
    await getCartBook().then((value) {
      Iterable mCart = value;
      myCartList.addAll(mCart.map((model) => MyCartResponse.fromJson(model)).toList());
      myCartList.forEach((element) {});
      myCartList.forEach((element) {
        total = total.toString().toDouble().validate() + element.price.toString().toDouble();
        setState(() {});
      });

      setState(() {
        mIsLoading = false;
      });

      setState(() {});
    }).catchError((onError) {
      setState(() {
        mIsLoading = false;
      });
    });
  }

  Future<void> removeFromCart(String? proId, int? index) async {
    setState(() {
      mIsLoading = true;
    });

    var request = {'pro_id': proId};

    await isNetworkAvailable().then((bool) async {
      if (bool) {
        await deletefromCart(request).then((res) async {
          myCartList.removeAt(index!);
          total = 0;
          getCartItem();

          setState(() {});
        }).catchError((onError) {
          ErrorView(
            message: onError.toString(),
          ).launch(context);
        });
      } else {
        NoInternetConnection().launch(context);
      }
    });
  }

  Future webViewPayment() async {
    if (Platform.isAndroid) {
      var result = await requestPermissionGranted(context, Permission.storage);
      if (result) {
        placeOrder();
      }
    } else {
      placeOrder();
    }
  }

  //WebView API
  Future placeOrder() async {
    myCartList.forEach((element) {
      var lineItem = LineItemsRequest();
      lineItem.product_id = element.proId;
      lineItem.quantity = element.quantity;
      lineItems.add(lineItem);

      setState(() {});
    });

    var request = {
      'currency': getStringAsync(CURRENCY_NAME),
      'customer_id': getIntAsync(USER_ID),
      'payment_method': "",
      'set_paid': false,
      'status': "pending",
      'transaction_id': "",
      'line_items': lineItems,
    };

    log(request);
    setState(() {
      mWebViewPayment = true;
    });
    await isNetworkAvailable().then(
      (bool) async {
        if (bool) {
          await bookOrderRestApi(request).then((response) {
            if (!mounted) return;
            processPaymentApi(response['id']);
          }).catchError((error) {
            setState(() {
              mIsLoading = false;
            });
            toast(error.toString());
          });
        } else {
          NoInternetConnection().launch(context);
        }
      },
    );
  }

  processPaymentApi(var mOrderId) async {
    log(mOrderId);
    var request = {"order_id": mOrderId};
    checkoutURLRestApi(request).then((res) async {
      if (!mounted) return;
      setState(() {
        mWebViewPayment = false;
      });
      bool isPaymentDone = await WebViewScreen(res['checkout_url'], "Payment").launch(context) ?? false;
      if (isPaymentDone) {
        setState(() {
          mWebViewPayment = true;
        });
        clearCart().then((response) {
          if (!mounted) return;
          setState(() {
            mWebViewPayment = false;
          });
          DashboardActivity().launch(context, isNewTask: true);
        }).catchError((error) {
          setState(() {
            mWebViewPayment = false;
          });
          toast(error.toString());
        });
      } else {
        deleteOrder(mOrderId).then((value) => {log(value)}).catchError((error) {});
      }
    }).catchError((error) {});
  }

  Future deleteOrder(orderId) async {
    if (!await isLoggedIn()) {
      SignInScreen().launch(context);
      return;
    }
    await isNetworkAvailable().then(
      (bool) async {
        if (bool) {
          await deleteOrderRestApi(orderId).then((res) async {}).catchError((onError) {
            ErrorView(
              message: onError.toString(),
            ).launch(context);
          });
        } else {
          NoInternetConnection().launch(context);
        }
      },
    );
  }

  Future<void> pay() async {
    if (getStringAsync(PAYMENT_METHOD) != "native") {
      webViewPayment();
    } else {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext _context) {
          return StatefulBuilder(builder: (BuildContext mContext, setState) {
            return PaymentSheetComponent(
              total.toString(),
              context,
              myCartList: myCartList,
            );
          });
        },
      );
    }
  }

  Future<void> clearBookCart() async {
    await clearCart().then((value) {
      setState(() {});
      log(value.toString());
    }).catchError((onError) {
      log(onError.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.scaffoldBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: appStore.appBarColor,
        elevation: 0,
        leading: backIcons(context),
        title: Row(
          children: [
            Text(
              keyString(context, 'lbl_my_cart')!,
              style: boldTextStyle(size: fontSizeLarge.toInt()),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView.builder(
              itemCount: myCartList.length,
              padding: EdgeInsets.all(16),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          myCartList[index].thumbnail.validate(),
                          fit: BoxFit.fill,
                          height: 100,
                          width: 75,
                        ).cornerRadiusWithClipRRect(12),
                        8.width,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            2.height,
                            Text(myCartList[index].name.validate(), textAlign: TextAlign.start, style: boldTextStyle(size: 18)),
                            4.height,
                            Text(
                              myCartList[index].stockStatus.validate(),
                              textAlign: TextAlign.start,
                              style: primaryTextStyle(color: Colors.green),
                            ),
                            4.height,
                            Text(
                              getStringAsync(CURRENCY_SYMBOL) + myCartList[index].price.validate(),
                              textAlign: TextAlign.start,
                              style: boldTextStyle(color: primaryColor),
                            ),
                          ],
                        )
                      ],
                    ),
                    Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: appStore.editTextBackColor,
                              borderRadius: radius(12),
                            ),
                            child: Icon(Icons.delete, color: appStore.iconColor))
                        .onTap(() {
                      removeFromCart(myCartList[index].proId.toString(), index);
                      setState(() {});
                    })
                  ],
                ).paddingBottom(16).onTap(() {
                  BookDetails(
                    myCartList[index].proId.toString(),
                  ).launch(context);
                });
              }).visible(!mIsLoading && myCartList.isNotEmpty),
          Text(keyString(context, 'lbl_empty_cart')!, style: boldTextStyle()).center().visible(!mIsLoading && myCartList.isEmpty),
          appLoaderWidget.center().visible(mIsLoading),
          CircularProgressIndicator().center().visible(mWebViewPayment),
        ],
      ),
      bottomNavigationBar: Container(
        height: 90,
        color: appStore.editTextBackColor,
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(keyString(context, 'lbl_total')!, style: primaryTextStyle()),
                Text(getStringAsync(CURRENCY_SYMBOL) + total.toString(), style: boldTextStyle(size: 18, color: primaryColor)),
              ],
            ),
            AppButton(
              onTap: () {
                pay();
              },
              text: keyString(context, 'lbl_check_out')!,
              textStyle: boldTextStyle(color: white),
              color: primaryColor,
            )
          ],
        ),
      ).visible(!mIsLoading && myCartList.isNotEmpty),
    );
  }
}
