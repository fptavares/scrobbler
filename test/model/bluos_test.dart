import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:scrobbler/model/bluos.dart';
import 'package:test/test.dart';

import '../mocks/cache_mocks.dart' as mocks;

const emptyPlaylistResponse = {
  'isPolling': true,
  'playlist': [],
  'playerName': 'Living Room',
  'playerState': 'stop',
};

Future<void> main() async {
  group('BluOS monitor', () {
    test('updates the monitor address', () async {
      final bluos = BluOS();
      expect(bluos.monitorAddress, isNull);

      const testAddress = 'test:1234';

      // when setting external monitor, the client checks the status immediately
      expectNextExternalMonitorRequest(equals('http://$testAddress/playlist'));
      bluos.updateMonitorAddress(testAddress);
      expect(bluos.monitorAddress, equals(testAddress));

      // check the external monitor is used when starting
      expectNextExternalMonitorRequest(startsWith('http://$testAddress/start'));
      await bluos.start('test', 4321);

      // empty address should unset address and not check the external monitor again
      final mockClient = mocks.MockClient();
      BluOSExternalMonitorClient.httpClient = mockClient;
      bluos.updateMonitorAddress('');
      verifyNoMoreInteractions(mockClient);
    });
  });
}

void expectNextExternalMonitorRequest(Matcher matcher, [count = 1]) {
  BluOSExternalMonitorClient.httpClient = MockClient(expectAsync1<Future<http.Response>, http.Request>((request) async {
    expect(request.url.toString(), matcher);
    return http.Response(const JsonEncoder.withIndent(' ').convert(emptyPlaylistResponse), 200);
  }, count: count));
}
