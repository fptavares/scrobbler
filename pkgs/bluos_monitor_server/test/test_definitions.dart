import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void runTests(void Function(String name, Future<void> Function(String host)) testServer) {
  testServer('responds even if not started', (host) async {
    final response = await get(host, '/playlist');
    verifyResponse(response, count: 0, isPolling: false);
  });

  testServer('starts monitoring BluOS player', (host) async {
    final startResponse = await get(host, '/start/localhost/1', {'name': 'Test Player'});
    verifyResponse(startResponse, count: 1, name: 'Test Player');
  });

  testServer('includes error information', (host) async {
    await get(host, '/start/localhost/1', {'name': 'Test Player'});

    await Future.delayed(Duration(seconds: 3));

    final playlistResponse = await get(host, '/playlist', {'name': 'Test Player'});
    verifyResponse(playlistResponse, count: 1, name: 'Test Player', hasError: true);
  });

  testServer('clears playlist', (host) async {
    final startResponse = await get(host, '/start/localhost/1');
    verifyResponse(startResponse, count: 1);

    final clearResponse = await get(host, '/clear/${(DateTime.now().millisecondsSinceEpoch / 1000).floor()}');

    verifyResponse(clearResponse, count: 0);
  });

  testServer('stops monitoring', (host) async {
    await get(host, '/start/localhost/1', {'name': 'Test Player'});
    final stopResponse = await get(host, '/stop');

    verifyResponse(stopResponse, name: 'Test Player', isPolling: false);
  });
}

void verifyResponse(http.Response response, {int? count, bool isPolling = true, String? name, bool hasError = false}) {
  final status = json.decode(response.body) as Map<String, dynamic>;

  expect(response.statusCode, 200);
  expect(response.body, isNotEmpty);
  expect(response.headers, containsPair('content-type', 'application/json'));

  expect(status['isPolling'], equals(isPolling));
  expect(status['playerName'], equals(name));
  expect(status['errorMessage'], hasError ? isNotNull : isNull);

  if (count == null) {
    return;
  } else if (count > 0) {
    final playlist = status['playlist'] as List<dynamic>;
    var i = 1;
    expect(playlist.length, count);
    for (final item in playlist) {
      final track = item as Map<String, dynamic>;
      expect(track['artist'], 'artist$i');
      expect(track['album'], 'album$i');
      expect(track['title'], 'title$i');
      expect(track['image'], contains('image$i'));
      expect(track['timestamp'], isNotNull);
      i++;
    }
  } else {
    expect(status['playlist'], isEmpty);
  }
}

Future<http.Response> get(String authority, String path, [Map<String, String>? query]) {
  return http.get(Uri.http(authority, path, query));
}
