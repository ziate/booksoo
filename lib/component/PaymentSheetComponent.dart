import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterapp/activity/DashboardActivity.dart';
import 'package:flutterapp/activity/NoInternetConnection.dart';
import 'package:flutterapp/activity/SignInScreen.dart';
import 'package:flutterapp/activity/WebViewScreen.dart';
import 'package:flutterapp/app_localizations.dart';
import 'package:flutterapp/model/CheckoutResponse.dart';
import 'package:flutterapp/model/LineItemModel.dart';
import 'package:flutterapp/model/MyCartResponse.dart';
import 'package:flutterapp/model/OrderResponse.dart';
import 'package:flutterapp/network/rest_api_call.dart';
import 'package:flutterapp/utils/AppPermissionHandler.dart';
import 'package:flutterapp/utils/BookDetailWidget.dart';
import 'package:flutterapp/utils/Colors.dart';
import 'package:flutterapp/utils/Constant.dart';
import 'package:flutterapp/utils/flutterwave/core/TransactionCallBack.dart';
import 'package:flutterapp/utils/flutterwave/core/navigation_controller.dart';
import 'package:flutterapp/utils/flutterwave/flutterwave.dart';
import 'package:flutterapp/utils/flutterwave/models/requests/customer.dart';
import 'package:flutterapp/utils/flutterwave/models/requests/customizations.dart';
import 'package:flutterapp/utils/flutterwave/models/requests/standard_request.dart';
import 'package:flutterapp/utils/flutterwave/view/view_utils.dart';
import 'package:flutterapp/utils/utils.dart';
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_paystack/flutter_paystack.dart' as paystack;

import '../main.dart';

class PaymentSheetComponent extends StatefulWidget {
  final String? total;
  final BuildContext? context;
  var myCartList = <MyCartResponse>[];
  final String? mBookId;
  bool? mIsDetail = false;
  final Function? onCall;

  PaymentSheetComponent(
    this.total,
    this.context, {
    this.mBookId,
    this.mIsDetail,
    this.onCall,
    required this.myCartList,
  });

  @override
  PaymentSheetComponentState createState() => PaymentSheetComponentState();
}

class PaymentSheetComponentState extends State<PaymentSheetComponent> implements TransactionCallBack {
  List<LineItemsRequest> lineItems = [];
  int? _currentTimeValue = 1;
  int? paymentIndex;

  late Razorpay _razorPay;
  final plugin = paystack.PaystackPlugin();
  late NavigationController controller;

  var mPaymentList = ["RazorPay", "Pay Stack", "FlutterWave"];

  String? _cardNumber;
  String? _cvv;
  String selectedCurrency = "";
  int? _expiryMonth;
  int? _expiryYear;

  paystack.CheckoutMethod _method = paystack.CheckoutMethod.card;

