import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:logging/logging.dart';

class ReviewRequester {
  ReviewRequester._();

  static final ReviewRequester instance = ReviewRequester._();

  @visibleForTesting
  static InAppReview appReview = InAppReview.instance;

  static final _log = Logger('ReviewRequester');

  Future<void> tryToAskForAppReview() async {
    try {
      if (await appReview.isAvailable()) {
        await appReview.requestReview();
      }
    } catch (e, stackTrace) {
      _log.severe('Requesting app review failed.', e, stackTrace);
    }
  }
}
