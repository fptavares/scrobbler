import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

final _ScrobblerAnalytics analytics = _ScrobblerAnalytics();

class _ScrobblerAnalytics extends FirebaseAnalytics {
  void logException(String description) {
    logEvent(name: 'exception', parameters: {'exDescription': description});
  }

  void logScrobbling({@required int numberOfAlbums}) {
    logEvent(name: 'scrobble', parameters: {'numberOfAlbums': numberOfAlbums});
  }

  void logSkippedOnboarding({@required double fromPage}) {
    logEvent(name: 'skippedOnboarding', parameters: {'fromPage': fromPage});
  }

  void logScrollToNextPage({@required int page}) {
    logEvent(name: 'scrollToNextPage', parameters: {'page': page});
  }

  void logPullToRefresh() {
    logEvent(name: 'pullToRefresh');
  }

  void logAccountSettingsOpen() {
    logEvent(name: 'accountSettingsOpen');
  }

  void logOnboargding() {
    logEvent(name: 'onboarding');
  }
}
