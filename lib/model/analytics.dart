import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

final _ScrobblerAnalytics analytics = _ScrobblerAnalytics();

class _ScrobblerAnalytics extends FirebaseAnalytics {
  void logException(String description) {
    logEvent(name: 'exception', parameters: {'exDescription': description});
  }

  void logScrobbling({@required int numberOfAlbums}) {
    logEvent(name: 'scrobble', parameters: {'amount': numberOfAlbums});
  }

  void logSkippedOnboarding({@required double fromPage}) {
    logEvent(name: 'skip_onboarding', parameters: {'step': fromPage});
  }

  void logScrollToNextPage({@required int page}) {
    logEvent(name: 'scroll_next_page', parameters: {'page': page});
  }

  void logPullToRefresh() {
    logEvent(name: 'pull_refresh');
  }

  void logAccountSettingsOpen() {
    logEvent(name: 'open_account_settings');
  }

  void logOnboargding() {
    logEvent(name: 'start_onboarding');
  }

  void logLoadAllForSearch({@required int amount}) {
    logEvent(name: 'load_all_on_search', parameters: {'amount': amount});
  }

  void logTapLogo() {
    logEvent(name: 'tap_logo');
  }
}
