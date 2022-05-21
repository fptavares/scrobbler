import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

final ScrobblerAnalytics analytics = ScrobblerAnalytics.instance;

class ScrobblerAnalytics {
  static final ScrobblerAnalytics instance = ScrobblerAnalytics();

  @visibleForTesting
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  @visibleForTesting
  static FirebasePerformance performance = FirebasePerformance.instance;

  bool performanceEnabled = true;

  void logLogin({String? loginMethod}) => analytics.logLogin(loginMethod: loginMethod);
  void logAppOpen() => analytics.logAppOpen();

  void logException(String description) {
    analytics.logEvent(name: 'exception', parameters: {'exDescription': description});
  }

  void logScrobbling({required int numberOfAlbums, required int numberOfExclusions, required int offsetInMinutes}) {
    analytics.logEvent(
        name: 'scrobble',
        parameters: {'amount': numberOfAlbums, 'exclusions': numberOfExclusions, 'offset': offsetInMinutes});
  }

  void logScrobbleOptionsOpen({required int numberOfAlbums, required int maxCount}) {
    analytics.logEvent(name: 'open_scrobble_options', parameters: {'amount': numberOfAlbums, 'max_count': maxCount});
  }

  void logSkippedOnboarding({required double fromPage}) {
    analytics.logEvent(name: 'skip_onboarding', parameters: {'step': fromPage});
  }

  void logScrollToNextPage({required int page}) {
    analytics.logEvent(name: 'scroll_next_page', parameters: {'page': page});
  }

  void logPullToRefresh() {
    analytics.logEvent(name: 'pull_refresh');
  }

  void logAccountSettingsOpen() {
    analytics.logEvent(name: 'open_account_settings');
  }

  void logOnboargding() {
    analytics.logEvent(name: 'start_onboarding');
  }

  void logLoadAllForSearch({required int amount}) {
    analytics.logEvent(name: 'load_all_on_search', parameters: {'amount': amount});
  }

  void logTapLogo() {
    analytics.logEvent(name: 'tap_logo');
  }

  void logSearchScreen() {
    analytics.setCurrentScreen(screenName: 'search');
  }

  Trace newTrace(String name) => performance.newTrace(name);
}
