import 'package:flutter/material.dart';

class AuthorDetailComponent extends StatefulWidget {
  static String tag = '/AuthorDetailComponent';

  @override
  AuthorDetailComponentState createState() => AuthorDetailComponentState();
}

class AuthorDetailComponentState extends State<AuthorDetailComponent> {
  @override
  void initState() {
    super.initState();
    init();
  }

  init() async{
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}