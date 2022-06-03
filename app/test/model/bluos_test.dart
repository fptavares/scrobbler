import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:scrobbler/components/error.dart';
import 'package:scrobbler/model/bluos.dart';
import 'package:scrobbler_bluos_monitor/scrobbler_bluos_monitor.dart';
import 'package:test/test.dart';

import '../bluos_test_data.dart';
import '../mocks/cache_mocks.dart' as mocks;
import '../mocks/model_mocks.dart';

Future<void> main() async {
  group('BluOS monitor', () {
    test('updates the monitor address', () async {
      final bluos = BluOS();
      expect(bluos.externalMonitorClientInstance, isNull);

      const testAddress = 'monitor:1234';

      // set external monitor
      bluos.updateMonitorAddress(testAddress);
      expect(bluos.externalMonitorClientInstance, isNotNull);
      expect(bluos.externalMonitorClientInstance!.monitorAddress, equals(testAddress));

      // check the external monitor is used when starting
      await expectExternalMonitorRequest(() => bluos.start('test', 4321), equals('http://$testAddress/start/test/4321'),
          BluOSTestData.pollingEmptyPlaylist, bluos);

      // empty address should unset address
      bluos.updateMonitorAddress('');
      expect(bluos.externalMonitorClientInstance, isNull);
      bluos.updateMonitorAddress(null);
      expect(bluos.externalMonitorClientInstance, isNull);
    });

    test('updates monitor address even if already polling', () async {
      final bluos = BluOS();
      expect(bluos.externalMonitorClientInstance, isNull);

      const testAddress1 = 'monitor1:1234';
      bluos.updateMonitorAddress(testAddress1);
      expect(bluos.externalMonitorClientInstance, isNotNull);
      expect(bluos.externalMonitorClientInstance!.monitorAddress, equals(testAddress1));

      // check the monitor1 is used when starting
      await expectExternalMonitorRequest(() => bluos.start('test', 4321),
          equals('http://$testAddress1/start/test/4321'), BluOSTestData.pollingEmptyPlaylist, bluos);

      final nextRequestData = fakeNextMonitorRequest(bluos, BluOSTestData.notPollingEmptyPlaylist);

      // update monitor address
      const testAddress2 = 'monitor2:6789';
      bluos.updateMonitorAddress(testAddress2);
      expect(bluos.externalMonitorClientInstance, isNotNull);
      expect(bluos.externalMonitorClientInstance!.monitorAddress, equals(testAddress2));

      // check the monitor1 is still the one stopped
      await bluos.stop();
      expect(nextRequestData.requestUrl.toString(), equals('http://$testAddress1/stop'));

      // check the monitor2 is now used when starting
      await expectExternalMonitorRequest(() => bluos.start('test', 4321),
          equals('http://$testAddress2/start/test/4321'), BluOSTestData.pollingEmptyPlaylist, bluos);

      // check the monitor2 is still polling
      await expectExternalMonitorRequest(
          bluos.refresh, equals('http://$testAddress2/playlist'), BluOSTestData.pollingEmptyPlaylist, bluos);

      // check the monitor2 is still stopped
      await expectExternalMonitorRequest(
          bluos.stop, equals('http://$testAddress2/stop'), BluOSTestData.notPollingEmptyPlaylist, bluos);
    });

    test('processes and stores playlist', () async {
      final bluos = BluOS();
      expect(bluos.externalMonitorClientInstance, isNull);

      const testAddress = 'monitor:1234';

      // setting external monitor
      bluos.updateMonitorAddress(testAddress);
      expect(bluos.isPolling, isFalse);
      expect(bluos.playlist, isEmpty);
      expect(bluos.playerName, isNull);
      expect(bluos.errorMessage, isNull);

      // check the external monitor is used and that the data stored matches
      await expectExternalMonitorRequest(() => bluos.start('test', 4321), equals('http://$testAddress/start/test/4321'),
          BluOSTestData.pollingWithPlaylist, bluos);
      expect(bluos.canReload, isTrue);
      expect(bluos.isPolling, isTrue);
      expect(bluos.playlist, isNotEmpty);
      expect(bluos.playerName, equals(BluOSTestData.pollingWithPlaylist['playerName']));
      expect(bluos.errorMessage, isNull);
      checkPlaylistMatches(bluos.playlist, BluOSTestData.pollingWithPlaylist['playlist']);

      // check that refresh gets the correct data inclusing the error message
      await expectExternalMonitorRequest(
          bluos.refresh, equals('http://$testAddress/playlist'), BluOSTestData.pollingWithPlaylistAndError, bluos);
      expect(bluos.canReload, isTrue);
      expect(bluos.isPolling, isTrue);
      expect(bluos.playlist, isNotEmpty);
      expect(bluos.playerName, equals(BluOSTestData.pollingWithPlaylistAndError['playerName']));
      expect(bluos.errorMessage, equals(BluOSTestData.pollingWithPlaylistAndError['errorMessage']));
      checkPlaylistMatches(bluos.playlist, BluOSTestData.pollingWithPlaylistAndError['playlist']);

      // when stopping external monitor, the client should retain the last state
      await expectExternalMonitorRequest(
          bluos.stop, equals('http://$testAddress/stop'), BluOSTestData.notPollingWithPlaylist, bluos);
      expect(bluos.canReload, isTrue);
      expect(bluos.isPolling, isFalse);
      expect(bluos.playlist, isNotEmpty);
      expect(bluos.playerName, equals(BluOSTestData.notPollingWithPlaylist['playerName']));
      expect(bluos.errorMessage, isNull);
      checkPlaylistMatches(bluos.playlist, BluOSTestData.notPollingWithPlaylist['playlist']);
    });

    test('allows clearing the playlist', () async {
      final bluos = BluOS();
      expect(bluos.externalMonitorClientInstance, isNull);

      const testAddress = 'monitor:1234';

      // setting external monitor
      bluos.updateMonitorAddress(testAddress);

      // start external monitor
      await expectExternalMonitorRequest(() => bluos.start('test', 4321), equals('http://$testAddress/start/test/4321'),
          BluOSTestData.pollingWithPlaylist, bluos);

      // check that the clear request is sent to the monitor
      await expectExternalMonitorRequest(() => bluos.clear(123456789), equals('http://$testAddress/clear/123456789'),
          BluOSTestData.pollingEmptyPlaylist, bluos);
      expect(bluos.isPolling, isTrue);
      expect(bluos.playlist, isEmpty);
      expect(bluos.playerName, equals(BluOSTestData.pollingWithPlaylist['playerName']));
      expect(bluos.errorMessage, isNull);
    });

    test('stops previous client before starting new client', () async {
      final apiMonitorMock = createMockBluOSAPIMonitor();
      final bluos = BluOS(apiMonitor: apiMonitorMock);
      expect(bluos.externalMonitorClientInstance, isNull);

      // mock polling API monitor
      when(apiMonitorMock.isPolling).thenReturn(true);

      // setting external monitor
      const monitorAddress = 'monitor:1234';
      bluos.updateMonitorAddress(monitorAddress);
      expect(bluos.externalMonitorClientInstance, isNotNull);
      expect(bluos.externalMonitorClientInstance!.monitorAddress, equals(monitorAddress));

      verifyZeroInteractions(apiMonitorMock);
      expect(bluos.isPolling, isTrue);

      // mock external http client
      final externalMonitorHttpClientMock = mocks.createMockHttpClient();
      bluos.externalMonitorClientInstance!.httpClient = externalMonitorHttpClientMock;

      // API monitor should remain active while it's polling
      await bluos.refresh();
      verify(apiMonitorMock.refresh());
      verifyZeroInteractions(externalMonitorHttpClientMock);

      // start without stopping first, expect stop to be sent before starting API client
      await expectExternalMonitorRequest(() => bluos.start('test', 4321),
          equals('http://$monitorAddress/start/test/4321'), BluOSTestData.pollingWithPlaylist, bluos);
      verify(apiMonitorMock.isPolling); // should check if polling before stopping
      verify(apiMonitorMock.stop()); // should stop
      verifyNoMoreInteractions(apiMonitorMock);

      expect(bluos.isPolling, isTrue);
      expect(bluos.canReload, isTrue);
      expect(bluos.playlist.length, equals(3));
    });

    test('handles exceptions', () async {
      final bluos = BluOS();
      bluos.updateMonitorAddress('monitor:1234');
      final httpClientMock = bluos.externalMonitorClientInstance!.httpClient = mocks.createMockHttpClient();

      when(httpClientMock.get(any, headers: anyNamed('headers'))).thenThrow(const SocketException(''));
      await expectLater(() async => await bluos.start('playerHost', 9876), throwsA(isA<UIException>()));
      verify(httpClientMock.get(any, headers: anyNamed('headers')));

      when(httpClientMock.get(any, headers: anyNamed('headers'))).thenThrow(const FormatException());
      await expectLater(bluos.refresh(), throwsA(isA<UIException>()));
      verify(httpClientMock.get(any, headers: anyNamed('headers')));

      when(httpClientMock.get(any, headers: anyNamed('headers'))).thenThrow(Error());
      await expectLater(bluos.stop(), throwsA(isA<UIException>()));
      verify(httpClientMock.get(any, headers: anyNamed('headers')));
    });
  });
}

