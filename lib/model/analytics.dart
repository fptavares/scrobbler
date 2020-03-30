import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

final _ScrobblerAnalytics analytics = _ScrobblerAnalytics();

class _ScrobblerAnalytics extends FirebaseAnalytics {
  void logException(String description) {
    logEvent(name: 'exception', parameters: {'exDescription': description});
  }

  void logScrobbling(
      {@required int numberOfAlbums,
      @required int numberOfExclusions,
      @required int offsetInMinutes}) {
    logEvent(name: 'scrobble', parameters: {
      'amount': numberOfAlbums,
      'exclusions': numberOfExclusions,
      'offset': offsetInMinutes
    });
  }

  void logScrobbleOptionsOpen(
      {@required int numberOfAlbums, @required int maxCount}) {
    logEvent(name: 'open_scrobble_options', parameters: {
      'amount': numberOfAlbums,
      'max_count': maxCount
    });
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

class MetricHttpClient extends BaseClient {
  MetricHttpClient(this.innerClient);

  Client innerClient;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final metric = FirebasePerformance.instance
        .newHttpMetric(request.url.toString(), HttpMethod.Get);

    await metric.start();

    StreamedResponse response;
    try {
      response = await innerClient.send(request);
      metric
        ..responseContentType = response.headers['Content-Type']
        ..httpResponseCode = response.statusCode;

      if (response.contentLength != null) {
        metric.responsePayloadSize = response.contentLength;
      }
      if (request.contentLength != null) {
        metric.requestPayloadSize = request.contentLength;
      }
    } finally {
      await metric.stop();
    }

    return response;
  }
}