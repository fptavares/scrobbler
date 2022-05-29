import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:scrobbler_bluos_monitor/scrobbler_bluos_monitor.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

Future main() async {
  //Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.time.toIso8601String()} [${record.level.name}] ${record.loggerName}: ${record.message}'); // ignore: avoid_print
    if (record.error != null) {
      print('Error: ${record.error}'); // ignore: avoid_print
    }
    if (record.stackTrace != null) {
      print(record.stackTrace); // ignore: avoid_print
    }
  });

  // If the "PORT" environment variable is set, listen to it. Otherwise, 8080.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final cascade = Cascade().add(_router);

  final server = await shelf_io.serve(
    logRequests().addHandler(cascade.handler),
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  print('Serving at http://${server.address.host}:${server.port}');
}

final _bluOS = BluOSAPIMonitor();

// Router instance to handler requests.
final _router = shelf_router.Router()
  ..get('/start/<host|[^/]+>/<port|[0-9]+>', _startHandler)
  ..get('/playlist', _playlistHandler)
  ..get('/clear/<timestamp|[0-9]+>', _clearHandler)
  ..get('/stop', _stopHandler);

Future<Response> _startHandler(Request request, String host, String port) async {
  final name = request.requestedUri.queryParameters['name'];
  final stopWhenPlayerStops = request.requestedUri.queryParameters['stopOnStop'] == '1';

  try {
    await _bluOS.start(host, int.tryParse(port) ?? 11000, name, stopWhenPlayerStops);
  } on BluOSLoadingException {
    return Response.forbidden('Cannot start because the monitor is already in the process of starting');
  }

  return createResponseWithFullPlaylist();
}

Response _playlistHandler(Request request) {
  return createResponseWithFullPlaylist();
}

Response _clearHandler(Request request, String timestamp) {
  _bluOS.clear(int.parse(timestamp));
  return createResponseWithFullPlaylist();
}

Response _stopHandler(Request request) {
  _bluOS.stop();

  return createResponseWithFullPlaylist();
}

Response createResponseWithFullPlaylist() {
  return Response.ok(
      JsonEncoder.withIndent(' ', ((object) {
        if (object is BluOSTrack) {
          return {
            'timestamp': object.timestamp,
            'artist': object.artist,
            'title': object.title,
            'album': object.album,
            'image': object.imageUrl,
            if (!object.isScrobbable) 'isScrobbable': object.isScrobbable,
          }..removeWhere((key, value) => value == null);
        } else {
          return object.toJson();
        }
      })).convert({
        'isPolling': _bluOS.isPolling,
        'playlist': _bluOS.playlist,
        'playerName': _bluOS.playerName,
        'playerState': _bluOS.state?.playerState,
        'errorMessage': _bluOS.errorMessage,
      }..removeWhere((key, value) => value == null)),
      headers: {'content-type': 'application/json'});
}
