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
    test('starts monitoring player', () async {
      final polling = FakePollingResponder(4);
      final client = polling.client;

      expect(client.canReload, isFalse);
      expect(client.isPolling, isFalse);
      expect(client.playlist, isEmpty);
      expect(client.playerName, isNull);
      expect(client.errorMessage, isNull);
      expect(client.state, isNull);
      expect(client.isLoading, isFalse);

      polling.startClient();

      await polling.emitResponseAndValidate(track1Xml, track1Expected, 1, first: true);
      expect(client.isPolling, isTrue);

      await polling.emitResponseAndValidate(track1Xml, track1Expected, 1);
      expect(client.isPolling, isTrue);

      await polling.emitResponseAndValidate(track2Xml, track2Expected, 2);
      expect(client.isPolling, isTrue);

      await polling.emitResponseAndValidate(track3Xml, track3Expected, 3);
      expect(client.isPolling, isTrue);

      await polling.close();
    });

    test('allows clearing the playlist', () async {
      final polling = FakePollingResponder(3);
      final client = polling.client;

      polling.startClient();

      await polling.emitResponseAndValidate(track1Xml, track1Expected, 1, first: true);
      await polling.emitResponseAndValidate(track2Xml, track2Expected, 2);

      await client.clear(client.playlist.first.timestamp);

      expect(client.playlist.length, equals(1));
      expect(client.playlist.first.title, equals(track2Expected.title));

      await polling.emitResponseAndValidate(track2Xml, track2Expected, 1);

      await polling.close();
    });

    test('allows stopping', () async {
      final polling = FakePollingResponder(2);
      final client = polling.client;

      polling.startClient();

      await polling.emitResponseAndValidate(track1Xml, track1Expected, 1, first: true);

      await Future.delayed(Duration(seconds: 1)); // make sure there's time for the next poll to start

      await client.stop();

      expect(client.isPolling, isFalse);
      expect(client.playlist.length, equals(1));

      // validate that after response is reveived, it's ignored because the client was stopped
      await polling.emitResponseAndValidate(track2Xml, track1Expected, 1);

      expect(client.isPolling, isFalse);
      expect(client.playlist.length, equals(1));

      await polling.close();
    });

    test('supports stopping automatically when player stops', () async {
      final polling = FakePollingResponder(2);
      final client = polling.client;

      polling.startClient(stopWhenPlayerStops: true);

      await polling.emitResponseAndValidate(track1Xml, track1Expected, 1, first: true);

      expect(client.isPolling, isTrue);
      expect(client.state!.isPlaying, isTrue);

      await polling.emitTrack(stoppedXml);

      expect(client.isPolling, isFalse);
      expect(client.state!.isStopped, isTrue);
      expect(client.playlist.length, equals(1));

      await polling.close();
    });

    Future<void> testError(
        {int? statusCode, String? badResponse, bool shouldStop = false, bool noDelay = false}) async {
      final polling = FakePollingResponder(noDelay ? 2 : 1);
      final client = polling.client;

      expect(client.errorMessage, isNull);

      polling.startClient();

      if (statusCode != null) {
        await polling.emitError(statusCode);
      } else if (badResponse != null) {
        await polling.emitTrack(badResponse);
      }
      await polling.validateErrorHandling(shouldStop: shouldStop, noDelay: noDelay);

      await polling.close();
    }

    test('handles exceptions', () async {
      await Future.wait([
        testError(badResponse: 'bad XML'),
        testError(badResponse: '<notstatus>valid but not right element</notstatus>'),
        testError(badResponse: '<status><album>missing mandatory</album><state>play</state></status>', noDelay: true),
        testError(statusCode: 403, shouldStop: true),
        testError(statusCode: 500),
        testError(badResponse: 'TimeoutException', noDelay: true),
        testError(badResponse: 'SocketException'),
      ]);
    });
  });
}

class FakePollingResponder {
  FakePollingResponder(int count) {
    client = BluOSAPIMonitor.withNotifier(expectAsync0<void>(() => _notificationStreamer.add(true), count: 3, max: -1));
    client.httpClient = MockClient(expectAsync1<Future<http.Response>, http.Request>((request) async {
      // get expected reponse body from test
      final response = await _responses.first;
      // stream status back to test
      _statusStreamer.add(StatusRequestData(request.url, request.method, client.isLoading, client.state?.etag));
      // using body here to indicate errors to throw
      if (response.body == 'SocketException') {
        throw SocketException('cannot connect');
      } else if (response.body == 'TimeoutException') {
        throw TimeoutException('timed out');
      }

      return response;
    }, count: count));
  }

  late final BluOSAPIMonitor client;

  final _statusStreamer = StreamController<StatusRequestData>();
  final _responseStreamer = StreamController<http.Response>.broadcast();
  final _notificationStreamer = StreamController<bool>.broadcast();

  Stream<http.Response> get _responses => _responseStreamer.stream;
  Stream<bool> get _notifications => _notificationStreamer.stream;

  final _statuses = <StatusRequestData>[];

  void startClient({bool? stopWhenPlayerStops}) {
    _statusStreamer.stream.listen(_statuses.add);
    unawaited(client.start('test', 1234, 'Test Player', stopWhenPlayerStops));
  }

  Future<void> emitTrack(String trackStatusXml) {
    return _emitReponse(http.Response(
      trackStatusXml,
      200,
      headers: {HttpHeaders.contentTypeHeader: 'text/xml; charset=utf-8'},
    ));
  }

  Future<void> emitError(int statusCode) {
    return _emitReponse(http.Response('', statusCode));
  }

  Future<void> _emitReponse(http.Response response) async {
    // allow time for the fake HTTP client to received request
    await Future.delayed(Duration(seconds: 1));
    // inject response XML to fake HTTP client
    _responseStreamer.add(response);
    // wait for client to process the response and update state
    await _notifications.first;
  }

  Future<void> close() async {
    await client.stop();
    await _responseStreamer.close();
    await _statusStreamer.close();
    await _notificationStreamer.close();
  }

  Future<void> emitResponseAndValidate(String trackStatusXml, BluOSAPITrack expectedTrack, int expectedPlaylistLength,
      {bool first = false}) async {
    await emitTrack(trackStatusXml);

    final requestData = _statuses.last;

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

  Future<void> validateErrorHandling({required bool shouldStop, required bool noDelay}) async {
    expect(client.errorMessage, isNotNull);
    print(client.errorMessage);
    expect(client.playlist, isEmpty);

    if (shouldStop) {
      expect(client.isPolling, isFalse);
    } else if (noDelay) {
      expect(client.isPolling, isTrue);
      await emitResponseAndValidate(track1Xml, track1Expected, 1);
      expect(client.errorMessage, isNull);
    } else {
      expect(client.isPolling, isTrue);

      // client has a retry delay of 30 sec
      unawaited(emitTrack(track1Xml).catchError((_) {}));
      // wait 5 seconds
      await Future.delayed(Duration(seconds: 5));

      // ensure no new polling happened yet
      expect(client.isPolling, isTrue);
      expect(client.errorMessage, isNotNull);
      expect(client.playlist, isEmpty);
    }
  }
}

class StatusRequestData {
  final Uri url;
  final String method;
  final bool isLoading;
  final String? etag;

  StatusRequestData(this.url, this.method, this.isLoading, this.etag);
}
