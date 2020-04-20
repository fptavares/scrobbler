import 'package:flutter/material.dart';
import 'package:rate_my_app/rate_my_app.dart';

class ReviewRequester {
  ReviewRequester._();

  factory ReviewRequester.instance() => _instance ??= ReviewRequester._();

  static ReviewRequester _instance;

  final _rateMyApp = RateMyApp(
    minDays: 7,
    minLaunches: 10,
    remindDays: 7,
    remindLaunches: 10,
    googlePlayIdentifier: 'io.github.fptavares.scrobbler',
    appStoreIdentifier: '1505776204',
  );

  Future<void> init() => _rateMyApp.init();

  void askForReview(BuildContext context) {
    if (_rateMyApp.shouldOpenDialog) {
      _rateMyApp.showRateDialog(context, ignoreIOS: false);
    }
  }
}