void checkPlaylistMatches(List<BluOSTrack> playlist, JsonList pollingPlaylist) {
  int index = 0;
  expect(playlist.every((track) {
    final json = pollingPlaylist[index++];
    return track.timestamp == json['timestamp'] &&
        track.artist == json['artist'] &&
        track.album == json['album'] &&
        track.title == json['title'] &&
        track.imageUrl == json['image'] &&
        track.isScrobbable == (json['isScrobbable'] ?? true);
  }), isTrue);
}

Future<void> expectExternalMonitorRequest(
    Future<void> Function() operation, Matcher matcher, JsonObject response, BluOS bluos) async {
  FutureRequestData? data = fakeNextMonitorRequest(bluos, response);

  var notifyCounter = 0;
  bluos.addListener(() => notifyCounter++);

  await operation();
  expect(bluos.isLoading, isFalse);

  expect(notifyCounter, equals(2));
  expect(data.isLoadingDuringRequest, isTrue);
  expect(data.requestUrl.toString(), matcher);
}

FutureRequestData fakeNextMonitorRequest(BluOS bluos, JsonObject response) {
  final data = FutureRequestData();
  bluos.externalMonitorClientInstance!.httpClient =
      MockClient(expectAsync1<Future<http.Response>, http.Request>((request) async {
    data.requestUrl = request.url;
    data.isLoadingDuringRequest = bluos.isLoading;
    return http.Response(const JsonEncoder.withIndent(' ').convert(response), 200);
  }, count: 1));
  return data;
}

class FutureRequestData {
  Uri? requestUrl;
  bool isLoadingDuringRequest = false;
}
