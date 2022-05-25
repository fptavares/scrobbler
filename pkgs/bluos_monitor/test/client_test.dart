import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scrobbler_bluos_monitor/src/client.dart';
import 'package:scrobbler_bluos_monitor/src/playlist.dart';
import 'package:scrobbler_bluos_monitor/src/polling.dart';
import 'package:test/test.dart';

import 'test_data.dart';

Future<void> main() async {
  group('BluOS API client', () {
    void validateRequestAndState(
        BluOSAPIMonitor client, StatusRequestData requestData, BluOSAPITrack expectedTrack, int expectedPlaylistLength,
        {bool first = false}) {
      expect(requestData.method, equals('GET'));
      expect(
          requestData.url,
          equals(Uri.http('test:1234', '/Status', {
            'timeout': LongPollingSession.timeout.toString(),
            'etag': requestData.etag,
          })));
      if (first) {
        expect(requestData.isLoading, isTrue);
      }

      expect(client.isLoading, isFalse);
      expect(client.state!.isActive, isTrue);
      expect(client.state!.isPlaying, isTrue);
      expect(client.state!.playerState, equals(expectedTrack.state.playerState));
      expect(client.state!.etag, equals(expectedTrack.state.etag));
      expect(client.playlist.length, equals(expectedPlaylistLength));
      expect(client.playlist.last.title, equals(expectedTrack.title));
      expect(client.playlist.last.artist, equals(expectedTrack.artist));
      expect(client.playlist.last.album, equals(expectedTrack.album));
    }

    test('starts monitoring player', () async {
      final client = BluOSAPIMonitor.withNotifier(expectAsync0<void>(() {}, count: 3, max: -1));
      final polling = FakeLongPoll(client, 4);

      expect(client.isPolling, isFalse);
      expect(client.playlist, isEmpty);
      expect(client.playerName, isNull);
      expect(client.errorMessage, isNull);
      expect(client.state, isNull);
      expect(client.isLoading, isFalse);

      unawaited(client.start('test', 1234));

      validateRequestAndState(client, await polling.injectResponse(track1Status), track1Expected, 1, first: true);
      expect(client.isPolling, isTrue);
      validateRequestAndState(client, await polling.injectResponse(track1Status), track1Expected, 1);
      expect(client.isPolling, isTrue);
      validateRequestAndState(client, await polling.injectResponse(track2Status), track2Expected, 2);
      expect(client.isPolling, isTrue);
      validateRequestAndState(client, await polling.injectResponse(track3Status), track3Expected, 3);
      expect(client.isPolling, isTrue);

      await client.stop();
      await polling.close();
    });

    test('allows clearing the playlist', () async {});

    test('allows stopping', () async {
      final client = BluOSAPIMonitor.withNotifier(expectAsync0<void>(() {}, count: 3, max: -1));
      final polling = FakeLongPoll(client, 2);

      unawaited(client.start('test', 1234));

      validateRequestAndState(client, await polling.injectResponse(track1Status), track1Expected, 1, first: true);

      await Future.delayed(Duration(seconds: 1)); // make sure there's time for the next poll to start

      await client.stop();

      expect(client.isPolling, isFalse);
      expect(client.playlist.length, equals(1));

      validateRequestAndState(client, await polling.injectResponse(track2Status), track1Expected, 1);

      expect(client.isPolling, isFalse);
      expect(client.playlist.length, equals(1));

      await polling.close();
    });

    test('handles exceptions', () async {});
  });
}

class FakeLongPoll {
  FakeLongPoll(BluOSAPIMonitor client, int count) {
    client.httpClient = MockClient(expectAsync1<Future<http.Response>, http.Request>((request) async {
      print('Waiting for reponse to be emited for: ${request.url.toString()}');
      // get expected reponse body from test
      final body = await responseBodies.first;
      // stream status back to test
      statusStreamer.add(StatusRequestData(request.url, request.method, client.isLoading, client.state?.etag));

      return http.Response(body, 200, headers: {HttpHeaders.contentTypeHeader: 'text/xml; charset=utf-8'});
    }, count: count));
  }

  final statusStreamer = StreamController<StatusRequestData>.broadcast();
  final responseBodyStreamer = StreamController<String>.broadcast();

  Stream<StatusRequestData> get statusStream => statusStreamer.stream;
  Stream<String> get responseBodies => responseBodyStreamer.stream;

  Future<StatusRequestData> injectResponse(String trackStatusXml) async {
    // allow time for the fake HTTP client to received request
    await Future.delayed(Duration(seconds: 1));
    // inject response XML to fake HTTP client
    responseBodyStreamer.add(trackStatusXml);
    // wait for client to send back status
    final trackRequestData = await statusStream.first;
    print('Received status request data back');
    // allow time for client to process the response and update state
    await Future.delayed(Duration(seconds: 1));

    return trackRequestData;
  }

  Future<void> close() async {
    await responseBodyStreamer.close();
    await statusStreamer.close();
  }
}

class StatusRequestData {
  final Uri url;
  final String method;
  final bool isLoading;
  final String? etag;

  StatusRequestData(this.url, this.method, this.isLoading, this.etag);
}
