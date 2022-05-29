import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

Future main() async {
  // If the "PORT" environment variable is set, listen to it. Otherwise, 8081.
  final port = int.parse(Platform.environment['PORT'] ?? '8081');

  final cascade = Cascade().add(_router);

  final server = await shelf_io.serve(
    logRequests().addHandler(cascade.handler),
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  print('Serving at http://${server.address.host}:${server.port}');
}

final statuses = [
  createStatus(1, 'play'),
  createStatus(2, 'pause'),
].iterator;

// Router instance to handler requests.
final _router = shelf_router.Router()..get('/Status', _statusHandler);

Response _statusHandler(Request request) {
  if (statuses.moveNext()) {
    return statuses.current;
  } else {
    return Response.internalServerError();
  }
}

Response createStatus(int pid, String state) {
  return Response.ok('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="etag$pid">
	<album>album$pid</album>
	<artist>artist$pid</artist>
	<image>/image$pid</image>
	<name>title$pid</name>
	<pid>$pid</pid>
	<service>LocalMusic</service>
	<state>$state</state>
	<totlen>10$pid</totlen>
	<secs>10$pid</secs>
</status>
''');
}
