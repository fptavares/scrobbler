import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:scrobbler/model/bluos.dart';
import 'package:scrobbler_bluos_monitor/scrobbler_bluos_monitor.dart';
import 'package:test/test.dart';

import '../bluos_test_data.dart';
import '../mocks/cache_mocks.dart' as mocks;

Future<void> main() async {
  group('BluOS monitor', () {
    test('updates the monitor address', () async {
      final bluos = BluOS();
      expect(bluos.monitorAddress, isNull);

      const testAddress = 'monitor:1234';

      // when setting external monitor, the client checks the status immediately
      await expectExternalMonitorRequest(() => bluos.updateMonitorAddress(testAddress),
          equals('http://$testAddress/playlist'), BluOSTestData.notPollingEmptyPlaylist, bluos);

      // check the external monitor is used when starting
      await expectExternalMonitorRequest(() => bluos.start('test', 4321), equals('http://$testAddress/start/test/4321'),
          BluOSTestData.pollingEmptyPlaylist, bluos);

      // empty address should unset address and not check the external monitor again
      final mockClient = mocks.MockClient();
      BluOSExternalMonitorClient.httpClient = mockClient;
      await bluos.updateMonitorAddress('');
      verifyNoMoreInteractions(mockClient);
    });

    test('updates monitor address even if already polling', () async {
      final bluos = BluOS();

      const testAddress1 = 'monitor1:1234';
      await expectExternalMonitorRequest(() => bluos.updateMonitorAddress(testAddress1),
          equals('http://$testAddress1/playlist'), BluOSTestData.notPollingEmptyPlaylist, bluos);
      expect(bluos.monitorAddress, equals(testAddress1));

      // check the monitor1 is used when starting
      await expectExternalMonitorRequest(() => bluos.start('test', 4321),
          equals('http://$testAddress1/start/test/4321'), BluOSTestData.pollingEmptyPlaylist, bluos);

      // updating address should not check the external monitor again
      const testAddress2 = 'monitor2:6789';

      final mockClient = mocks.MockClient();
      BluOSExternalMonitorClient.httpClient = mockClient;
      await bluos.updateMonitorAddress(testAddress2);
      verifyNoMoreInteractions(mockClient);

      expect(bluos.monitorAddress, equals(testAddress2));

      // check the monitor1 is still polling
      await expectExternalMonitorRequest(
          bluos.refresh, equals('http://$testAddress1/playlist'), BluOSTestData.pollingEmptyPlaylist, bluos);

      // check the monitor1 is still stopped
      await expectExternalMonitorRequest(
          bluos.stop, equals('http://$testAddress1/stop'), BluOSTestData.notPollingEmptyPlaylist, bluos);

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
      expect(bluos.monitorAddress, isNull);

      const testAddress = 'monitor:1234';

      // when setting external monitor, the client checks the status immediately
      await expectExternalMonitorRequest(() => bluos.updateMonitorAddress(testAddress),
          equals('http://$testAddress/playlist'), BluOSTestData.notPollingEmptyPlaylist, bluos);
      expect(bluos.canReload, isTrue);
      expect(bluos.isPolling, isFalse);
      expect(bluos.playlist, isEmpty);
      expect(bluos.playerName, isNull);
      expect(bluos.errorMessage, isNull);

      // check the external monitor is used and that the data stored matches
      await expectExternalMonitorRequest(() => bluos.start('test', 4321), equals('http://$testAddress/start/test/4321'),
          BluOSTestData.pollingWithPlaylist, bluos);
      expect(bluos.isPolling, isTrue);
      expect(bluos.playlist, isNotEmpty);
      expect(bluos.playerName, equals(BluOSTestData.pollingWithPlaylist['playerName']));
      expect(bluos.errorMessage, isNull);
      checkPlaylistMatches(bluos.playlist, BluOSTestData.pollingWithPlaylist['playlist']);

      // check that refresh gets the correct data inclusing the error message
      await expectExternalMonitorRequest(
          bluos.refresh, equals('http://$testAddress/playlist'), BluOSTestData.pollingWithPlaylistAndError, bluos);
      expect(bluos.isPolling, isTrue);
      expect(bluos.playlist, isNotEmpty);
      expect(bluos.playerName, equals(BluOSTestData.pollingWithPlaylistAndError['playerName']));
      expect(bluos.errorMessage, equals(BluOSTestData.pollingWithPlaylistAndError['errorMessage']));
      checkPlaylistMatches(bluos.playlist, BluOSTestData.pollingWithPlaylistAndError['playlist']);

      // when stopping external monitor, the client should retain the last state
      await expectExternalMonitorRequest(
          bluos.stop, equals('http://$testAddress/stop'), BluOSTestData.notPollingWithPlaylist, bluos);
      expect(bluos.isPolling, isFalse);
      expect(bluos.playlist, isNotEmpty);
      expect(bluos.playerName, equals(BluOSTestData.notPollingWithPlaylist['playerName']));
      expect(bluos.errorMessage, isNull);
      checkPlaylistMatches(bluos.playlist, BluOSTestData.notPollingWithPlaylist['playlist']);
    });

    test('allows clearing the playlist', () async {
      final bluos = BluOS();
      expect(bluos.monitorAddress, isNull);

      const testAddress = 'monitor:1234';

      // when setting external monitor, the client checks the status immediately
      await expectExternalMonitorRequest(() => bluos.updateMonitorAddress(testAddress),
          equals('http://$testAddress/playlist'), BluOSTestData.notPollingEmptyPlaylist, bluos);

      // check that the clear request is sent to the monitor
      await expectExternalMonitorRequest(() => bluos.clear(123456789), equals('http://$testAddress/clear/123456789'),
          BluOSTestData.pollingEmptyPlaylist, bluos);
      expect(bluos.isPolling, isTrue);
      expect(bluos.playlist, isEmpty);
      expect(bluos.playerName, equals(BluOSTestData.pollingWithPlaylist['playerName']));
      expect(bluos.errorMessage, isNull);
    });

    test('stops previous client before starting new client', () async {
      final bluos = BluOS();
      expect(bluos.monitorAddress, isNull);

      const monitorAddress = 'monitor:1234';

      // when setting external monitor, the client checks the status immediately
      await expectExternalMonitorRequest(() => bluos.updateMonitorAddress(monitorAddress),
          equals('http://$monitorAddress/playlist'), BluOSTestData.pollingWithPlaylist, bluos);

      expect(bluos.isPolling, isTrue);

      // updating address to null should cause an extra check on the external monitor
      final mockExternalMonitorClient = mocks.MockClient();
      BluOSExternalMonitorClient.httpClient = mockExternalMonitorClient;
      await bluos.updateMonitorAddress(''); // empty setting
      verifyNoMoreInteractions(mockExternalMonitorClient);

      expect(bluos.monitorAddress, isNull);
      expect(bluos.isPolling, isTrue);

      // verify external monitor is still used
      await expectExternalMonitorRequest(
          bluos.refresh, equals('http://$monitorAddress/playlist'), BluOSTestData.pollingWithPlaylist, bluos);

      expect(bluos.isPolling, isTrue);
      expect(bluos.playlist.length, equals(3));

      // expect stop to be sent before starting API client
      BluOSExternalMonitorClient.httpClient =
          MockClient(expectAsync1<Future<http.Response>, http.Request>((request) async {
        expect(request.url.toString(), equals('http://$monitorAddress/stop'));
        expect(bluos.isLoading, isTrue);
        return http.Response(const JsonEncoder.withIndent(' ').convert(BluOSTestData.notPollingWithPlaylist), 200);
      }, count: 1));

      const playerHost = 'player';
      const playerPort = 6789;

      // start without stopping first
      await expectBluOSAPIRequest(() => bluos.start(playerHost, playerPort),
          startsWith('http://$playerHost:$playerPort/'), BluOSTestData.bluosStatus, bluos);

      expect(bluos.monitorAddress, isNull);
      expect(bluos.isPolling, isTrue);
      expect(bluos.playlist.length, equals(1));
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
  Uri? url;
  BluOSExternalMonitorClient.httpClient = MockClient(expectAsync1<Future<http.Response>, http.Request>((request) async {
    url = request.url;
    expect(bluos.isLoading, isTrue);
    return http.Response(const JsonEncoder.withIndent(' ').convert(response), 200);
  }, count: 1));

  expect(bluos.isLoading, isFalse);
  await operation();
  expect(bluos.isLoading, isFalse);

  expect(url.toString(), matcher);
}

Future<void> expectBluOSAPIRequest(
    Future<void> Function() operation, Matcher matcher, String xmlResponse, BluOS bluos) async {
  Uri? url;
  BluOSAPIMonitor.httpClient = MockClient(expectAsync1<Future<http.Response>, http.Request>((request) async {
    url = request.url;
    expect(bluos.isLoading, isTrue);
    return http.Response(xmlResponse, 200);
  }, count: 1));

  expect(bluos.isLoading, isFalse);
  await operation();
  expect(bluos.isLoading, isFalse);

  expect(url.toString(), matcher);
}