  bool mIsLoading = false;

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() {
      init();
    });
  }

  Future<void> init() async {
    plugin.initialize(publicKey: paystackPublicKey);

    _razorPay = Razorpay();
    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  //RazorPay
  void handlePaymentSuccess(PaymentSuccessResponse response) async {
    Fluttertoast.showToast(msg: "SUCCESS: " + response.paymentId!);
    createNativeOrder("RazorPay");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "ERROR: " + response.code.toString() + " - " + response.message!);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "EXTERNAL_WALLET: " + response.walletName!);
  }

  //FlutterWave
  flutterWavePayment() {
    FlutterwaveViewUtils.showConfirmPaymentModal(
      context,
      getStringAsync(CURRENCY_SYMBOL),
      widget.total.toString(),
      style.getMainTextStyle(),
      style.getDialogBackgroundColor(),
      style.getDialogCancelTextStyle(),
      style.getDialogContinueTextStyle(),
      handlePayment,
    );
  }

  void handlePayment() async {
    final Customer customer = Customer(
      name: getStringAsync(USERNAME),
      phoneNumber: "",
      email: getStringAsync(USER_EMAIL),
    );

    final request = StandardRequest(
      txRef: DateTime.now().millisecond.toString(),
      amount: widget.total.toString(),
      customer: customer,
      paymentOptions: "card, payattitude",
      customization: Customization(title: "Test Payment"),
      isTestMode: true,
      publicKey: flutterWavePublicKey,
      currency: getStringAsync(CURRENCY_NAME),
      redirectUrl: "https://www.google.com",
    );
    log(request);

    try {
      Navigator.pop(widget.context!); // to remove confirmation dialog
      controller.startTransaction(request);
    } catch (error) {
      _showErrorAndClose(error.toString());
    }
  }

  @override
  onTransactionError() {
    _showErrorAndClose("transaction error");
  }

  @override
  onCancelled() {
    log("Transaction Cancelled");
    FlutterwaveViewUtils.showToast(context, "Transaction Cancelled");
  }

  @override
  onTransactionSuccess(String id, String txRef) {
    ChargeResponse(status: "success", success: true, transactionId: id, txRef: txRef);
    createNativeOrder("Flutterwave");
  }

  void _showErrorAndClose(final String errorMessage) {
    toast(errorMessage);
    // FlutterwaveViewUtils.showToast(widget.context!, errorMessage);
    Navigator.pop(widget.context!);
  }

  // PayStack Payment
  void _payStackPayment(BuildContext context) async {
    paystack.Charge charge = paystack.Charge()
      ..amount = (double.parse(widget.total.toString()) * 100.00).toInt() // In base currency
      ..email = getStringAsync(USER_EMAIL)
      ..currency = getStringAsync(CURRENCY_NAME)
      ..card = paystack.PaymentCard(number: _cardNumber, cvc: _cvv, expiryMonth: _expiryMonth, expiryYear: _expiryYear);

    charge.reference = _getReference();
    try {
      paystack.CheckoutResponse response = await plugin.checkout(
        context,
        method: _method,
        charge: charge,
        fullscreen: false,
      ); //_updateStatus(response.reference, response.message);
      if (response.message == "Success") {
        createNativeOrder("PayStackPayment");
      } else {
        snackBar(context, title: keyString(context, 'lbl_payment_failed').validate());
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }
    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
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

  // WebView API
  Future placeOrder() async {
    if (!await isLoggedIn()) {
      SignInScreen().launch(context);
      return;
    }
    int userId = getIntAsync(USER_ID);
    String currency = getStringAsync(CURRENCY_NAME);
    var request = {
      'currency': currency,
      'customer_id': userId,
      'payment_method': "",
      'set_paid': false,
      'status': "pending",
      'transaction_id': "",
      'line_items': [
        {
          "product_id": widget.mBookId,
          "quantity": 1,
        }
      ],
    };

    log(request);
    await isNetworkAvailable().then(
      (bool) async {
        if (bool) {
          await bookOrderRestApi(request).then((res) async {
            OrderResponse orderResponse = OrderResponse.fromJson(res);
            log(orderResponse.toString());
            var requestCheckout = {
              'order_id': orderResponse.id,
            };
            await checkoutURLRestApi(requestCheckout).then((res) async {
              CheckoutResponse checkoutResponse = CheckoutResponse.fromJson(res);
              log(checkoutResponse.toString());
              var results = await WebViewScreen(
                checkoutResponse.checkoutUrl.toString(),
                "Payment",
                orderId: orderResponse.id.toString(),
              ).launch(widget.context!);

              if (results != null && results.containsKey('orderCompleted')) {
                log('success');
                Navigator.pop(widget.context!, true);
              } else {
                toast(keyString(context, "lbl_payment_cancelled"));
                Navigator.pop(widget.context!, false);
              }
            });
          }).catchError((onError) {
            log(onError.toString());
          });
        } else {
          NoInternetConnection().launch(context);
        }
      },
    );
  }

  // Native Payment API
  Future createNativeOrder(String name, {String status = "completed"}) async {
    if (!await isLoggedIn()) {
      SignInScreen().launch(context);
      return;
    }

    setState(() {
      mIsLoading = true;
    });

    widget.myCartList.forEach((element) {
      var lineItem = LineItemsRequest();
      lineItem.product_id = element.proId;
      lineItem.quantity = element.quantity;
      lineItems.add(lineItem);

      setState(() {});
    });

    var request = {
      'currency': getStringAsync(CURRENCY_NAME),
      'customer_id': getIntAsync(USER_ID),
      'payment_method': name,
      'set_paid': true,
      'status': status,
      'transaction_id': "",
      'line_items': widget.mIsDetail == true
          ? [
              {
                "product_id": widget.mBookId,
                "quantity": 1,
              }
            ]
          : lineItems
    };

    await isNetworkAvailable().then(
      (bool) async {
        if (bool) {
          await bookOrderRestApi(request).then((res) async {
            // OrderResponse orderResponse = OrderResponse.fromJson(res);
            // log('success: ${orderResponse.toString()}');
            //
            DashboardActivity().launch(widget.context!, isNewTask: true);
            //
          }).catchError((onError) {
            log(onError.toString());
            Navigator.pop(widget.context!, false);
          });
        } else {
          Navigator.pop(widget.context!, false);
          NoInternetConnection().launch(context);
        }
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller = NavigationController(Client(), style, this);
    return WillPopScope(
      onWillPop: () {
        finish(widget.context!, false);
        return Future.value(false);
      },
      child: SingleChildScrollView(
        child: Container(
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: appStore.editTextBackColor!,
            borderRadius: BorderRadius.only(topRight: Radius.circular(12), topLeft: Radius.circular(12)),
          ),
          padding: EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                children: <Widget>[
                  if (getStringAsync(PAYMENT_METHOD) == "native")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(keyString(context, "lbl_choose_payment_method")!, style: boldTextStyle(size: 18)),
                        IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            finish(widget.context!, false);
                          },
                          icon: Icon(Icons.close, color: appStore.iconColor, size: 24),
                        )
                      ],
                    ),
                  if (getStringAsync(PAYMENT_METHOD) == "native") Divider(),
                  if (getStringAsync(PAYMENT_METHOD) == "native")
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      itemBuilder: (context, index) {
                        return Theme(
                          data: Theme.of(context).copyWith(unselectedWidgetColor: Theme.of(context).iconTheme.color),
                          child: RadioListTile(
                            dense: true,
                            activeColor: primaryColor,
                            contentPadding: EdgeInsets.all(0),
                            value: index,
                            groupValue: _currentTimeValue,
                            onChanged: (dynamic ind) {
                              _currentTimeValue = ind;
                              paymentIndex = index;
                              setState(() {});
                            },
                            title: Text(mPaymentList[index], style: primaryTextStyle()),
                          ),
                        );
                      },
                      itemCount: mPaymentList.length,
                    ),
                  AppButton(
                    onTap: () {
                      if (getStringAsync(PAYMENT_METHOD) == "native") {
                        Navigator.pop(context);
                        if (_currentTimeValue == 0) openCheckout(_razorPay, widget.total.toString().validate());
                        if (_currentTimeValue == 1) _payStackPayment(context);
                        if (_currentTimeValue == 2) flutterWavePayment();
                      } else {
                        webViewPayment();
                      }
                    },
                    text: keyString(context, 'lbl_pay')! + ' ' + getStringAsync(CURRENCY_SYMBOL) + widget.total.toString(),
                    textStyle: boldTextStyle(color: white),
                    color: primaryColor,
                  ).center(),
                ],
              ).visible(!mIsLoading),
              CircularProgressIndicator().center().visible(mIsLoading)
            ],
          ),
        ),
      ),
    );
  }
}
