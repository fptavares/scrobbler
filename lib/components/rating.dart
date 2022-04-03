import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rate_my_app/rate_my_app.dart';

class ReviewRequester {
  ReviewRequester({
    int minDays = 7,
    int minLaunches = 10,
  }) : _rateMyApp = RateMyApp(
          minDays: minDays,
          minLaunches: minLaunches,
          remindDays: 7,
          remindLaunches: 10,
          googlePlayIdentifier: 'io.github.fptavares.scrobbler',
          appStoreIdentifier: '1505776204',
        );

  final _log = Logger('ReviewRequester');

  final RateMyApp _rateMyApp;

  Future<void> init() => _rateMyApp.init().catchError((e, st) => _log.severe('Failed to initialize rateMyApp', e, st));

  void askForReview(BuildContext context) {
    try {
      if (_rateMyApp.shouldOpenDialog) {
        _rateMyApp.showRateDialog(context);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e, stackTrace) {
      _log.severe('Failed to ask for review', e, stackTrace);
    }
  }
}
